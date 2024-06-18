// Package nginx provides helper functions for interacting with NGINX
package nginx

import "net/http"

// ResponseBufferHeader is the HTTP header used to control response buffering in NGINX
const ResponseBufferHeader = "X-Accel-Buffering"

// DisableResponseBuffering disables response buffering in NGINX for the provided HTTP response writer
func DisableResponseBuffering(w http.ResponseWriter) {
	w.Header().Set(ResponseBufferHeader, "no")
}

// AllowResponseBuffering enables response buffering in NGINX for the provided HTTP response writer
func AllowResponseBuffering(w http.ResponseWriter) {
	w.Header().Del(ResponseBufferHeader)
}
