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

// Middleware creates HTTP middleware that sheds load based on Puma backlog
// Returns 503 Service Unavailable when backlog exceeds the configured threshold
func Middleware(loadShedder *LoadShedder, logger *logrus.Logger) func(http.Handler) http.Handler {
	return func(next http.Handler) http.Handler {
		return http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
			if loadShedder == nil {
				next.ServeHTTP(w, r)
				return
			}

			if loadShedder.ShouldShedLoad() {
				backlog := loadShedder.GetLastBacklog()
				threshold := loadShedder.GetThreshold()
				retryAfter := loadShedder.GetRetryAfterSeconds()

				logger.WithFields(map[string]interface{}{
					"backlog":     backlog,
					"threshold":   threshold,
					"retry_after": retryAfter,
					"path":        r.URL.Path,
					"method":      r.Method,
				}).Debug("Shedding load due to high backlog")

				// Return 503 Service Unavailable with Retry-After header
				// NGINX will retry the request per proxy_next_upstream configuration
				w.Header().Set("Retry-After", strconv.Itoa(retryAfter))
				http.Error(w, "Service Unavailable: High backlog", http.StatusServiceUnavailable)
				return
			}

			next.ServeHTTP(w, r)
		})
	}
}
