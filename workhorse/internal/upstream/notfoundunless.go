package upstream

import "net/http"

// NotFoundUnless returns a handler that forwards requests to the given handler if pass is true.
// Otherwise, it responds with a 404 Not Found status.
func NotFoundUnless(pass bool, handler http.Handler) http.Handler {
	if pass {
		return handler
	}
	return http.NotFoundHandler()
}
