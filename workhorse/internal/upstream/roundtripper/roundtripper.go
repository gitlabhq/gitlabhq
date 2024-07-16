/*
Package roundtripper provides a custom HTTP roundtripper for handling requests.

This package implements a custom HTTP transport for handling HTTP requests
with additional features such as logging, tracing, and error handling.
*/
package roundtripper

import (
	"context"
	"crypto/tls"
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
	return newBackendRoundTripper(backend, socket, proxyHeadersTimeout, developmentMode, nil)
}

func newBackendRoundTripper(backend *url.URL, socket string, proxyHeadersTimeout time.Duration, developmentMode bool, tlsConf *tls.Config) http.RoundTripper {
	transport := http.DefaultTransport.(*http.Transport).Clone()
	transport.ResponseHeaderTimeout = proxyHeadersTimeout
	transport.TLSClientConfig = tlsConf

	// Puma does not support http/2, there's no point in reconnecting
	transport.ForceAttemptHTTP2 = false

	dial := transport.DialContext

	switch {
	case backend != nil && socket == "":
		address := mustParseAddress(backend.Host, backend.Scheme)
		transport.DialContext = func(ctx context.Context, _, _ string) (net.Conn, error) {
			return dial(ctx, "tcp", address)
		}
	case socket != "":
		transport.DialContext = func(ctx context.Context, _, _ string) (net.Conn, error) {
			return dial(ctx, "unix", socket)
		}
	default:
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
