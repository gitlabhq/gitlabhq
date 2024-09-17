// Package builds provides functionality for registering builds.
package builds

import (
	"bytes"
	"context"
	"encoding/json"
	"errors"
	"fmt"
	"io"
	"net/http"
	"time"

	"github.com/prometheus/client_golang/prometheus"
	"github.com/prometheus/client_golang/prometheus/promauto"

	"gitlab.com/gitlab-org/gitlab/workhorse/internal/helper"
	"gitlab.com/gitlab-org/gitlab/workhorse/internal/helper/fail"
	"gitlab.com/gitlab-org/gitlab/workhorse/internal/redis"
)

const (
	maxRegisterBodySize         = 32 * 1024
	runnerBuildQueue            = "runner:build_queue:"
	runnerBuildQueueHeaderKey   = "Gitlab-Ci-Builds-Polling"
	runnerBuildQueueHeaderValue = "yes"
)

var (
	registerHandlerRequests = promauto.NewCounterVec(
		prometheus.CounterOpts{
			Name: "gitlab_workhorse_builds_register_handler_requests",
			Help: "Describes how many requests in different states hit a register handler",
		},
		[]string{"status"},
	)
	registerHandlerOpen = promauto.NewGaugeVec(
		prometheus.GaugeOpts{
			Name: "gitlab_workhorse_builds_register_handler_open",
			Help: "Describes how many requests is currently open in given state",
		},
		[]string{"state"},
	)

	registerHandlerOpenAtReading  = registerHandlerOpen.WithLabelValues("reading")
	registerHandlerOpenAtProxying = registerHandlerOpen.WithLabelValues("proxying")
	registerHandlerOpenAtWatching = registerHandlerOpen.WithLabelValues("watching")

	registerHandlerBodyReadErrors         = registerHandlerRequests.WithLabelValues("body-read-error")
	registerHandlerBodyParseErrors        = registerHandlerRequests.WithLabelValues("body-parse-error")
	registerHandlerMissingValues          = registerHandlerRequests.WithLabelValues("missing-values")
	registerHandlerWatchErrors            = registerHandlerRequests.WithLabelValues("watch-error")
	registerHandlerAlreadyChangedRequests = registerHandlerRequests.WithLabelValues("already-changed")
	registerHandlerSeenChangeRequests     = registerHandlerRequests.WithLabelValues("seen-change")
	registerHandlerTimeoutRequests        = registerHandlerRequests.WithLabelValues("timeout")
	registerHandlerNoChangeRequests       = registerHandlerRequests.WithLabelValues("no-change")
)

type largeBodyError struct{ error }

// WatchKeyHandler is a function type for watching keys in Redis.
type WatchKeyHandler func(ctx context.Context, key, value string, timeout time.Duration) (redis.WatchKeyStatus, error)

type runnerRequest struct {
	Token      string `json:"token,omitempty"`
	LastUpdate string `json:"last_update,omitempty"`
}

func readRunnerBody(w http.ResponseWriter, r *http.Request) ([]byte, error) {
	registerHandlerOpenAtReading.Inc()
	defer registerHandlerOpenAtReading.Dec()

	return readRequestBody(w, r, maxRegisterBodySize)
}

func readRequestBody(w http.ResponseWriter, r *http.Request, maxBodySize int64) ([]byte, error) {
	limitedBody := http.MaxBytesReader(w, r.Body, maxBodySize)
	defer func() {
		if err := limitedBody.Close(); err != nil {
			fmt.Printf("Failed to close request body: %v", err)
		}
	}()

	return io.ReadAll(limitedBody)
}

func readRunnerRequest(r *http.Request, body []byte) (*runnerRequest, error) {
	if !isApplicationJSON(r) {
		return nil, errors.New("invalid content-type received")
	}

	var request runnerRequest
	err := json.Unmarshal(body, &request)
	if err != nil {
		return nil, err
	}

	return &request, nil
}

