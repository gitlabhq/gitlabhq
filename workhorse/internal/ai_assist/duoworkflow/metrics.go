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
)
