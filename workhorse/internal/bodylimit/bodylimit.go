// Package bodylimit provides HTTP request body size limiting functionality
// for RoundTrippers, supporting different enforcement modes including
// logging and strict enforcement with configurable size limits.
package bodylimit

import (
	"errors"
	"fmt"
	"io"
	"net/http"
	"strings"
	"sync/atomic"
)

// Mode defines the behavior of the request body middleware
type Mode int

// contextKey to hold a body limit per request
type contextKey string

// BodyLimitKey is the context key used to store the request body size limit
const BodyLimitKey contextKey = "bodyLimit"

// BodyLimitMode is the context key used to store the mode for the request
const BodyLimitMode contextKey = "bodyLimitMode"

const (
	// ModeUseGlobal - use global mode configuration (sentinel value)
	ModeUseGlobal Mode = -1
	// ModeDisabled - no body size checking
	ModeDisabled Mode = iota
	// ModeLogging - log when body size exceeds limit but allow request to continue
	ModeLogging
	// ModeEnforced - reject requests that exceed body size limit
	ModeEnforced
)

// RequestBodyTooLargeError is returned when a request body exceeds the configured size limit.
type RequestBodyTooLargeError struct {
	Limit int64
	Read  int64
}

func (e *RequestBodyTooLargeError) Error() string {
	return fmt.Sprintf("request body too large: read %d bytes, limit %d bytes", e.Read, e.Limit)
}

// countingReadCloser wraps an io.ReadCloser to count bytes read
type countingReadCloser struct {
	reader io.ReadCloser
	count  int64
	limit  int64
	mode   Mode
}

func (crc *countingReadCloser) Read(p []byte) (n int, err error) {
	// Validate the next read to avoid EOF errors
	if crc.mode == ModeEnforced {
		currentCount := atomic.LoadInt64(&crc.count)
		remaining := crc.limit - currentCount
		if remaining <= 0 {
			return 0, &RequestBodyTooLargeError{Limit: crc.limit, Read: currentCount}
		}
		// Only read up to the remaining limit
		if int64(len(p)) > remaining {
			p = p[:remaining]
		}
	}

	n, err = crc.reader.Read(p)
	atomic.AddInt64(&crc.count, int64(n))

	return n, err
}

func (crc *countingReadCloser) Close() error {
	return crc.reader.Close()
}

func (crc *countingReadCloser) Count() int64 {
	return atomic.LoadInt64(&crc.count)
}

type roundTripper struct {
	next http.RoundTripper
	mode Mode
}

// NewRoundTripper creates a RoundTripper that logs or blocks requests
// with request body size over the specified limit.
func NewRoundTripper(next http.RoundTripper, mode Mode) http.RoundTripper {
	return &roundTripper{next: next, mode: mode}
}

func (t *roundTripper) RoundTrip(r *http.Request) (*http.Response, error) {
	// If mode redefined for the request, use it
	mode, ok := r.Context().Value(BodyLimitMode).(Mode)
	if !ok {
		// Otherwise, use mode from the global configuration
		mode = t.mode
	}

	// If disabled, just pass through
	if mode == ModeDisabled {
		return t.next.RoundTrip(r)
	}

	// Extract limit from the provided context
	bodyLimit, ok := r.Context().Value(BodyLimitKey).(int64)
	if !ok || bodyLimit < 1 {
		return t.next.RoundTrip(r)
	}

	// Handle empty request body case
	if r.Body == nil {
		return t.next.RoundTrip(r)
	}

	// Use a custom reader to count
	bytesCounter := &countingReadCloser{reader: r.Body, count: 0, limit: bodyLimit, mode: mode}
	r.Body = bytesCounter

	res, err := t.next.RoundTrip(r)

	// Enforced mode processing
	if mode == ModeEnforced && err != nil {
		var bodyTooLargeErr *RequestBodyTooLargeError
		// Return 413 error code when request body is too large
		if errors.As(err, &bodyTooLargeErr) {
			return &http.Response{
				Status:     http.StatusText(http.StatusRequestEntityTooLarge),
				StatusCode: http.StatusRequestEntityTooLarge,
				Proto:      r.Proto,
				ProtoMajor: r.ProtoMajor,
				ProtoMinor: r.ProtoMinor,
				Body:       io.NopCloser(strings.NewReader("Request Entity Too Large")),
				Request:    r,
				Header:     make(http.Header),
				Trailer:    make(http.Header),
			}, nil
		}
	}

	return res, err
}
