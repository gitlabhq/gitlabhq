package roundtripper

import (
	"context"
	"fmt"
	"net"
	"net/http"
	"net/url"
	"time"

	"gitlab.com/gitlab-org/labkit/correlation"
	"gitlab.com/gitlab-org/labkit/tracing"

	"gitlab.com/gitlab-org/gitlab/workhorse/internal/badgateway"
)

func mustParseAddress(address, scheme string) string {
	if scheme == "https" {
		panic("TLS is not supported for backend connections")
	}

	for _, suffix := range []string{"", ":" + scheme} {
		address += suffix
		if host, port, err := net.SplitHostPort(address); err == nil && host != "" && port != "" {
			return host + ":" + port
		}
	}

	panic(fmt.Errorf("could not parse host:port from address %q and scheme %q", address, scheme))
}

// NewBackendRoundTripper returns a new RoundTripper instance using the provided values
func NewBackendRoundTripper(backend *url.URL, socket string, proxyHeadersTimeout time.Duration, developmentMode bool) http.RoundTripper {
	// Copied from the definition of http.DefaultTransport. We can't literally copy http.DefaultTransport because of its hidden internal state.
	transport, dialer := newBackendTransport()
	transport.ResponseHeaderTimeout = proxyHeadersTimeout

	if backend != nil && socket == "" {
		address := mustParseAddress(backend.Host, backend.Scheme)
		transport.DialContext = func(ctx context.Context, network, addr string) (net.Conn, error) {
			return dialer.DialContext(ctx, "tcp", address)
		}
	} else if socket != "" {
		transport.DialContext = func(ctx context.Context, network, addr string) (net.Conn, error) {
			return dialer.DialContext(ctx, "unix", socket)
		}
	} else {
		panic("backend is nil and socket is empty")
	}

	return tracing.NewRoundTripper(
		correlation.NewInstrumentedRoundTripper(
			badgateway.NewRoundTripper(developmentMode, transport),
		),
	)
}

// NewTestBackendRoundTripper sets up a RoundTripper for testing purposes
func NewTestBackendRoundTripper(backend *url.URL) http.RoundTripper {
	return NewBackendRoundTripper(backend, "", 0, true)
}
