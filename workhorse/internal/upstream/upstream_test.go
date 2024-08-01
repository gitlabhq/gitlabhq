package upstream

import (
	"fmt"
	"io"
	"net/http"
	"net/http/httptest"
	"os"
	"testing"
	"time"

	"github.com/sirupsen/logrus"
	"github.com/stretchr/testify/assert"
	"github.com/stretchr/testify/require"

	apipkg "gitlab.com/gitlab-org/gitlab/workhorse/internal/api"
	"gitlab.com/gitlab-org/gitlab/workhorse/internal/config"
	"gitlab.com/gitlab-org/gitlab/workhorse/internal/helper"
	"gitlab.com/gitlab-org/gitlab/workhorse/internal/testhelper"
	"gitlab.com/gitlab-org/gitlab/workhorse/internal/upstream/roundtripper"
)

const (
	geoProxyEndpoint             = "/api/v4/geo/proxy"
	testDocumentRoot             = "testdata/public"
	geoProxyDisabledResponseBody = `{"geo_enabled":false}`
)

type testCase struct {
	desc             string
	path             string
	expectedResponse string
}

type testCasePost struct {
	test        testCase
	contentType string
	body        io.Reader
}

type testCaseRequest struct {
	desc            string
	method          string
	path            string
	headers         map[string]string
	expectedHeaders map[string]string
}

func TestMain(m *testing.M) {
	// Secret should be configured before any Geo API poll happens to prevent
	// race conditions where the first API call happens without a secret path
	testhelper.ConfigureSecret()

	os.Exit(m.Run())
}

func TestRouting(t *testing.T) {
	handle := func(u *upstream, regex string) routeEntry {
		handler := http.HandlerFunc(func(w http.ResponseWriter, _ *http.Request) {
			io.WriteString(w, regex)
		})
		metadata := routeMetadata{regex, "", ""}
		return u.route("", metadata, handler)
	}

	const (
		foobar = `\A/foobar\z`
		quxbaz = `\A/quxbaz\z`
		main   = ""
	)

	u := newUpstream(config.Config{}, logrus.StandardLogger(), func(u *upstream) {
		u.Routes = []routeEntry{
			handle(u, foobar),
			handle(u, quxbaz),
			handle(u, main),
		}
	}, nil)
	ts := httptest.NewServer(u)
	defer ts.Close()

	testCases := []testCase{
		{"main route works", "/", main},
		{"foobar route works", "/foobar", foobar},
		{"quxbaz route works", "/quxbaz", quxbaz},
		{"path traversal works, ends up in quxbaz", "/foobar/../quxbaz", quxbaz},
		{"escaped path traversal does not match any route", "/foobar%2f%2e%2e%2fquxbaz", main},
		{"double escaped path traversal does not match any route", "/foobar%252f%252e%252e%252fquxbaz", main},
	}

	runTestCases(t, ts, testCases)
}

func TestPollGeoProxyApiStopsWhenExplicitlyDisabled(t *testing.T) {
	up := upstream{
		enableGeoProxyFeature: false,
		geoProxyPollSleep:     func(time.Duration) {},
		geoPollerDone:         make(chan struct{}),
	}

	go up.pollGeoProxyAPI()

	select {
	case <-up.geoPollerDone:
		// happy
	case <-time.After(10 * time.Second):
		t.Fatal("timeout")
	}
}

func TestPollGeoProxyApiStopsWhenGeoNotEnabled(t *testing.T) {
	remoteServer := startRemoteServer(t)

	response := geoProxyDisabledResponseBody
	railsServer := startRailsServer(t, &response)

	cfg := newUpstreamConfig(railsServer.URL)
	roundTripper := roundtripper.NewBackendRoundTripper(cfg.Backend, "", 1*time.Minute, true)
	remoteServerURL := helper.URLMustParse(remoteServer.URL)

	up := upstream{
		Config:                *cfg,
		RoundTripper:          roundTripper,
		APIClient:             apipkg.NewAPI(remoteServerURL, "", roundTripper),
		enableGeoProxyFeature: true,
		geoProxyPollSleep:     func(time.Duration) {},
		geoPollerDone:         make(chan struct{}),
	}

	go up.pollGeoProxyAPI()

	select {
	case <-up.geoPollerDone:
		// happy
	case <-time.After(10 * time.Second):
		t.Fatal("timeout")
	}
}

