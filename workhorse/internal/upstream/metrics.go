package upstream

import (
	"net/http"

	"github.com/prometheus/client_golang/prometheus"
	"github.com/prometheus/client_golang/prometheus/promauto"
	"github.com/prometheus/client_golang/prometheus/promhttp"
)

const (
	namespace     = "gitlab_workhorse"
	httpSubsystem = "http"
)

func secondsDurationBuckets() []float64 {
	return []float64{
		0.005, /* 5ms */
		0.025, /* 25ms */
		0.1,   /* 100ms */
		0.5,   /* 500ms */
		1.0,   /* 1s */
		10.0,  /* 10s */
		30.0,  /* 30s */
		60.0,  /* 1m */
		300.0, /* 10m */
	}
}

func byteSizeBuckets() []float64 {
	return []float64{
		10,
		64,
		256,
		1024,             /* 1kB */
		64 * 1024,        /* 64kB */
		256 * 1024,       /* 256kB */
		1024 * 1024,      /* 1mB */
		64 * 1024 * 1024, /* 64mB */
	}
}

var (
	httpInFlightRequests = promauto.NewGauge(prometheus.GaugeOpts{
		Namespace: namespace,
		Subsystem: httpSubsystem,
		Name:      "in_flight_requests",
		Help:      "A gauge of requests currently being served by workhorse.",
	})

	httpRequestsTotal = promauto.NewCounterVec(
		prometheus.CounterOpts{
			Namespace: namespace,
			Subsystem: httpSubsystem,
			Name:      "requests_total",
			Help:      "A counter for requests to workhorse.",
		},
		[]string{"code", "method", "route"},
	)

	httpRequestDurationSeconds = promauto.NewHistogramVec(
		prometheus.HistogramOpts{
			Namespace: namespace,
			Subsystem: httpSubsystem,
			Name:      "request_duration_seconds",
			Help:      "A histogram of latencies for requests to workhorse.",
			Buckets:   secondsDurationBuckets(),
		},
		[]string{"code", "method", "route"},
	)

	httpRequestSizeBytes = promauto.NewHistogramVec(
		prometheus.HistogramOpts{
			Namespace: namespace,
			Subsystem: httpSubsystem,
			Name:      "request_size_bytes",
			Help:      "A histogram of sizes of requests to workhorse.",
			Buckets:   byteSizeBuckets(),
		},
		[]string{"code", "method", "route"},
	)

	httpResponseSizeBytes = promauto.NewHistogramVec(
		prometheus.HistogramOpts{
			Namespace: namespace,
			Subsystem: httpSubsystem,
			Name:      "response_size_bytes",
			Help:      "A histogram of response sizes for requests to workhorse.",
			Buckets:   byteSizeBuckets(),
		},
		[]string{"code", "method", "route"},
	)

	httpTimeToWriteHeaderSeconds = promauto.NewHistogramVec(
		prometheus.HistogramOpts{
			Namespace: namespace,
			Subsystem: httpSubsystem,
			Name:      "time_to_write_header_seconds",
			Help:      "A histogram of request durations until the response headers are written.",
			Buckets:   secondsDurationBuckets(),
		},
		[]string{"code", "method", "route"},
	)
)

func instrumentRoute(next http.Handler, method string, regexpStr string) http.Handler {
	handler := next

	handler = promhttp.InstrumentHandlerCounter(httpRequestsTotal.MustCurryWith(map[string]string{"route": regexpStr}), handler)
	handler = promhttp.InstrumentHandlerDuration(httpRequestDurationSeconds.MustCurryWith(map[string]string{"route": regexpStr}), handler)
	handler = promhttp.InstrumentHandlerInFlight(httpInFlightRequests, handler)
	handler = promhttp.InstrumentHandlerRequestSize(httpRequestSizeBytes.MustCurryWith(map[string]string{"route": regexpStr}), handler)
	handler = promhttp.InstrumentHandlerResponseSize(httpResponseSizeBytes.MustCurryWith(map[string]string{"route": regexpStr}), handler)
	handler = promhttp.InstrumentHandlerTimeToWriteHeader(httpTimeToWriteHeaderSeconds.MustCurryWith(map[string]string{"route": regexpStr}), handler)

	return handler
}
