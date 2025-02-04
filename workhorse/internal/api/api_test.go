package api

import (
	"context"
	"encoding/json"
	"fmt"
	"io"
	"net/http"
	"net/http/httptest"
	"net/url"
	"regexp"
	"strings"
	"testing"

	"github.com/stretchr/testify/assert"
	"github.com/stretchr/testify/require"
	"gitlab.com/gitlab-org/gitaly/v16/proto/go/gitalypb"

	"gitlab.com/gitlab-org/gitlab/workhorse/internal/helper"
	"gitlab.com/gitlab-org/gitlab/workhorse/internal/secret"
	"gitlab.com/gitlab-org/gitlab/workhorse/internal/testhelper"
	"gitlab.com/gitlab-org/gitlab/workhorse/internal/upstream/roundtripper"
)

const (
	customPath = "/my/api/path"
)

func TestGetGeoProxyDataForResponses(t *testing.T) {
	testCases := []struct {
		desc              string
		json              string
		expectedError     bool
		expectedURL       string
		expectedExtraData string
	}{
		{"when Geo secondary", `{"geo_proxy_url":"http://primary","geo_proxy_extra_data":"geo-data"}`, false, "http://primary", "geo-data"},
		{"when Geo secondary with explicit null data", `{"geo_proxy_url":"http://primary","geo_proxy_extra_data":null}`, false, "http://primary", ""},
		{"when Geo secondary without extra data", `{"geo_proxy_url":"http://primary"}`, false, "http://primary", ""},
		{"when Geo primary or no node", `{}`, false, "", ""},
		{"for malformed request", `non-json`, true, "", ""},
	}

	for _, tc := range testCases {
		t.Run(tc.desc, func(t *testing.T) {
			geoProxyData, err := getGeoProxyDataGivenResponse(t, tc.json)

			if tc.expectedError {
				require.Error(t, err)
			} else {
				require.NoError(t, err)
				require.Equal(t, tc.expectedURL, geoProxyData.GeoProxyURL.String())
				require.Equal(t, tc.expectedExtraData, geoProxyData.GeoProxyExtraData)
			}
		})
	}
}

func TestPreAuthorizeFixedPath_OK(t *testing.T) {
	var (
		upstreamHeaders http.Header
		upstreamQuery   url.Values
	)

	ts := httptest.NewServer(http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		if r.URL.Path != customPath {
			return
		}

		upstreamHeaders = r.Header
		upstreamQuery = r.URL.Query()

		w.Header().Set("Content-Type", ResponseContentType)
		io.WriteString(w, `{"TempPath":"HELLO!!"}`)
	}))
	defer ts.Close()

	req, err := http.NewRequest("GET", "/original/request/path?q1=Q1&q2=Q2", nil)
	require.NoError(t, err)
	req.Header.Set("key1", "value1")

	api := NewAPI(helper.URLMustParse(ts.URL), "123", http.DefaultTransport)
	resp, err := api.PreAuthorizeFixedPath(req, "POST", customPath)
	require.NoError(t, err)

	require.Equal(t, "value1", upstreamHeaders.Get("key1"), "original headers must propagate")
	require.Equal(t, url.Values{"q1": []string{"Q1"}, "q2": []string{"Q2"}}, upstreamQuery,
		"original query must propagate")
	require.Equal(t, "HELLO!!", resp.TempPath, "sanity check: successful API call")
}

func TestPreAuthorizeFixedPath_Unauthorized(t *testing.T) {
	ts := httptest.NewServer(http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		if r.URL.Path != customPath {
			return
		}

		w.WriteHeader(http.StatusUnauthorized)
	}))
	defer ts.Close()

	req, err := http.NewRequest("GET", "/original/request/path?q1=Q1&q2=Q2", nil)
	require.NoError(t, err)

	api := NewAPI(helper.URLMustParse(ts.URL), "123", http.DefaultTransport)
	resp, err := api.PreAuthorizeFixedPath(req, "POST", "/my/api/path")
	require.Nil(t, resp)
	preAuthError := &PreAuthorizeFixedPathError{StatusCode: 401, Status: "Unauthorized 401"}
	require.ErrorAs(t, err, &preAuthError)
}