// This test can be removed when the environment variable `GEO_SECONDARY_PROXY` is removed
func TestGeoProxyFeatureDisabledOnGeoSecondarySite(t *testing.T) {
	// We could just not set up the primary, but then we'd have to assert
	// that the internal API call isn't made. This is easier.
	remoteServer := startRemoteServer(t)

	geoProxyEndpointResponseBody := fmt.Sprintf(`{"geo_enabled":true,"geo_proxy_url":"%v"}`, remoteServer.URL)
	railsServer := startRailsServer(t, &geoProxyEndpointResponseBody)

	ws, _ := startWorkhorseServer(t, railsServer.URL, false)

	testCases := []testCase{
		{"jobs request is served locally", "/api/v4/jobs/request", "Local Rails server received request to path /api/v4/jobs/request"},
		{"health check is served locally", "/-/health", "Local Rails server received request to path /-/health"},
		{"unknown route is served locally", "/anything", "Local Rails server received request to path /anything"},
	}

	runTestCases(t, ws, testCases)
}

func TestGeoProxyFeatureEnabledOnGeoSecondarySite(t *testing.T) {
	testCases := []testCase{
		{"push from secondary is forwarded", "/-/push_from_secondary/foo/bar.git/info/refs", "Geo primary received request to path /-/push_from_secondary/foo/bar.git/info/refs"},
		{"LFS files are served locally", "/group/project.git/gitlab-lfs/objects/37446575700829a11278ad3a550f244f45d5ae4fe1552778fa4f041f9eaeecf6", "Local Rails server received request to path /group/project.git/gitlab-lfs/objects/37446575700829a11278ad3a550f244f45d5ae4fe1552778fa4f041f9eaeecf6"},
		{"jobs request is forwarded", "/api/v4/jobs/request", "Geo primary received request to path /api/v4/jobs/request"},
		{"health check is served locally", "/-/health", "Local Rails server received request to path /-/health"},
		{"unknown route is forwarded", "/anything", "Geo primary received request to path /anything"},
	}

	runTestCasesWithGeoProxyEnabled(t, testCases)
}

// This test can be removed when the environment variable `GEO_SECONDARY_PROXY` is removed
func TestGeoProxyFeatureDisabledOnNonGeoSecondarySite(t *testing.T) {
	response := geoProxyDisabledResponseBody
	railsServer := startRailsServer(t, &response)

	ws, _ := startWorkhorseServer(t, railsServer.URL, false)

	testCases := []testCase{
		{"LFS files are served locally", "/group/project.git/gitlab-lfs/objects/37446575700829a11278ad3a550f244f45d5ae4fe1552778fa4f041f9eaeecf6", "Local Rails server received request to path /group/project.git/gitlab-lfs/objects/37446575700829a11278ad3a550f244f45d5ae4fe1552778fa4f041f9eaeecf6"},
		{"jobs request is served locally", "/api/v4/jobs/request", "Local Rails server received request to path /api/v4/jobs/request"},
		{"health check is served locally", "/-/health", "Local Rails server received request to path /-/health"},
		{"unknown route is served locally", "/anything", "Local Rails server received request to path /anything"},
	}

	runTestCases(t, ws, testCases)
}

