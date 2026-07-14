package duoworkflow

import (
	"github.com/prometheus/client_golang/prometheus"
	"github.com/prometheus/client_golang/prometheus/promauto"
)

var (
	// connectionsTotal counts all inbound requests that reach the handler,
	// including those that fail to upgrade to WebSocket.
	connectionsTotal = promauto.NewCounter(prometheus.CounterOpts{
		Name: "gitlab_workhorse_duo_workflow_connections_total",
		Help: "Total number of Duo Workflow connection attempts (including upgrade failures).",
	})

	// connectionErrorsTotal counts WebSocket connections that failed at any stage:
	// WebSocket upgrade, runner initialisation, or runner execution,
	// labeled by error type (quota_exceeded, locked, other).
	connectionErrorsTotal = promauto.NewCounterVec(prometheus.CounterOpts{
		Name: "gitlab_workhorse_duo_workflow_connection_errors_total",
		Help: "Total number of Duo Workflow WebSocket connections that failed (upgrade, initialisation, or execution), by error type.",
	}, []string{"error_type"})

	// sessionsTotal counts all gRPC ExecuteWorkflow streams opened to the Duo
	// Workflow Service.
	sessionsTotal = promauto.NewCounter(prometheus.CounterOpts{
		Name: "gitlab_workhorse_duo_workflow_sessions_total",
		Help: "Total number of Duo Workflow gRPC ExecuteWorkflow streams opened.",
	})

	// sessionErrorsTotal counts gRPC ExecuteWorkflow streams that ended with a
	// non-EOF error (i.e. unexpected failures, not normal workflow completion),
	// broken down by gRPC status code.
	sessionErrorsTotal = promauto.NewCounterVec(prometheus.CounterOpts{
		Name: "gitlab_workhorse_duo_workflow_session_errors_total",
		Help: "Total number of Duo Workflow gRPC sessions that ended with a non-EOF error, by gRPC status code.",
	}, []string{"grpc_code"})

	// httpActionsTotal counts HTTP actions executed on behalf of the Duo
	// Workflow Service, labeled by HTTP method and response status code.
	// Status code is "0" when the request could not be completed at all
	// (e.g. timeout, aborted, size limit exceeded).
	httpActionsTotal = promauto.NewCounterVec(prometheus.CounterOpts{
		Name: "gitlab_workhorse_duo_workflow_http_actions_total",
		Help: "Total number of HTTP actions executed on behalf of the Duo Workflow Service, by method and status code.",
	}, []string{"method", "status_code"})

	// httpActionDurationSeconds measures the latency of each HTTP action
	// executed on behalf of the Duo Workflow Service, labeled by HTTP method.
	httpActionDurationSeconds = promauto.NewHistogramVec(prometheus.HistogramOpts{
		Name:    "gitlab_workhorse_duo_workflow_http_action_duration_seconds",
		Help:    "Duration in seconds of HTTP actions executed on behalf of the Duo Workflow Service, by method.",
		Buckets: prometheus.DefBuckets,
	}, []string{"method"})

	// httpActionErrorsTotal counts HTTP actions that could not be completed
	// due to a transport-level error (timeout, aborted, size limit exceeded,
	// or other), labeled by error type. HTTP 4xx/5xx responses are not errors
	// at this layer and are counted only in httpActionsTotal.
	httpActionErrorsTotal = promauto.NewCounterVec(prometheus.CounterOpts{
		Name: "gitlab_workhorse_duo_workflow_http_action_errors_total",
		Help: "Total number of Duo Workflow HTTP actions that failed due to a transport-level error, by error type.",
	}, []string{"error_type"})
)
