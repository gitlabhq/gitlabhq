package nginx

import "net/http"

const ResponseBufferHeader = "X-Accel-Buffering"

func DisableResponseBuffering(w http.ResponseWriter) {
	w.Header().Set(ResponseBufferHeader, "no")
}

func AllowResponseBuffering(w http.ResponseWriter) {
	w.Header().Del(ResponseBufferHeader)
}