func TestGeoProxyFeatureEnabledOnNonGeoSecondarySite(t *testing.T) {
	response := geoProxyDisabledResponseBody
	railsServer := startRailsServer(t, &response)

	ws, _ := startWorkhorseServer(t, railsServer.URL, true)

	testCases := []testCase{
		{"LFS files are served locally", "/group/project.git/gitlab-lfs/objects/37446575700829a11278ad3a550f244f45d5ae4fe1552778fa4f041f9eaeecf6", "Local Rails server received request to path /group/project.git/gitlab-lfs/objects/37446575700829a11278ad3a550f244f45d5ae4fe1552778fa4f041f9eaeecf6"},
		{"jobs request is served locally", "/api/v4/jobs/request", "Local Rails server received request to path /api/v4/jobs/request"},
		{"health check is served locally", "/-/health", "Local Rails server received request to path /-/health"},
		{"unknown route is served locally", "/anything", "Local Rails server received request to path /anything"},
	}

	runTestCases(t, ws, testCases)
}

func TestGeoProxyFeatureEnabledButWithAPIError(t *testing.T) {
	geoProxyEndpointResponseBody := "Invalid response"
	railsServer := startRailsServer(t, &geoProxyEndpointResponseBody)

	ws, _ := startWorkhorseServer(t, railsServer.URL, true)

	testCases := []testCase{
		{"LFS files are served locally", "/group/project.git/gitlab-lfs/objects/37446575700829a11278ad3a550f244f45d5ae4fe1552778fa4f041f9eaeecf6", "Local Rails server received request to path /group/project.git/gitlab-lfs/objects/37446575700829a11278ad3a550f244f45d5ae4fe1552778fa4f041f9eaeecf6"},
		{"jobs request is served locally", "/api/v4/jobs/request", "Local Rails server received request to path /api/v4/jobs/request"},
		{"health check is served locally", "/-/health", "Local Rails server received request to path /-/health"},
		{"unknown route is served locally", "/anything", "Local Rails server received request to path /anything"},
	}

	runTestCases(t, ws, testCases)
}

func TestGeoProxyFeatureEnablingAndDisabling(t *testing.T) {
	remoteServer := startRemoteServer(t)

	geoProxyEndpointEnabledResponseBody := fmt.Sprintf(`{"geo_enabled":true,"geo_proxy_url":"%v"}`, remoteServer.URL)
	geoProxyEndpointDisabledResponseBody := `{"geo_enabled":true}`
	geoProxyEndpointResponseBody := geoProxyEndpointEnabledResponseBody

	railsServer := startRailsServer(t, &geoProxyEndpointResponseBody)

	ws, waitForNextAPIPoll := startWorkhorseServer(t, railsServer.URL, true)

	testCasesLocal := []testCase{
		{"LFS files are served locally", "/group/project.git/gitlab-lfs/objects/37446575700829a11278ad3a550f244f45d5ae4fe1552778fa4f041f9eaeecf6", "Local Rails server received request to path /group/project.git/gitlab-lfs/objects/37446575700829a11278ad3a550f244f45d5ae4fe1552778fa4f041f9eaeecf6"},
		{"jobs request is served locally", "/api/v4/jobs/request", "Local Rails server received request to path /api/v4/jobs/request"},
		{"health check is served locally", "/-/health", "Local Rails server received request to path /-/health"},
		{"unknown route is served locally", "/anything", "Local Rails server received request to path /anything"},
	}

	testCasesProxied := []testCase{
		{"push from secondary is forwarded", "/-/push_from_secondary/foo/bar.git/info/refs", "Geo primary received request to path /-/push_from_secondary/foo/bar.git/info/refs"},
		{"LFS files are served locally", "/group/project.git/gitlab-lfs/objects/37446575700829a11278ad3a550f244f45d5ae4fe1552778fa4f041f9eaeecf6", "Local Rails server received request to path /group/project.git/gitlab-lfs/objects/37446575700829a11278ad3a550f244f45d5ae4fe1552778fa4f041f9eaeecf6"},
		{"jobs request is forwarded", "/api/v4/jobs/request", "Geo primary received request to path /api/v4/jobs/request"},
		{"health check is served locally", "/-/health", "Local Rails server received request to path /-/health"},
		{"unknown route is forwarded", "/anything", "Geo primary received request to path /anything"},
	}

	// Enabled initially, run tests
	runTestCases(t, ws, testCasesProxied)

	// Disable proxying and run tests. It's safe to write to
	// geoProxyEndpointResponseBody because the polling goroutine is blocked.
	geoProxyEndpointResponseBody = geoProxyEndpointDisabledResponseBody
	waitForNextAPIPoll()

	runTestCases(t, ws, testCasesLocal)

	// Re-enable proxying and run tests
	geoProxyEndpointResponseBody = geoProxyEndpointEnabledResponseBody
	waitForNextAPIPoll()

	runTestCases(t, ws, testCasesProxied)
}