func TestPreAuthorizeHandler_NotFound(t *testing.T) {
	ts := httptest.NewServer(http.HandlerFunc(func(w http.ResponseWriter, _ *http.Request) {
		w.WriteHeader(http.StatusNotFound)
		w.Header().Set("Content-Type", "text/plain; charset=utf-8")
		io.WriteString(w, strings.Repeat("a", failureResponseLimit+100))
	}))
	defer ts.Close()

	req, err := http.NewRequest("GET", "/original/request/path", nil)
	require.NoError(t, err)

	api := NewAPI(helper.URLMustParse(ts.URL), "123", http.DefaultTransport)

	handler := api.PreAuthorizeHandler(func(_ http.ResponseWriter, _ *http.Request, _ *Response) {}, "/api/v4/internal/authorized_request")

	rr := httptest.NewRecorder()
	handler.ServeHTTP(rr, req)

	require.Equal(t, http.StatusNotFound, rr.Code)
}

func getGeoProxyDataGivenResponse(t *testing.T, givenInternalAPIResponse string) (*GeoProxyData, error) {
	t.Helper()
	ts := testRailsServer(regexp.MustCompile(`/api/v4/geo/proxy`), 200, givenInternalAPIResponse)
	defer ts.Close()
	backend := helper.URLMustParse(ts.URL)
	version := "123"
	rt := roundtripper.NewTestBackendRoundTripper(backend)
	testhelper.ConfigureSecret()

	apiClient := NewAPI(backend, version, rt)

	geoProxyData, err := apiClient.GetGeoProxyData()

	return geoProxyData, err
}

func testRailsServer(url *regexp.Regexp, code int, body string) *httptest.Server {
	return testhelper.TestServerWithHandlerWithGeoPolling(url, func(w http.ResponseWriter, r *http.Request) {
		// return a 204 No Content response if we don't receive the JWT header
		if r.Header.Get(secret.RequestHeader) == "" {
			w.WriteHeader(204)
			return
		}

		w.Header().Set("Content-Type", ResponseContentType)

		w.WriteHeader(code)
		fmt.Fprint(w, body)
	})
}

func TestPreAuthorizeFixedPath(t *testing.T) {
	var (
		upstreamHeaders http.Header
		upstreamQuery   url.Values
	)

	ts := httptest.NewServer(http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		if r.URL.Path != "/my/api/path" {
			return
		}

		upstreamHeaders = r.Header
		upstreamQuery = r.URL.Query()
		w.Header().Set("Content-Type", ResponseContentType)
		io.WriteString(w, `{"TempPath":"HELLO!!"}`)
	}))
	defer ts.Close()

	req, err := http.NewRequest("GET", "/original/request/path?q1=Q1&q2=Q2", nil)
	require.NoError(t, err)
	req.Header.Set("key1", "value1")

	api := NewAPI(helper.URLMustParse(ts.URL), "123", http.DefaultTransport)
	resp, err := api.PreAuthorizeFixedPath(req, "POST", "/my/api/path")
	require.NoError(t, err)

	require.Equal(t, "value1", upstreamHeaders.Get("key1"), "original headers must propagate")
	require.Equal(t, url.Values{"q1": []string{"Q1"}, "q2": []string{"Q2"}}, upstreamQuery,
		"original query must propagate")
	require.Equal(t, "HELLO!!", resp.TempPath, "sanity check: successful API call")
}

func TestSendGitAuditEvent(t *testing.T) {
	testhelper.ConfigureSecret()

	var (
		requestHeaders http.Header
		requestBody    GitAuditEventRequest
	)

	ts := httptest.NewServer(http.HandlerFunc(func(_ http.ResponseWriter, r *http.Request) {
		if r.URL.Path != "/api/v4/internal/shellhorse/git_audit_event" {
			return
		}

		requestHeaders = r.Header
		defer r.Body.Close()
		b, err := io.ReadAll(r.Body)
		assert.NoError(t, err)
		err = json.Unmarshal(b, &requestBody)
		assert.NoError(t, err)
	}))
	defer ts.Close()

	api := NewAPI(helper.URLMustParse(ts.URL), "123", http.DefaultTransport)
	auditRequest := GitAuditEventRequest{
		Action:   "git-receive-request",
		Protocol: "http",
		Repo:     "project-1",
		Username: "GitLab-Shell",
		PackfileStats: &gitalypb.PackfileNegotiationStatistics{
			Wants: 3,
			Haves: 23,
		},
	}
	err := api.SendGitAuditEvent(context.Background(), auditRequest)
	require.NoError(t, err)

	require.NotEmpty(t, requestHeaders)
	require.NotEmpty(t, requestHeaders["Gitlab-Workhorse-Api-Request"])
	require.Equal(t, auditRequest, requestBody)
}
