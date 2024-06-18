package git

import (
	"net/http"
	"strconv"

	"github.com/prometheus/client_golang/prometheus"
	"github.com/prometheus/client_golang/prometheus/promauto"

	"gitlab.com/gitlab-org/gitlab/workhorse/internal/helper"
)

const (
	directionIn  = "in"
	directionOut = "out"
)

var (
	gitHTTPSessionsActive = promauto.NewGauge(prometheus.GaugeOpts{
		Name: "gitlab_workhorse_git_http_sessions_active",
		Help: "Number of Git HTTP request-response cycles currently being handled by gitlab-workhorse.",
	})

	gitHTTPRequests = promauto.NewCounterVec(
		prometheus.CounterOpts{
			Name: "gitlab_workhorse_git_http_requests",
			Help: "How many Git HTTP requests have been processed by gitlab-workhorse, partitioned by request type and agent.",
		},
		[]string{"method", "code", "service", "agent"},
	)

	gitHTTPBytes = promauto.NewCounterVec(
		prometheus.CounterOpts{
			Name: "gitlab_workhorse_git_http_bytes",
			Help: "How many Git HTTP bytes have been sent by gitlab-workhorse, partitioned by request type, agent and direction.",
		},
		[]string{"method", "code", "service", "agent", "direction"},
	)
)

type HTTPResponseWriter struct {
	helper.CountingResponseWriter
}

func NewHTTPResponseWriter(rw http.ResponseWriter) *HTTPResponseWriter {
	gitHTTPSessionsActive.Inc()
	return &HTTPResponseWriter{
		CountingResponseWriter: helper.NewCountingResponseWriter(rw),
	}
}

func (w *HTTPResponseWriter) Log(r *http.Request, writtenIn int64) {
	service := getService(r)
	agent := getRequestAgent(r)

	gitHTTPSessionsActive.Dec()
	gitHTTPRequests.WithLabelValues(r.Method, strconv.Itoa(w.Status()), service, agent).Inc()
	gitHTTPBytes.WithLabelValues(r.Method, strconv.Itoa(w.Status()), service, agent, directionIn).
		Add(float64(writtenIn))
	gitHTTPBytes.WithLabelValues(r.Method, strconv.Itoa(w.Status()), service, agent, directionOut).
		Add(float64(w.Count()))
}

func getRequestAgent(r *http.Request) string {
	u, _, ok := r.BasicAuth()
	if !ok {
		return "anonymous"
	}

	if u == "gitlab-ci-token" {
		return "gitlab-ci"
	}

	return "logged"
}
