package main

import (
	"bytes"
	"fmt"
	"io"
	"net"
	"net/http"
	"net/http/httptest"
	"net/url"
	"regexp"
	"testing"
	"time"

	"gitlab.com/gitlab-org/gitlab/workhorse/internal/badgateway"
	"gitlab.com/gitlab-org/gitlab/workhorse/internal/helper"
	"gitlab.com/gitlab-org/gitlab/workhorse/internal/proxy"
	"gitlab.com/gitlab-org/gitlab/workhorse/internal/testhelper"
	"gitlab.com/gitlab-org/gitlab/workhorse/internal/upstream/roundtripper"

	"github.com/stretchr/testify/assert"
	"github.com/stretchr/testify/require"
)

const testVersion = "123"

func newProxy(url string, rt http.RoundTripper, opts ...func(*proxy.Proxy)) *proxy.Proxy {
	parsedURL := helper.URLMustParse(url)
	if rt == nil {
		rt = roundtripper.NewTestBackendRoundTripper(parsedURL)
	}
	return proxy.NewProxy(parsedURL, testVersion, rt, opts...)
}

func TestProxyRequest(t *testing.T) {
	inboundURL, err := url.Parse("https://explicitly.set.host/url/path")
	require.NoError(t, err, "parse inbound url")

	urlRegexp := regexp.MustCompile(fmt.Sprintf(`%s\z`, inboundURL.Path))
	ts := testhelper.TestServerWithHandler(urlRegexp, func(w http.ResponseWriter, r *http.Request) {
		assert.Equal(t, "POST", r.Method, "method")
		assert.Equal(t, "test", r.Header.Get("Custom-Header"), "custom header")
		assert.Equal(t, testVersion, r.Header.Get("Gitlab-Workhorse"), "version header")
		assert.Equal(t, inboundURL.Host, r.Host, "sent host header")
		assert.Empty(t, r.Header.Get("X-Forwarded-Host"), "X-Forwarded-Host header")
		assert.Empty(t, r.Header.Get("Forwarded"), "Forwarded header")

		assert.Regexp(
			t,
			regexp.MustCompile(`\A1`),
			r.Header.Get("Gitlab-Workhorse-Proxy-Start"),
			"expect Gitlab-Workhorse-Proxy-Start to start with 1",
		)

		body, readErr := io.ReadAll(r.Body)
		assert.NoError(t, readErr, "read body")
		assert.Equal(t, "REQUEST", string(body), "body contents")

		w.Header().Set("Custom-Response-Header", "test")
		w.WriteHeader(202)
		fmt.Fprint(w, "RESPONSE")
	})

	httpRequest, err := http.NewRequest("POST", inboundURL.String(), bytes.NewBufferString("REQUEST"))
	require.NoError(t, err)
	httpRequest.Header.Set("Custom-Header", "test")

	w := httptest.NewRecorder()
	newProxy(ts.URL, nil).ServeHTTP(w, httpRequest)
	require.Equal(t, 202, w.Code)
	testhelper.RequireResponseBody(t, w, "RESPONSE")

	require.Equal(t, "test", w.Header().Get("Custom-Response-Header"), "custom response header")
}

func TestProxyWithForcedTargetHostHeader(t *testing.T) {
	var tsURL *url.URL
	inboundURL, err := url.Parse("https://explicitly.set.host/url/path")
	require.NoError(t, err, "parse upstream url")

	urlRegexp := regexp.MustCompile(fmt.Sprintf(`%s\z`, inboundURL.Path))
	ts := testhelper.TestServerWithHandler(urlRegexp, func(w http.ResponseWriter, r *http.Request) {
		assert.Equal(t, tsURL.Host, r.Host, "upstream host header")
		assert.Equal(t, inboundURL.Host, r.Header.Get("X-Forwarded-Host"), "X-Forwarded-Host header")
		assert.Equal(t, fmt.Sprintf("host=%s", inboundURL.Host), r.Header.Get("Forwarded"), "Forwarded header")

		_, err = w.Write([]byte(`ok`))
		assert.NoError(t, err, "write ok response")
	})
	tsURL, err = url.Parse(ts.URL)
	require.NoError(t, err, "parse testserver URL")

	httpRequest, err := http.NewRequest("POST", inboundURL.String(), nil)
	require.NoError(t, err)

	w := httptest.NewRecorder()
	testProxy := newProxy(ts.URL, nil, proxy.WithForcedTargetHostHeader())
	testProxy.ServeHTTP(w, httpRequest)
	testhelper.RequireResponseBody(t, w, "ok")
}

func TestProxyWithCustomHeaders(t *testing.T) {
	ts := testhelper.TestServerWithHandler(regexp.MustCompile(`/url/path\z`), func(w http.ResponseWriter, r *http.Request) {
		assert.Equal(t, "value", r.Header.Get("Custom-Header"), "custom proxy header")
		assert.Equal(t, testVersion, r.Header.Get("Gitlab-Workhorse"), "version header")

		_, err := w.Write([]byte(`ok`))
		assert.NoError(t, err, "write ok response")
	})

	httpRequest, err := http.NewRequest("POST", ts.URL+"/url/path", nil)
	require.NoError(t, err)

	w := httptest.NewRecorder()
	testProxy := newProxy(ts.URL, nil, proxy.WithCustomHeaders(map[string]string{"Custom-Header": "value"}))
	testProxy.ServeHTTP(w, httpRequest)
	testhelper.RequireResponseBody(t, w, "ok")
}

func TestProxyError(t *testing.T) {
	httpRequest, err := http.NewRequest("POST", "/url/path", bytes.NewBufferString("REQUEST"))
	require.NoError(t, err)
	httpRequest.Header.Set("Custom-Header", "test")

	w := httptest.NewRecorder()
	newProxy("http://localhost:655575/", nil).ServeHTTP(w, httpRequest)
	require.Equal(t, 502, w.Code)
	require.Regexp(t, regexp.MustCompile("dial tcp:.*invalid port.*"), w.Body.String(), "response body")
}

func TestProxyReadTimeout(t *testing.T) {
	ts := testhelper.TestServerWithHandler(nil, func(_ http.ResponseWriter, _ *http.Request) {
		time.Sleep(time.Minute)
	})

	httpRequest, err := http.NewRequest("POST", "http://localhost/url/path", nil)
	require.NoError(t, err)

	rt := badgateway.NewRoundTripper(false, &http.Transport{
		Proxy: http.ProxyFromEnvironment,
		Dial: (&net.Dialer{
			Timeout:   30 * time.Second,
			KeepAlive: 30 * time.Second,
		}).Dial,
		TLSHandshakeTimeout:   10 * time.Second,
		ResponseHeaderTimeout: time.Millisecond,
	})

	p := newProxy(ts.URL, rt)
	w := httptest.NewRecorder()
	p.ServeHTTP(w, httpRequest)
	require.Equal(t, 502, w.Code)
	testhelper.RequireResponseBody(t, w, "GitLab is not responding")
}

func TestProxyHandlerTimeout(t *testing.T) {
	ts := testhelper.TestServerWithHandler(nil,
		http.TimeoutHandler(http.HandlerFunc(func(_ http.ResponseWriter, _ *http.Request) {
			time.Sleep(time.Second)
		}), time.Millisecond, "Request took too long").ServeHTTP,
	)

	httpRequest, err := http.NewRequest("POST", "http://localhost/url/path", nil)
	require.NoError(t, err)

	w := httptest.NewRecorder()
	newProxy(ts.URL, nil).ServeHTTP(w, httpRequest)
	require.Equal(t, 503, w.Code)
	testhelper.RequireResponseBody(t, w, "Request took too long")
}
