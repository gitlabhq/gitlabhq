/*
Package ratelimitcache provides a custom HTTP wrapper roundTripper that caches
rate limited responses from Rails, and blocks those users from subsequent requests.
*/
package ratelimitcache

import (
	"bytes"
	"encoding/json"
	"errors"
	"io"
	"net/http"
	"strconv"
	"time"

	redis "github.com/redis/go-redis/v9"

	"gitlab.com/gitlab-org/gitlab/workhorse/internal/log"
)

const (
	enableCircuitBreakerHeader = "Enable-Workhorse-Circuit-Breaker"
	errorMsg                   = "This endpoint has been requested too many times. Try again later."
	maxRetryAfterSeconds       = 86400     // 24 hours
	maxBodySize                = 64 * 1024 // 64KB
)

type roundTripper struct {
	delegate http.RoundTripper
	cache    *blockCache
}

// NewRoundTripper returns a new RoundTripper that wraps the provided RoundTripper with a cache of
// rate limited users, blocking those users from subsequent requests.
func NewRoundTripper(delegate http.RoundTripper, rdb *redis.Client) http.RoundTripper {
	if rdb == nil {
		return delegate
	}

	return &roundTripper{
		delegate: delegate,
		cache:    newBlockCache(rdb),
	}
}

// RoundTrip wraps the provided delegate RoundTripper with a blocked user cache.
// Requests that belong to users who have been rate limited will be rejected with a 429 response for the duration
// specified by the retry-after header.
func (r *roundTripper) RoundTrip(req *http.Request) (*http.Response, error) {
	ctx := req.Context()

	userKey, err := getUserKey(req)
	if err != nil {
		return r.delegate.RoundTrip(req)
	}

	if blockedUntil, blocked := r.cache.isBlocked(ctx, userKey); blocked {
		return blockedResponse(blockedUntil, userKey), nil
	}

	resp, err := r.delegate.RoundTrip(req)
	if err != nil {
		return resp, err
	}

	if isBlockApplicable(resp) {
		if blockedUntil, ok := parseRetryAfter(resp.Header.Get("Retry-After")); ok {
			r.cache.setBlock(ctx, userKey, blockedUntil)
			log.WithFields(log.Fields{"userKey": userKey, "blockedUntil": blockedUntil}).Info("ratelimitcache: blocking user")
		}
	}

	return resp, nil
}

func blockedResponse(blockedUntil time.Time, userKey string) *http.Response {
	retryAfter := time.Until(blockedUntil).Seconds()
	if retryAfter < 0 {
		retryAfter = 0
	}

	resp := &http.Response{
		StatusCode: http.StatusTooManyRequests,
		Body:       io.NopCloser(bytes.NewBufferString(errorMsg)),
		Header:     make(http.Header),
	}
	resp.Header.Set("Retry-After", strconv.Itoa(int(retryAfter)))

	log.WithFields(log.Fields{"userKey": userKey, "retryAfter": retryAfter}).Info("ratelimitcache: request blocked")

	return resp
}

// parseRetryAfter parses the Retry-After header value (in seconds) and returns the blockedUntil time.
func parseRetryAfter(value string) (time.Time, bool) {
	if value == "" {
		return time.Time{}, false
	}

	seconds, err := strconv.ParseInt(value, 10, 64)
	if err != nil {
		log.WithError(err).Info("ratelimitcache: failed to parse Retry-After header")
		return time.Time{}, false
	}

	if seconds <= 0 {
		return time.Time{}, false
	}

	if seconds > maxRetryAfterSeconds {
		seconds = maxRetryAfterSeconds
	}

	return time.Now().Add(time.Duration(seconds) * time.Second), true
}

func getUserKey(req *http.Request) (string, error) {
	if req.Body == nil {
		return "", errors.New("ratelimitcache: missing request body")
	}

	bodyBytes, err := io.ReadAll(io.LimitReader(req.Body, maxBodySize))
	if err != nil {
		return "", err
	}

	// If body exceeds limit, reconstruct body from buffer + remaining stream
	if len(bodyBytes) == maxBodySize {
		req.Body = io.NopCloser(io.MultiReader(bytes.NewBuffer(bodyBytes), req.Body))
	} else {
		req.Body = io.NopCloser(bytes.NewBuffer(bodyBytes))
	}

	var jsonBody map[string]any
	if err := json.Unmarshal(bodyBytes, &jsonBody); err == nil {
		if id, ok := jsonBody["key_id"].(string); ok && id != "" {
			return id, nil
		}
	}

	return "", errors.New("ratelimitcache: key not found")
}

func isBlockApplicable(res *http.Response) bool {
	return res.Header.Get(enableCircuitBreakerHeader) == "true" && res.StatusCode == http.StatusTooManyRequests
}
