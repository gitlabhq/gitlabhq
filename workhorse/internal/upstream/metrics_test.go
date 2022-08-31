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

func TestInstrumentGeoProxyRoute(t *testing.T) {
	const (
		remote = `\A/remote\z`
		local  = `\A/local\z`
		main   = ""
	)

	u := newUpstream(config.Config{}, logrus.StandardLogger(), func(u *upstream) {
		u.Routes = []routeEntry{
			handleRouteWithMatchers(u, remote, withGeoProxy()),
			handleRouteWithMatchers(u, local),
			handleRouteWithMatchers(u, main),
		}
	}, nil)
	ts := httptest.NewServer(u)
	defer ts.Close()

	testCases := []testCase{
		{"remote", "/remote", remote},
		{"local", "/local", local},
		{"main", "/", main},
	}

	httpGeoProxiedRequestsTotal.Reset()

	runTestCases(t, ts, testCases)

	require.Equal(t, 1, testutil.CollectAndCount(httpGeoProxiedRequestsTotal))
	require.InDelta(t, 1, testutil.ToFloat64(httpGeoProxiedRequestsTotal.WithLabelValues("200", "get", remote)), 0.1)
	require.InDelta(t, 0, testutil.ToFloat64(httpGeoProxiedRequestsTotal.WithLabelValues("200", "get", local)), 0.1)
	require.InDelta(t, 0, testutil.ToFloat64(httpGeoProxiedRequestsTotal.WithLabelValues("200", "get", main)), 0.1)
}

func handleRouteWithMatchers(u *upstream, regex string, matchers ...func(*routeOptions)) routeEntry {
	handler := http.HandlerFunc(func(w http.ResponseWriter, _ *http.Request) {
		io.WriteString(w, regex)
	})
	return u.route("", regex, handler, matchers...)
}
