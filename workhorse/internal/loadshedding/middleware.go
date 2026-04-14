// Package loadshedding provides load shedding functionality for Workhorse.
// It monitors Puma's request backlog and returns 503 Service Unavailable
// when the backlog exceeds configured thresholds, allowing NGINX to retry
// requests to other instances.
package loadshedding

import (
	"net/http"
	"strconv"

	"github.com/sirupsen/logrus"
)

// ReadinessProvider allows the middleware to shed load when the upstream
// signals it is not ready due to being overloaded. Three conditions are required
// before load shedding is triggered:
//   - IsReady() is false (the readiness probe failed)
//   - LastFailureWasTimeout() is true (the probe timed out, indicating a slow
//     upstream rather than one that is simply not yet up or is shutting down)
//   - IsShuttingDown() is false (graceful shutdown — let in-flight requests drain)
type ReadinessProvider interface {
	IsReady() bool
	IsShuttingDown() bool
	LastFailureWasTimeout() bool
}

// isRetryableMethod returns true for HTTP methods that are safe to retry.
// GET, HEAD, and OPTIONS are idempotent and safe for NGINX to retry.
// Non-idempotent methods like POST, PUT, PATCH, and DELETE must never be shed
// since retrying could cause duplicate writes or unintended side effects.
func isRetryableMethod(method string) bool {
	switch method {
	case http.MethodGet, http.MethodHead, http.MethodOptions:
		return true
	}
	return false
}

// Middleware creates HTTP middleware that sheds load based on Puma backlog or
// upstream readiness. Returns a configurable status code (503 by default) when
// the backlog exceeds the configured threshold or when the readiness provider
// signals not-ready, allowing NGINX to retry requests on other instances.
func Middleware(loadShedder *LoadShedder, readiness ReadinessProvider, logger *logrus.Logger) func(http.Handler) http.Handler {
	return func(next http.Handler) http.Handler {
		return http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
			if loadShedder == nil {
				next.ServeHTTP(w, r)
				return
			}

			shouldShedBacklog := loadShedder.ShouldShedLoad()
			// Treat not-ready as a shedding signal only when the probe timed
			// out (overloaded upstream), not when it failed fast (e.g. TCP
			// connection refused — worker not yet up) or when the pod is
			// shutting down and we want in-flight requests to drain normally.
			notReady := readiness != nil &&
				!readiness.IsReady() &&
				readiness.LastFailureWasTimeout() &&
				!readiness.IsShuttingDown()

			// Keep the workhorse_load_shedding_active gauge in sync with both
			// signals; SetReadinessShedActive is a no-op when the state has
			// not changed, so calling it per-request is inexpensive.
			loadShedder.SetReadinessShedActive(notReady)

			if isRetryableMethod(r.Method) && (shouldShedBacklog || notReady) {
				backlog := loadShedder.GetLastBacklog()
				threshold := loadShedder.GetThreshold()
				retryAfter := loadShedder.GetRetryAfterSeconds()
				statusCode := loadShedder.GetStatusCode()

				reason := "backlog"
				if !shouldShedBacklog {
					reason = "not_ready"
				}

				logger.WithFields(map[string]interface{}{
					"backlog":     backlog,
					"threshold":   threshold,
					"retry_after": retryAfter,
					"status_code": statusCode,
					"path":        r.URL.Path,
					"method":      r.Method,
					"reason":      reason,
				}).Debug("Shedding load")

				message := "Service Unavailable: High backlog"
				if !shouldShedBacklog {
					message = "Service Unavailable: Readiness probe timed out"
				}

				// Return configured status code with Retry-After header
				// NGINX will retry the request per proxy_next_upstream configuration
				w.Header().Set("Retry-After", strconv.Itoa(retryAfter))
				http.Error(w, message, statusCode)
				return
			}

			next.ServeHTTP(w, r)
		})
	}
}
