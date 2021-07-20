package api

import (
	"fmt"
	"net/http"
	"net/http/httptest"
	"net/url"
	"regexp"
	"testing"

	"github.com/stretchr/testify/require"
	"gitlab.com/gitlab-org/labkit/log"

	"gitlab.com/gitlab-org/gitlab-workhorse/internal/helper"
	"gitlab.com/gitlab-org/gitlab-workhorse/internal/secret"
	"gitlab.com/gitlab-org/gitlab-workhorse/internal/testhelper"
	"gitlab.com/gitlab-org/gitlab-workhorse/internal/upstream/roundtripper"
)

func TestGetGeoProxyURLWhenGeoSecondary(t *testing.T) {
	geoProxyURL, err := getGeoProxyURLGivenResponse(t, `{"geo_proxy_url":"http://primary"}`)

	require.NoError(t, err)
	require.NotNil(t, geoProxyURL)
	require.Equal(t, "http://primary", geoProxyURL.String())
}

func TestGetGeoProxyURLWhenGeoPrimaryOrNonGeo(t *testing.T) {
	geoProxyURL, err := getGeoProxyURLGivenResponse(t, "{}")

	require.Error(t, err)
	require.Equal(t, ErrNotGeoSecondary, err)
	require.Nil(t, geoProxyURL)
}

func getGeoProxyURLGivenResponse(t *testing.T, givenInternalApiResponse string) (*url.URL, error) {
	t.Helper()
	ts := testRailsServer(regexp.MustCompile(`/api/v4/geo/proxy`), 200, givenInternalApiResponse)
	defer ts.Close()
	backend := helper.URLMustParse(ts.URL)
	version := "123"
	rt := roundtripper.NewTestBackendRoundTripper(backend)
	testhelper.ConfigureSecret()

	apiClient := NewAPI(backend, version, rt)

	geoProxyURL, err := apiClient.GetGeoProxyURL()

	return geoProxyURL, err
}

func testRailsServer(url *regexp.Regexp, code int, body string) *httptest.Server {
	return testhelper.TestServerWithHandler(url, func(w http.ResponseWriter, r *http.Request) {
		// return a 204 No Content response if we don't receive the JWT header
		if r.Header.Get(secret.RequestHeader) == "" {
			w.WriteHeader(204)
			return
		}

		w.Header().Set("Content-Type", ResponseContentType)

		logEntry := log.WithFields(log.Fields{
			"method": r.Method,
			"url":    r.URL,
		})
		logEntryWithCode := logEntry.WithField("code", code)

		// Write pure string
		logEntryWithCode.Info("UPSTREAM")

		w.WriteHeader(code)
		fmt.Fprint(w, body)
	})
}
