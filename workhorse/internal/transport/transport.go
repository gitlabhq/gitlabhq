// Package transport provides a roundtripper for HTTP clients with Workhorse integration.
package transport

import (
	"net"
	"net/http"
	"time"

	"gitlab.com/gitlab-org/labkit/correlation"
	"gitlab.com/gitlab-org/labkit/tracing"

	"gitlab.com/gitlab-org/gitlab/workhorse/internal/version"
)

// NewDefaultTransport creates a new default transport that has Workhorse's User-Agent header set.
func NewDefaultTransport() http.RoundTripper {
	return &DefaultTransport{Next: http.DefaultTransport}
}

// NewRestrictedTransport defines a http.Transport with values that are more restrictive than for
// http.DefaultTransport, they define shorter TLS Handshake, and more
// aggressive connection closing to prevent the connection hanging and reduce
// FD usage
func NewRestrictedTransport(options ...Option) http.RoundTripper {
	return &DefaultTransport{Next: newRestrictedTransport(options...)}
}

// DefaultTransport is a roundtripper that sets the User-Agent header in requests
type DefaultTransport struct {
	Next http.RoundTripper
}

// RoundTrip sets the User-Agent header in the request and then forwards the request to the next RoundTripper.
func (t DefaultTransport) RoundTrip(req *http.Request) (*http.Response, error) {
	req.Header.Set("User-Agent", version.GetUserAgent())

	return t.Next.RoundTrip(req)
}

// Option is a functional option to configure the restricted transport.
type Option func(*http.Transport)

// WithDisabledCompression disables compression for the transport.
func WithDisabledCompression() Option {
	return func(t *http.Transport) {
		t.DisableCompression = true
	}
}

// WithDialTimeout sets the dial timeout for the transport.
func WithDialTimeout(timeout time.Duration) Option {
	return func(t *http.Transport) {
		t.DialContext = (&net.Dialer{
			Timeout: timeout,
		}).DialContext
	}
}

// WithResponseHeaderTimeout sets the response header timeout for the transport.
func WithResponseHeaderTimeout(timeout time.Duration) Option {
	return func(t *http.Transport) {
		t.ResponseHeaderTimeout = timeout
	}
}

func newRestrictedTransport(options ...Option) http.RoundTripper {
	t := http.DefaultTransport.(*http.Transport).Clone()

	// To avoid keep around TCP connections to http servers we're done with
	t.MaxIdleConns = 2

	// A stricter timeout for fetching from external sources that can be slow
	t.ResponseHeaderTimeout = 30 * time.Second

	for _, option := range options {
		option(t)
	}

	return tracing.NewRoundTripper(correlation.NewInstrumentedRoundTripper(t))
}
