package roundtripper

import (
	"crypto/tls"
	"crypto/x509"
	"fmt"
	"io"
	"net/http"
	"net/http/httptest"
	"net/url"
	"strconv"
	"testing"

	"github.com/stretchr/testify/require"
)

func TestMustParseAddress(t *testing.T) {
	successExamples := []struct{ address, scheme, expected string }{
		{"1.2.3.4:56", "http", "1.2.3.4:56"},
		{"[::1]:23", "http", "::1:23"},
		{"4.5.6.7", "http", "4.5.6.7:http"},
		{"4.5.6.7", "https", "4.5.6.7:https"},
	}
	for i, example := range successExamples {
		t.Run(strconv.Itoa(i), func(t *testing.T) {
			require.Equal(t, example.expected, mustParseAddress(example.address, example.scheme))
		})
	}
}

func TestMustParseAddressPanic(t *testing.T) {
	panicExamples := []struct{ address, scheme string }{
		{"1.2.3.4", ""},
	}

	for i, panicExample := range panicExamples {
		t.Run(strconv.Itoa(i), func(t *testing.T) {
			defer func() {
				if r := recover(); r == nil {
					t.Fatal("expected panic")
				}
			}()
			mustParseAddress(panicExample.address, panicExample.scheme)
		})
	}
}

func TestSupportsHTTPBackend(t *testing.T) {
	ts := httptest.NewServer(http.HandlerFunc(func(w http.ResponseWriter, _ *http.Request) {
		w.WriteHeader(200)
		fmt.Fprint(w, "successful response")
	}))
	defer ts.Close()

	testNewBackendRoundTripper(t, ts, nil, "successful response")
}

func TestSupportsHTTPSBackend(t *testing.T) {
	ts := httptest.NewTLSServer(http.HandlerFunc(func(w http.ResponseWriter, _ *http.Request) {
		w.WriteHeader(200)
		fmt.Fprint(w, "successful response")
	}))
	defer ts.Close()

	certpool := x509.NewCertPool()
	certpool.AddCert(ts.Certificate())
	tlsClientConfig := &tls.Config{
		RootCAs: certpool,
	}

	testNewBackendRoundTripper(t, ts, tlsClientConfig, "successful response")
}

func testNewBackendRoundTripper(t *testing.T, ts *httptest.Server, tlsClientConfig *tls.Config, expectedResponseBody string) {
	t.Helper()

	backend, err := url.Parse(ts.URL)
	require.NoError(t, err, "parse url")

	rt := newBackendRoundTripper(backend, "", 0, true, tlsClientConfig)

	req, err := http.NewRequest("GET", ts.URL+"/", nil)
	require.NoError(t, err, "build request")

	response, err := rt.RoundTrip(req)
	require.NoError(t, err, "perform roundtrip")
	defer response.Body.Close()

	body, err := io.ReadAll(response.Body)
	require.NoError(t, err)

	require.Equal(t, expectedResponseBody, string(body))
}
