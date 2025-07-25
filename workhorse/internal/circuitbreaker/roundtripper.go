/*
Package circuitbreaker provides a custom HTTP wrapper roundTripper that implements a circuitbreaker.
*/
package circuitbreaker

import (
	"bytes"
	"encoding/json"
	"errors"
	"io"
	"net/http"
	"time"

	redis "github.com/redis/go-redis/v9"
	"github.com/sony/gobreaker/v2"

	"gitlab.com/gitlab-org/gitlab/workhorse/internal/config"
	"gitlab.com/gitlab-org/gitlab/workhorse/internal/log"
)

const (
	enableCircuitBreakerHeader = "Enable-Workhorse-Circuit-Breaker"
	errorMsg                   = "This endpoint has been requested too many times. Try again later."
)

type roundTripper struct {
	delegate            http.RoundTripper
	store               *RedisStore
	timeout             time.Duration // Timeout is the duration to transition to half-open when open
	interval            time.Duration // Interval is the duration to clear consecutive failures (and other gobreaker.Counts) when closed
	maxRequests         uint32        // MaxRequests is the number of failed requests to open the circuit breaker when half-open
	consecutiveFailures uint32        // ConsecutiveFailures is the number of consecutive failures to open the circuit breaker when closed
}

// NewRoundTripper returns a new RoundTripper that wraps the provided RoundTripper with a circuit breaker
func NewRoundTripper(delegate http.RoundTripper, circuitBreakerConfig *config.CircuitBreakerConfig, rdb *redis.Client) http.RoundTripper {
	if rdb == nil {
		return delegate
	}

	return &roundTripper{
		delegate:            delegate,
		store:               NewRedisStore(rdb),
		timeout:             time.Duration(circuitBreakerConfig.Timeout) * time.Second,
		interval:            time.Duration(circuitBreakerConfig.Interval) * time.Second,
		maxRequests:         circuitBreakerConfig.MaxRequests,
		consecutiveFailures: circuitBreakerConfig.ConsecutiveFailures,
	}
}

// RoundTrip wraps the provided delegate RoundTripper with a circuit breaker.
func (r roundTripper) RoundTrip(req *http.Request) (res *http.Response, err error) {
	cb, err := r.newCircuitBreaker(req, r.store)
	if err != nil {
		return r.delegate.RoundTrip(req)
	}

	response, executeErr := cb.Execute(func() (any, error) {
		roundTripRes, roundTripErr := r.delegate.RoundTrip(req)
		if roundTripErr != nil {
			return nil, roundTripErr
		}

		defer func() { _ = roundTripRes.Body.Close() }()

		return roundTripRes, responseToError(roundTripRes)
	})

	if response != nil {
		return response.(*http.Response), executeErr
	}

	if errors.Is(executeErr, gobreaker.ErrOpenState) {
		resp := &http.Response{
			StatusCode: http.StatusTooManyRequests,
			Body:       io.NopCloser(bytes.NewBufferString(errorMsg)),
			Header:     make(http.Header),
		}

		resp.Header.Set("Retry-After", r.timeout.String())

		return resp, nil
	}

	return nil, executeErr
}

func (r roundTripper) newCircuitBreaker(req *http.Request, store *RedisStore) (*gobreaker.DistributedCircuitBreaker[any], error) {
	var st gobreaker.Settings

	key, err := getRedisKey(req)
	if err != nil {
		return nil, err
	}
	st.Name = key
	st.MaxRequests = r.maxRequests
	st.Timeout = r.timeout
	st.Interval = r.interval

	st.OnStateChange = func(name string, from gobreaker.State, to gobreaker.State) {
		log.WithFields(log.Fields{"name": name, "from": from.String(), "to": to.String()}).Info("gobreaker: state change")
	}
	st.ReadyToTrip = func(counts gobreaker.Counts) bool {
		return counts.ConsecutiveFailures > r.consecutiveFailures
	}
	st.IsSuccessful = func(err error) bool {
		return err == nil
	}

	return gobreaker.NewDistributedCircuitBreaker[any](store, st)
}

func getRedisKey(req *http.Request) (string, error) {
	if req.Body == nil {
		return "", errors.New("gobreaker: missing response body")
	}

	bodyBytes, err := io.ReadAll(req.Body)
	if err != nil {
		log.WithError(err).Info("gobreaker: failed to read request body")
		return "", err
	}

	defer func() { _ = req.Body.Close() }()
	req.Body = io.NopCloser(bytes.NewBuffer(bodyBytes))

	// Ssh key_id is present in the JSON body for git ssh requests, and uniquely identifies a user
	var jsonBody map[string]any
	if err := json.Unmarshal(bodyBytes, &jsonBody); err == nil {
		if id, ok := jsonBody["key_id"].(string); ok && id != "" {
			return "gobreaker:key_id:" + id, nil
		}
	}

	return "", errors.New("gobreaker: key not found")
}

// If there was a Too Many Requests error in the http response, return an error to be passed into IsSuccessful()
func responseToError(res *http.Response) error {
	if res.Header.Get(enableCircuitBreakerHeader) != "true" || res.StatusCode != http.StatusTooManyRequests {
		return nil
	}

	return errors.New("rate limited")
}
