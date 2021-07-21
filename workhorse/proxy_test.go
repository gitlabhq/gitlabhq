package main

import (
	"bytes"
	"fmt"
	"io/ioutil"
	"net"
	"net/http"
	"net/http/httptest"
	"regexp"
	"testing"
	"time"

	"gitlab.com/gitlab-org/gitlab/workhorse/internal/badgateway"
	"gitlab.com/gitlab-org/gitlab/workhorse/internal/helper"
	"gitlab.com/gitlab-org/gitlab/workhorse/internal/proxy"
	"gitlab.com/gitlab-org/gitlab/workhorse/internal/testhelper"
	"gitlab.com/gitlab-org/gitlab/workhorse/internal/upstream/roundtripper"

	"github.com/stretchr/testify/require"
)

const testVersion = "123"

func newProxy(url string, rt http.RoundTripper) *proxy.Proxy {
	parsedURL := helper.URLMustParse(url)
	if rt == nil {
		rt = roundtripper.NewTestBackendRoundTripper(parsedURL)
	}
	return proxy.NewProxy(parsedURL, testVersion, rt)
}

func TestProxyRequest(t *testing.T) {
	ts := testhelper.TestServerWithHandler(regexp.MustCompile(`/url/path\z`), func(w http.ResponseWriter, r *http.Request) {
		require.Equal(t, "POST", r.Method, "method")
		require.Equal(t, "test", r.Header.Get("Custom-Header"), "custom header")
		require.Equal(t, testVersion, r.Header.Get("Gitlab-Workhorse"), "version header")

		require.Regexp(
			t,
			regexp.MustCompile(`\A1`),
			r.Header.Get("Gitlab-Workhorse-Proxy-Start"),
			"expect Gitlab-Workhorse-Proxy-Start to start with 1",
		)

		body, err := ioutil.ReadAll(r.Body)
		require.NoError(t, err, "read body")
		require.Equal(t, "REQUEST", string(body), "body contents")

		w.Header().Set("Custom-Response-Header", "test")
		w.WriteHeader(202)
		fmt.Fprint(w, "RESPONSE")
	})

	httpRequest, err := http.NewRequest("POST", ts.URL+"/url/path", bytes.NewBufferString("REQUEST"))
	require.NoError(t, err)
	httpRequest.Header.Set("Custom-Header", "test")

	w := httptest.NewRecorder()
	newProxy(ts.URL, nil).ServeHTTP(w, httpRequest)
	require.Equal(t, 202, w.Code)
	testhelper.RequireResponseBody(t, w, "RESPONSE")

	require.Equal(t, "test", w.Header().Get("Custom-Response-Header"), "custom response header")
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
	ts := testhelper.TestServerWithHandler(nil, func(w http.ResponseWriter, r *http.Request) {
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
		http.TimeoutHandler(http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
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
