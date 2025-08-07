/*
Package circuitbreaker provides a custom HTTP wrapper roundTripper that implements a circuit breaker.
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
	gobreaker "github.com/sony/gobreaker/v2"

	"gitlab.com/gitlab-org/gitlab/workhorse/internal/config"
	"gitlab.com/gitlab-org/gitlab/workhorse/internal/log"
)

const (
	enableCircuitBreakerHeader = "Enable-Workhorse-Circuit-Breaker"
	errorMsg                   = "This endpoint has been requested too many times. Try again later."
)

type roundTripper struct {
	delegate            http.RoundTripper
	store               *DistributedRedisStoreWithExpiry
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
		store:               NewDistributedRedisStoreWithExpiry(rdb),
		timeout:             time.Duration(circuitBreakerConfig.Timeout) * time.Second,
		interval:            time.Duration(circuitBreakerConfig.Interval) * time.Second,
		maxRequests:         circuitBreakerConfig.MaxRequests,
		consecutiveFailures: circuitBreakerConfig.ConsecutiveFailures,
	}
}

// RoundTrip wraps the provided delegate RoundTripper with a circuit breaker.
func (r roundTripper) RoundTrip(req *http.Request) (res *http.Response, err error) {
	userKey, err := getUserKey(req)
	if err != nil {
		return r.delegate.RoundTrip(req)
	}

	tracked := r.store.isUserTracked(userKey)
	if !tracked {
		return r.roundTripAndTrackUser(req, userKey)
	}

	cb, err := r.newCircuitBreaker(userKey)
	if err != nil {
		log.WithError(err).Info("gobreaker: error creating circuit breaker")
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
		return response.(*http.Response), nil
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

func (r roundTripper) roundTripAndTrackUser(req *http.Request, userKey string) (res *http.Response, err error) {
	res, err = r.delegate.RoundTrip(req)
	if err != nil {
		return res, err
	}

	// The user must receive a Too Many Requests response before being tracked by the circuit breaker.
	if isCircuitBreakerApplicable(res) {
		// newCircuitBreaker initializes the circuit breaker's state for the user, ensuring the user is tracked in subsequent requests.
		_, cbErr := r.newCircuitBreaker(userKey)
		if cbErr != nil {
			log.WithError(cbErr).Info("gobreaker: error creating circuit breaker")
		}
	}

	return res, err
}

func (r roundTripper) newCircuitBreaker(userKey string) (*gobreaker.DistributedCircuitBreaker[any], error) {
	var st gobreaker.Settings

	st.Name = userKey // Name becomes the key for the user in Redis
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

	return gobreaker.NewDistributedCircuitBreaker[any](r.store, st)
}

func getUserKey(req *http.Request) (string, error) {
	if req.Body == nil {
		return "", errors.New("gobreaker: missing request body")
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
			return id, nil
		}
	}

	return "", errors.New("gobreaker: key not found")
}

// If there was a Too Many Requests error in the http response, return an error to be passed into IsSuccessful()
func responseToError(res *http.Response) error {
	if !isCircuitBreakerApplicable(res) {
		return nil
	}

	return errors.New("rate limited")
}

func isCircuitBreakerApplicable(res *http.Response) bool {
	return res.Header.Get(enableCircuitBreakerHeader) == "true" && res.StatusCode == http.StatusTooManyRequests
}
