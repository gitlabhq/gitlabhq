package upstream

import (
	"net/http"

	"github.com/prometheus/client_golang/prometheus"
	"github.com/prometheus/client_golang/prometheus/promauto"
	"github.com/prometheus/client_golang/prometheus/promhttp"

	"gitlab.com/gitlab-org/labkit/metrics"
)

const (
	namespace     = "gitlab_workhorse"
	httpSubsystem = "http"
)

var (
	httpGeoProxiedRequestsTotal = promauto.NewCounterVec(
		prometheus.CounterOpts{
			Namespace: namespace,
			Subsystem: httpSubsystem,
			Name:      "geo_proxied_requests_total",
			Help:      "A counter for Geo proxied requests through workhorse.",
		},
		[]string{"code", "method", "route"},
	)

	buildHandler = metrics.NewHandlerFactory(metrics.WithNamespace(namespace), metrics.WithLabels("route"))
)

func instrumentRoute(next http.Handler, _ string, regexpStr string) http.Handler {
	return buildHandler(next, metrics.WithLabelValues(map[string]string{"route": regexpStr}))
}

func instrumentGeoProxyRoute(next http.Handler, _ string, regexpStr string) http.Handler {
	return promhttp.InstrumentHandlerCounter(httpGeoProxiedRequestsTotal.MustCurryWith(map[string]string{"route": regexpStr}), next)
}
