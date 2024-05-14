/*
Package upstream provides functionality for handling upstream requests.

This package includes handlers for managing request routing and interaction with upstream servers.
*/
package upstream

import (
	"compress/gzip"
	"fmt"
	"io"
	"net/http"

	"gitlab.com/gitlab-org/gitlab/workhorse/internal/helper/fail"
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
			fail.Request(w, r, fmt.Errorf("contentEncodingHandler: %v", err))
			return
		}
		defer func() { _ = body.Close() }()

		r.Body = body
		r.Header.Del("Content-Encoding")

		h.ServeHTTP(w, r)
	})
}
