package transport

import (
	"net"
	"net/http"
	"time"

	"gitlab.com/gitlab-org/labkit/correlation"
	"gitlab.com/gitlab-org/labkit/tracing"

	"gitlab.com/gitlab-org/gitlab/workhorse/internal/version"
)

// Creates a new default transport that has Workhorse's User-Agent header set.
func NewDefaultTransport() http.RoundTripper {
	return &DefaultTransport{Next: http.DefaultTransport}
}

// Defines a http.Transport with values that are more restrictive than for
// http.DefaultTransport, they define shorter TLS Handshake, and more
// aggressive connection closing to prevent the connection hanging and reduce
// FD usage
func NewRestrictedTransport(options ...Option) http.RoundTripper {
	return &DefaultTransport{Next: newRestrictedTransport(options...)}
}

type DefaultTransport struct {
	Next http.RoundTripper
}

func (t DefaultTransport) RoundTrip(req *http.Request) (*http.Response, error) {
	req.Header.Set("User-Agent", version.GetUserAgent())

	return t.Next.RoundTrip(req)
}

type Option func(*http.Transport)

func WithDisabledCompression() Option {
	return func(t *http.Transport) {
		t.DisableCompression = true
	}
}

func WithDialTimeout(timeout time.Duration) Option {
	return func(t *http.Transport) {
		t.DialContext = (&net.Dialer{
			Timeout: timeout,
		}).DialContext
	}
}

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
