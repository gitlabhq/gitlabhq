// Package forwardheaders implements utility functions for forwarding headers from
// a response to a response writer
//
// This is meant to be used in sendurl and dependencyproxy packages.
package forwardheaders

import (
	"net/http"
	"slices"
	"strings"
)

const (
	contentTypeHeader   = "Content-Type"
	octetStreamMimeType = "application/octet-stream"
)

// Params represents the configuration used by this package.
type Params struct {
	Enabled   bool
	AllowList []string
}

// ForwardResponseHeaders will forward the headers from the passed upstream response to the response writer.
// If a header is forwarded or not depends on a few rules:
// * if a header is present in the preserveHeaderKeys slice, then it's not forwarded.
// * if enabled _and_ a header is present in the allow list, then it's forward.
// * if disabled, all headers (except those that are protected) are forwarded.
func (p *Params) ForwardResponseHeaders(w http.ResponseWriter, upstreamResponse *http.Response, preserveHeaderKeys []string, extraHeaders http.Header) {
	if p.Enabled {
		replaceContentType(upstreamResponse)
	}

	w.Header().Del("Content-Length")

	canonicalProtectedKeys := []string{}
	canonicalAllowedKeys := []string{}

	for _, header := range preserveHeaderKeys {
		canonicalProtectedKeys = append(canonicalProtectedKeys, http.CanonicalHeaderKey(header))
	}

	for _, header := range p.AllowList {
		canonicalAllowedKeys = append(canonicalAllowedKeys, http.CanonicalHeaderKey(header))
	}

	// forward headers according to the protected and allowed keys
	for key, value := range upstreamResponse.Header {
		if !slices.Contains(canonicalProtectedKeys, key) {
			if p.Enabled {
				if slices.Contains(canonicalAllowedKeys, key) {
					w.Header()[key] = value
				}
			} else {
				w.Header()[key] = value
			}
		}
	}

	// set the extra headers
	for key, values := range extraHeaders {
		w.Header().Del(key)
		for _, value := range values {
			w.Header().Add(key, value)
		}
	}
}

func replaceContentType(response *http.Response) {
	contentType := response.Header.Get(contentTypeHeader)

	if strings.HasPrefix(contentType, "multipart") {
		response.Header.Set(contentTypeHeader, octetStreamMimeType)
	}
}
