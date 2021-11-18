package httptransport

import (
	"net/http"
	"time"

	"gitlab.com/gitlab-org/labkit/correlation"
	"gitlab.com/gitlab-org/labkit/tracing"
)

type Option func(*http.Transport)

// Defines a http.Transport with values
// that are more restrictive than for http.DefaultTransport,
// they define shorter TLS Handshake, and more aggressive connection closing
// to prevent the connection hanging and reduce FD usage
func New(options ...Option) http.RoundTripper {
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

func WithDisabledCompression() Option {
	return func(t *http.Transport) {
		t.DisableCompression = true
	}
}
