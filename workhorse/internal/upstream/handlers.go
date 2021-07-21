package upstream

import (
	"compress/gzip"
	"fmt"
	"io"
	"net/http"

	"gitlab.com/gitlab-org/gitlab/workhorse/internal/helper"
)

func contentEncodingHandler(h http.Handler) http.Handler {
	return http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		var body io.ReadCloser
		var err error

		// The client request body may have been gzipped.
		contentEncoding := r.Header.Get("Content-Encoding")
		switch contentEncoding {
		case "":
			body = r.Body
		case "gzip":
			body, err = gzip.NewReader(r.Body)
		default:
			err = fmt.Errorf("unsupported content encoding: %s", contentEncoding)
		}

		if err != nil {
			helper.Fail500(w, r, fmt.Errorf("contentEncodingHandler: %v", err))
			return
		}
		defer body.Close()

		r.Body = body
		r.Header.Del("Content-Encoding")

		h.ServeHTTP(w, r)
	})
}
