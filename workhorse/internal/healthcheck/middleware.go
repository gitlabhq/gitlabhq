package healthcheck

import (
	"net/http"
)

// ResponseTracker wraps http.ResponseWriter to track response status codes
type ResponseTracker struct {
	http.ResponseWriter
	statusCode int
}

// NewResponseTracker creates a new ResponseTracker
func NewResponseTracker(w http.ResponseWriter) *ResponseTracker {
	return &ResponseTracker{
		ResponseWriter: w,
		statusCode:     http.StatusOK, // Default to 200
	}
}

// WriteHeader captures the status code
func (rt *ResponseTracker) WriteHeader(code int) {
	rt.statusCode = code
	rt.ResponseWriter.WriteHeader(code)
}

// StatusCode returns the captured status code
func (rt *ResponseTracker) StatusCode() int {
	return rt.statusCode
}

// BackendSuccessTrackingMiddleware creates middleware that tracks successful 20x responses
// only for requests that are actually proxied to the backend (not served by static assets, etc.)
func BackendSuccessTrackingMiddleware(successTracker *SuccessTracker) func(http.Handler) http.Handler {
	return func(next http.Handler) http.Handler {
		return http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
			// Wrap the response writer to track status code
			tracker := NewResponseTracker(w)

			// Call the next handler
			next.ServeHTTP(tracker, r)

			// Check if the response was successful (20x status code)
			statusCode := tracker.StatusCode()
			if statusCode >= 200 && statusCode < 300 {
				successTracker.RecordSuccess()
			}
		})
	}
}
