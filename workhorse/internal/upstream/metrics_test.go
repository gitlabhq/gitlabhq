package upstream

import (
	"io"
	"net/http"
	"net/http/httptest"
	"testing"

	"github.com/prometheus/client_golang/prometheus/testutil"
	"github.com/sirupsen/logrus"
	"github.com/stretchr/testify/require"

	"gitlab.com/gitlab-org/gitlab/workhorse/internal/config"
)

type metricsTestCase struct {
	desc     string
	path     string
	metadata routeMetadata
}

func runMetricsTestCases(t *testing.T, ws *httptest.Server, testCases []metricsTestCase) {
	t.Helper()
	for _, tc := range testCases {
		t.Run(tc.desc, func(t *testing.T) {
			resp, err := http.Get(ws.URL + tc.path)
			require.NoError(t, err)
			defer resp.Body.Close()

			body, err := io.ReadAll(resp.Body)
			require.NoError(t, err)

			require.Equal(t, 200, resp.StatusCode, "response code")
			require.Equal(t, tc.metadata.regexpStr, string(body))
		})
	}
}

func TestInstrumentGeoProxyRoute(t *testing.T) {
	remote := routeMetadata{`\A/remote\z`, "remote", "remote"}
	local := routeMetadata{`\A/local\z`, "local", "local"}
	main := routeMetadata{"", "default", "default"}

	u := newUpstream(config.Config{}, logrus.StandardLogger(), func(u *upstream) {
		u.Routes = []routeEntry{
			handleRouteWithMatchers(u, remote, withGeoProxy()),
			handleRouteWithMatchers(u, local),
			handleRouteWithMatchers(u, main),
		}
	}, nil)
	ts := httptest.NewServer(u)
	defer ts.Close()

	testCases := []metricsTestCase{
		{"remote", "/remote", remote},
		{"local", "/local", local},
		{"main", "/", main},
	}

	httpGeoProxiedRequestsTotal.Reset()

	runMetricsTestCases(t, ts, testCases)

	require.Equal(t, 1, testutil.CollectAndCount(httpGeoProxiedRequestsTotal))
	require.InDelta(t, 1, testutil.ToFloat64(httpGeoProxiedRequestsTotal.WithLabelValues("200", "get", remote.regexpStr, remote.routeID, string(remote.backendID))), 0.1)
	require.InDelta(t, 0, testutil.ToFloat64(httpGeoProxiedRequestsTotal.WithLabelValues("200", "get", local.regexpStr, local.routeID, string(local.backendID))), 0.1)
	require.InDelta(t, 0, testutil.ToFloat64(httpGeoProxiedRequestsTotal.WithLabelValues("200", "get", main.regexpStr, main.routeID, string(main.backendID))), 0.1)
}

func handleRouteWithMatchers(u *upstream, metadata routeMetadata, matchers ...func(*routeOptions)) routeEntry {
	handler := http.HandlerFunc(func(w http.ResponseWriter, _ *http.Request) {
		io.WriteString(w, metadata.regexpStr)
	})
	return u.route("", metadata, handler, matchers...)
}
