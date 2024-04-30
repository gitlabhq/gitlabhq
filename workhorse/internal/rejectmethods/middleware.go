// Package rejectmethods provides middleware to reject HTTP requests with unknown methods
package rejectmethods

import (
	"net/http"

	"github.com/prometheus/client_golang/prometheus"
)

var acceptedMethods = map[string]bool{
	http.MethodGet:     true,
	http.MethodHead:    true,
	http.MethodPost:    true,
	http.MethodPut:     true,
	http.MethodPatch:   true,
	http.MethodDelete:  true,
	http.MethodConnect: true,
	http.MethodOptions: true,
	http.MethodTrace:   true,
}

var rejectedRequestsCount = prometheus.NewCounter(
	prometheus.CounterOpts{
		Name: "gitlab_workhorse_unknown_method_rejected_requests",
		Help: "The number of requests with unknown HTTP method which were rejected",
	},
)

// NewMiddleware returns middleware which rejects all unknown http methods
func NewMiddleware(handler http.Handler) http.Handler {
	return http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		if acceptedMethods[r.Method] {
			handler.ServeHTTP(w, r)
		} else {
			rejectedRequestsCount.Inc()
			http.Error(w, http.StatusText(http.StatusMethodNotAllowed), http.StatusMethodNotAllowed)
		}
	})
}