func TestGeoProxyUpdatesExtraDataWhenChanged(t *testing.T) {
	var expectedGeoProxyExtraData string

	remoteServer := httptest.NewServer(http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		assert.Equal(t, "1", r.Header.Get("Gitlab-Workhorse-Geo-Proxy"), "custom proxy header")
		assert.Equal(t, expectedGeoProxyExtraData, r.Header.Get("Gitlab-Workhorse-Geo-Proxy-Extra-Data"), "custom extra data header")
		w.WriteHeader(http.StatusOK)
	}))
	defer remoteServer.Close()

	geoProxyEndpointExtraData1 := fmt.Sprintf(`{"geo_enabled":true,"geo_proxy_url":"%v","geo_proxy_extra_data":"data1"}`, remoteServer.URL)
	geoProxyEndpointExtraData2 := fmt.Sprintf(`{"geo_enabled":true,"geo_proxy_url":"%v","geo_proxy_extra_data":"data2"}`, remoteServer.URL)
	geoProxyEndpointExtraData3 := fmt.Sprintf(`{"geo_enabled":true,"geo_proxy_url":"%v"}`, remoteServer.URL)
	geoProxyEndpointResponseBody := geoProxyEndpointExtraData1
	expectedGeoProxyExtraData = "data1"

	railsServer := startRailsServer(t, &geoProxyEndpointResponseBody)

	ws, waitForNextAPIPoll := startWorkhorseServer(t, railsServer.URL, true)

	res, err := http.Get(ws.URL)
	if err != nil {
		fmt.Printf("Error: %v", err)
	}
	defer res.Body.Close()

	// Verify that the expected header changes after next updated poll.
	geoProxyEndpointResponseBody = geoProxyEndpointExtraData2
	expectedGeoProxyExtraData = "data2"
	waitForNextAPIPoll()

	res, err = http.Get(ws.URL)
	if err != nil {
		fmt.Printf("Error: %v", err)
	}
	defer res.Body.Close()

	// Validate that non-existing extra data results in empty header
	geoProxyEndpointResponseBody = geoProxyEndpointExtraData3
	expectedGeoProxyExtraData = ""
	waitForNextAPIPoll()

	res, err = http.Get(ws.URL)
	if err != nil {
		fmt.Printf("Error: %v", err)
	}
	defer res.Body.Close()
}

func TestGeoProxySetsCustomHeader(t *testing.T) {
	testCases := []struct {
		desc      string
		json      string
		extraData string
	}{
		{"no extra data", `{"geo_enabled":true,"geo_proxy_url":"%v"}`, ""},
		{"with extra data", `{"geo_enabled":true,"geo_proxy_url":"%v","geo_proxy_extra_data":"extra-geo-data"}`, "extra-geo-data"},
	}

	for _, tc := range testCases {
		t.Run(tc.desc, func(t *testing.T) {
			remoteServer := httptest.NewServer(http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
				assert.Equal(t, "1", r.Header.Get("Gitlab-Workhorse-Geo-Proxy"), "custom proxy header")
				assert.Equal(t, tc.extraData, r.Header.Get("Gitlab-Workhorse-Geo-Proxy-Extra-Data"), "custom proxy extra data header")
				w.WriteHeader(http.StatusOK)
			}))
			defer remoteServer.Close()

			geoProxyEndpointResponseBody := fmt.Sprintf(tc.json, remoteServer.URL)
			railsServer := startRailsServer(t, &geoProxyEndpointResponseBody)

			ws, _ := startWorkhorseServer(t, railsServer.URL, true)

			res, err := http.Get(ws.URL)
			if err != nil {
				fmt.Printf("Error: %v", err)
			}
			defer res.Body.Close()
		})
	}
}

