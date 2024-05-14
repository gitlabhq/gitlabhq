// Package queueing provides functionality for managing queues of requests.
package queueing

import (
	"net/http"
	"time"

	"github.com/prometheus/client_golang/prometheus"

	"gitlab.com/gitlab-org/gitlab/workhorse/internal/helper/fail"
)

const (
	// DefaultTimeout is the default timeout duration for queueing requests.
	DefaultTimeout            = 30 * time.Second
	httpStatusTooManyRequests = 429
)

// QueueRequests creates a new request queue
// name specifies the name of queue, used to label Prometheus metrics
//
//	Don't call QueueRequests twice with the same name argument!
//
// h specifies a http.Handler which will handle the queue requests
// limit specifies number of requests run concurrently
// queueLimit specifies maximum number of requests that can be queued
// queueTimeout specifies the time limit of storing the request in the queue
func QueueRequests(name string, h http.Handler, limit, queueLimit uint, queueTimeout time.Duration, reg prometheus.Registerer) http.Handler {
	if limit == 0 {
		return h
	}
	if queueTimeout == 0 {
		queueTimeout = DefaultTimeout
	}

	queue := newQueue(name, limit, queueLimit, queueTimeout, reg)

	return http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		err := queue.Acquire()

		switch err {
		case nil:
			defer queue.Release()
			h.ServeHTTP(w, r)

		case ErrTooManyRequests:
			http.Error(w, "Too Many Requests", httpStatusTooManyRequests)

		case ErrQueueingTimedout:
			http.Error(w, "Service Unavailable", http.StatusServiceUnavailable)

		default:
			fail.Request(w, r, err)
		}
	})
}