func isApplicationJSON(r *http.Request) bool {
	contentType := r.Header.Get("Content-Type")
	return helper.IsContentType("application/json", contentType)
}

func proxyRegisterRequest(h http.Handler, w http.ResponseWriter, r *http.Request) {
	registerHandlerOpenAtProxying.Inc()
	defer registerHandlerOpenAtProxying.Dec()

	h.ServeHTTP(w, r)
}

func watchForRunnerChange(ctx context.Context, watchHandler WatchKeyHandler, token, lastUpdate string, duration time.Duration) (redis.WatchKeyStatus, error) {
	registerHandlerOpenAtWatching.Inc()
	defer registerHandlerOpenAtWatching.Dec()

	return watchHandler(ctx, runnerBuildQueue+token, lastUpdate, duration)
}

// RegisterHandler with key watch logic if polling is enabled.
func RegisterHandler(h http.Handler, watchHandler WatchKeyHandler, pollingDuration time.Duration) http.Handler {
	if pollingDuration == 0 {
		return h
	}

	return http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		w.Header().Set(runnerBuildQueueHeaderKey, runnerBuildQueueHeaderValue)

		requestBody, err := readRunnerBody(w, r)
		if err != nil {
			registerHandlerBodyReadErrors.Inc()
			fail.Request(w, r, &largeBodyError{err},
				fail.WithStatus(http.StatusRequestEntityTooLarge))
			return
		}

		newRequest := cloneRequestWithNewBody(r, requestBody)

		runnerRequest, shouldReturn := getRunnerRequest(r, requestBody, h, w, newRequest)
		if shouldReturn {
			return
		}

		result, err := watchForRunnerChange(r.Context(), watchHandler, runnerRequest.Token,
			runnerRequest.LastUpdate, pollingDuration)
		if err != nil {
			registerHandlerWatchErrors.Inc()
			proxyRegisterRequest(h, w, newRequest)
			return
		}

		switch result {
		// It means that we detected a change before starting watching on change,
		// We proxy request to Rails, to see whether we have a build to receive
		case redis.WatchKeyStatusAlreadyChanged:
			registerHandlerAlreadyChangedRequests.Inc()
			proxyRegisterRequest(h, w, newRequest)

		// It means that we detected a change after watching.
		// We could potentially proxy request to Rails, but...
		// We can end-up with unreliable responses,
		// as don't really know whether ResponseWriter is still in a sane state,
		// for example the connection is dead
		case redis.WatchKeyStatusSeenChange:
			registerHandlerSeenChangeRequests.Inc()
			w.WriteHeader(http.StatusNoContent)

		// When we receive one of these statuses, it means that we detected no change,
		// so we return to runner 204, which means nothing got changed,
		// and there's no new builds to process
		case redis.WatchKeyStatusTimeout:
			registerHandlerTimeoutRequests.Inc()
			w.WriteHeader(http.StatusNoContent)

		case redis.WatchKeyStatusNoChange:
			registerHandlerNoChangeRequests.Inc()
			w.WriteHeader(http.StatusNoContent)
		}
	})
}

func getRunnerRequest(r *http.Request, requestBody []byte, h http.Handler, w http.ResponseWriter, newRequest *http.Request) (*runnerRequest, bool) {
	runnerRequest, err := readRunnerRequest(r, requestBody)
	if err != nil {
		registerHandlerBodyParseErrors.Inc()
		proxyRegisterRequest(h, w, newRequest)
		return nil, true
	}

	if runnerRequest.Token == "" || runnerRequest.LastUpdate == "" {
		registerHandlerMissingValues.Inc()
		proxyRegisterRequest(h, w, newRequest)
		return nil, true
	}
	return runnerRequest, false
}

func cloneRequestWithNewBody(r *http.Request, body []byte) *http.Request {
	newReq := r.Clone(r.Context())
	newReq.Body = io.NopCloser(bytes.NewReader(body))
	newReq.ContentLength = int64(len(body))
	return newReq
}