func runTestCases(t *testing.T, ws *httptest.Server, testCases []testCase) {
	t.Helper()
	for _, tc := range testCases {
		t.Run(tc.desc, func(t *testing.T) {
			resp, err := http.Get(ws.URL + tc.path)
			require.NoError(t, err)
			defer resp.Body.Close()

			body, err := io.ReadAll(resp.Body)
			require.NoError(t, err)

			require.Equal(t, 200, resp.StatusCode, "response code")
			require.Equal(t, tc.expectedResponse, string(body))
		})
	}
}

func runTestCasesPost(t *testing.T, ws *httptest.Server, testCases []testCasePost) {
	t.Helper()
	for _, tc := range testCases {
		t.Run(tc.test.desc, func(t *testing.T) {
			resp, err := http.Post(ws.URL+tc.test.path, tc.contentType, tc.body)
			require.NoError(t, err)
			defer resp.Body.Close()

			body, err := io.ReadAll(resp.Body)
			require.NoError(t, err)

			require.Equal(t, 200, resp.StatusCode, "response code")
			require.Equal(t, tc.test.expectedResponse, string(body))
		})
	}
}

func runTestCasesRequest(t *testing.T, ws *httptest.Server, testCases []testCaseRequest) {
	t.Helper()
	for _, tc := range testCases {
		t.Run(tc.desc, func(t *testing.T) {
			client := http.Client{}
			request, err := http.NewRequest(tc.method, ws.URL+tc.path, nil)
			require.NoError(t, err)
			for key, value := range tc.headers {
				request.Header.Set(key, value)
			}

			resp, err := client.Do(request)
			require.NoError(t, err)
			defer resp.Body.Close()

			require.Equal(t, 200, resp.StatusCode, "response code")
			for key, value := range tc.expectedHeaders {
				require.Equal(t, resp.Header.Get(key), value, fmt.Sprint("response header ", key))
			}
		})
	}
}

func runTestCasesWithGeoProxyEnabled(t *testing.T, testCases []testCase) {
	remoteServer := startRemoteServer(t)

	geoProxyEndpointResponseBody := fmt.Sprintf(`{"geo_enabled":true,"geo_proxy_url":"%v"}`, remoteServer.URL)
	railsServer := startRailsServer(t, &geoProxyEndpointResponseBody)

	ws, _ := startWorkhorseServer(t, railsServer.URL, true)

	runTestCases(t, ws, testCases)
}

func runTestCasesWithGeoProxyEnabledPost(t *testing.T, testCases []testCasePost) {
	remoteServer := startRemoteServer(t)

	geoProxyEndpointResponseBody := fmt.Sprintf(`{"geo_enabled":true,"geo_proxy_url":"%v"}`, remoteServer.URL)
	railsServer := startRailsServer(t, &geoProxyEndpointResponseBody)

	ws, _ := startWorkhorseServer(t, railsServer.URL, true)

	runTestCasesPost(t, ws, testCases)
}

func runTestCasesWithGeoProxyEnabledRequest(t *testing.T, testCases []testCaseRequest) {
	remoteServer := startRemoteServer(t)

	geoProxyEndpointResponseBody := fmt.Sprintf(`{"geo_enabled":true,"geo_proxy_url":"%v"}`, remoteServer.URL)
	railsServer := startRailsServer(t, &geoProxyEndpointResponseBody)

	ws, _ := startWorkhorseServer(t, railsServer.URL, true)

	runTestCasesRequest(t, ws, testCases)
}

