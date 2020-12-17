package roundtripper

import (
	"net"
	"net/http"
	"time"
)

// newBackendTransport setups the default HTTP transport which Workhorse uses
// to communicate with the upstream
func newBackendTransport() (*http.Transport, *net.Dialer) {
	dialler := &net.Dialer{
		Timeout:   30 * time.Second,
		KeepAlive: 30 * time.Second,
	}

	transport := &http.Transport{
		Proxy:                 http.ProxyFromEnvironment,
		DialContext:           dialler.DialContext,
		MaxIdleConns:          100,
		IdleConnTimeout:       90 * time.Second,
		TLSHandshakeTimeout:   10 * time.Second,
		ExpectContinueTimeout: 1 * time.Second,
	}

	return transport, dialler
}
