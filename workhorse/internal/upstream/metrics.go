package upstream

import (
	"context"
	"net/http"

	"github.com/prometheus/client_golang/prometheus"
	"github.com/prometheus/client_golang/prometheus/promauto"
	"github.com/prometheus/client_golang/prometheus/promhttp"

	"gitlab.com/gitlab-org/labkit/metrics"

	wm "gitlab.com/gitlab-org/gitlab/workhorse/internal/metrics"
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
		[]string{"code", "method", "route", "route_id", "backend_id"},
	)

	buildHandler = metrics.NewHandlerFactory(
		metrics.WithNamespace(namespace),
		metrics.WithLabels("route", "route_id", "backend_id", wm.KeyFetchedExternalURL))
)

func instrumentRoute(next http.Handler, _ string, metadata routeMetadata) http.Handler {
	return buildHandler(next, metrics.WithLabelValues(
		map[string]string{
			"route":      metadata.regexpStr,
			"route_id":   metadata.routeID,
			"backend_id": string(metadata.backendID)}),
		metrics.WithLabelFromContext(
			wm.KeyFetchedExternalURL,
			func(ctx context.Context) string {
				if tracker, ok := wm.FromContext(ctx); ok {
					val, ok := tracker.GetFlag(wm.KeyFetchedExternalURL)
					if ok {
						return val
					}
				}
				return "false"
			},
		),
	)
}

func instrumentGeoProxyRoute(next http.Handler, _ string, metadata routeMetadata) http.Handler {
	return promhttp.InstrumentHandlerCounter(httpGeoProxiedRequestsTotal.MustCurryWith(map[string]string{
		"route":      metadata.regexpStr,
		"route_id":   metadata.routeID,
		"backend_id": string(metadata.backendID)}),
		next)
}