func newUpstreamConfig(authBackend string) *config.Config {
	return &config.Config{
		Version:            "123",
		DocumentRoot:       testDocumentRoot,
		Backend:            helper.URLMustParse(authBackend),
		ImageResizerConfig: config.DefaultImageResizerConfig,
	}
}

func startRemoteServer(t *testing.T) *httptest.Server {
	ts := httptest.NewServer(http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		body := "Geo primary received request to path " + r.URL.Path

		w.WriteHeader(200)
		fmt.Fprint(w, body)
	}))

	t.Cleanup(func() {
		ts.Close()
	})

	return ts
}

func startRailsServer(t *testing.T, geoProxyEndpointResponseBody *string) *httptest.Server {
	ts := httptest.NewServer(http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		var body string

		if r.URL.Path == geoProxyEndpoint {
			w.Header().Set("Content-Type", "application/vnd.gitlab-workhorse+json")
			body = *geoProxyEndpointResponseBody
		} else {
			body = "Local Rails server received request to path " + r.URL.Path
		}

		w.WriteHeader(200)
		fmt.Fprint(w, body)
	}))

	t.Cleanup(func() {
		ts.Close()
	})

	return ts
}

func startWorkhorseServer(t *testing.T, railsServerURL string, enableGeoProxyFeature bool) (*httptest.Server, func()) {
	geoProxySleepC := make(chan struct{})
	geoProxySleep := func(time.Duration) {
		geoProxySleepC <- struct{}{}
		<-geoProxySleepC
	}

	myConfigureRoutes := func(u *upstream) {
		// Enable environment variable "feature flag"
		u.enableGeoProxyFeature = enableGeoProxyFeature

		// Replace the time.Sleep function with geoProxySleep
		u.geoProxyPollSleep = geoProxySleep

		// call original
		configureRoutes(u)
	}
	cfg := newUpstreamConfig(railsServerURL)
	upstreamHandler := newUpstream(*cfg, logrus.StandardLogger(), myConfigureRoutes, nil)
	ws := httptest.NewServer(upstreamHandler)

	t.Cleanup(func() {
		ws.Close()
	})

	waitForNextAPIPoll := func() {}

	if enableGeoProxyFeature {
		// Wait for geoProxySleep to be entered for the first time
		<-geoProxySleepC

		waitForNextAPIPoll = func() {
			// Cause geoProxySleep to return
			geoProxySleepC <- struct{}{}

			// Wait for geoProxySleep to be entered again
			<-geoProxySleepC
		}
	}

	return ws, waitForNextAPIPoll
}

func TestFixRemoteAddr(t *testing.T) {
	testCases := []struct {
		initial   string
		forwarded string
		expected  string
	}{
		{initial: "@", forwarded: "", expected: "127.0.0.1:0"},
		{initial: "@", forwarded: "18.245.0.1", expected: "18.245.0.1:0"},
		{initial: "@", forwarded: "127.0.0.1", expected: "127.0.0.1:0"},
		{initial: "@", forwarded: "192.168.0.1", expected: "127.0.0.1:0"},
		{initial: "192.168.1.1:0", forwarded: "", expected: "192.168.1.1:0"},
		{initial: "192.168.1.1:0", forwarded: "18.245.0.1", expected: "18.245.0.1:0"},
	}

	for _, tc := range testCases {
		req, err := http.NewRequest("POST", "unix:///tmp/test.socket/info/refs", nil)
		require.NoError(t, err)

		req.RemoteAddr = tc.initial

		if tc.forwarded != "" {
			req.Header.Add("X-Forwarded-For", tc.forwarded)
		}

		fixRemoteAddr(req)

		require.Equal(t, tc.expected, req.RemoteAddr)
	}
}
