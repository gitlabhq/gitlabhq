package duoworkflow

import (
	"net/http"

	"github.com/prometheus/client_golang/prometheus"
	"github.com/prometheus/client_golang/prometheus/promauto"
)

var (
	// connectionsOpen tracks how many Duo Workflow runners are currently active,
	// labeled by the transport the client used (websocket, http).
	// gitlab_workhorse_http_in_flight_requests is no substitute: it is unlabeled
	// and also counts the HTTP actions that re-enter the upstream router. Memory
	// per connection is only interpretable against this gauge.
	connectionsOpen = promauto.NewGaugeVec(prometheus.GaugeOpts{
		Name: "gitlab_workhorse_duo_workflow_connections_open",
		Help: "Number of Duo Workflow connections currently open, by transport.",
	}, []string{"transport"})

	// sessionsTotal counts all gRPC ExecuteWorkflow streams opened to the Duo
	// Workflow Service.
	sessionsTotal = promauto.NewCounter(prometheus.CounterOpts{
		Name: "gitlab_workhorse_duo_workflow_sessions_total",
		Help: "Total number of Duo Workflow gRPC ExecuteWorkflow streams opened.",
	})

	// sessionErrorsTotal counts gRPC ExecuteWorkflow streams that ended with a
	// non-EOF error (i.e. unexpected failures, not normal workflow completion),
	// broken down by gRPC status code and by what ended the stream.
	//
	// A single gRPC code covers causes that are not equally a failure: an
	// Unavailable arrives both when DWS tears the stream down to acknowledge a
	// stop workhorse asked for, and when the connection to DWS fails outright.
	// teardown_reason separates them; see teardownReason for its values.
	sessionErrorsTotal = promauto.NewCounterVec(prometheus.CounterOpts{
		Name: "gitlab_workhorse_duo_workflow_session_errors_total",
		Help: "Total number of Duo Workflow gRPC sessions that ended with a non-EOF error, by gRPC status code and what ended the stream.",
	}, []string{"grpc_code", "teardown_reason"})

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
	// or other), labeled by HTTP method and error type. HTTP 4xx/5xx responses
	// are not errors at this layer and are counted only in httpActionsTotal.
	httpActionErrorsTotal = promauto.NewCounterVec(prometheus.CounterOpts{
		Name: "gitlab_workhorse_duo_workflow_http_action_errors_total",
		Help: "Total number of Duo Workflow HTTP actions that failed due to a transport-level error, by method and error type.",
	}, []string{"method", "error_type"})

	// actionQueueWaitSeconds measures how long an action waited for a free
	// worker in the run's action pool, labeled by action type. It is only
	// observed when actions run concurrently.
	actionQueueWaitSeconds = promauto.NewHistogramVec(prometheus.HistogramOpts{
		Name:    "gitlab_workhorse_duo_workflow_action_queue_wait_seconds",
		Help:    "Duration in seconds a Duo Workflow action waited for a free worker before it started, by action type.",
		Buckets: prometheus.DefBuckets,
	}, []string{"type"})

	// actionPoolSaturatedTotal counts actions that found every worker in the
	// run's action pool busy, so receiving from Duo Workflow Service paused.
	actionPoolSaturatedTotal = promauto.NewCounter(prometheus.CounterOpts{
		Name: "gitlab_workhorse_duo_workflow_action_pool_saturated_total",
		Help: "Total number of Duo Workflow actions that had to wait because every worker in the run's action pool was busy.",
	})
)

// Label values for the action metrics. The action type says who executes the
// action: Workhorse (http, mcp, self_hosted_tracking) or the client.
const (
	actionTypeHTTP               = "http"
	actionTypeMCP                = "mcp"
	actionTypeSelfHostedTracking = "self_hosted_tracking"
	actionTypeClient             = "client"

	// actionOutcomeOK means the action was answered, or forwarded to the client.
	actionOutcomeOK = "ok"
	// actionOutcomeError means the action was answered with an error, and the
	// run carried on.
	actionOutcomeError = "error"
	// actionOutcomeFatal means handling the action ended the run.
	actionOutcomeFatal = "fatal"
)

// Long enough for a slow MCP tool or a large API response.
var actionDurationBuckets = []float64{0.01, 0.05, 0.1, 0.25, 0.5, 1, 2.5, 5, 10, 30, 60, 120}

var (
	// actionsTotal counts every action received from the Duo Workflow
	// Service, whoever executes it.
	actionsTotal = promauto.NewCounterVec(prometheus.CounterOpts{
		Name: "gitlab_workhorse_duo_workflow_actions_total",
		Help: "Total number of actions received from the Duo Workflow Service, by type and outcome.",
	}, []string{"type", "outcome"})

	// actionDurationSeconds measures each action from its receipt until its
	// response is sent to the Duo Workflow Service, or until it is written to
	// the client.
	actionDurationSeconds = promauto.NewHistogramVec(prometheus.HistogramOpts{
		Name:    "gitlab_workhorse_duo_workflow_action_duration_seconds",
		Help:    "Duration in seconds of handling an action received from the Duo Workflow Service, by type.",
		Buckets: actionDurationBuckets,
	}, []string{"type"})

	// actionsInFlight is the baseline for parallel action execution: today a
	// run handles one action at a time, so this never exceeds the number of
	// open connections.
	actionsInFlight = promauto.NewGaugeVec(prometheus.GaugeOpts{
		Name: "gitlab_workhorse_duo_workflow_actions_in_flight",
		Help: "Number of actions from the Duo Workflow Service currently being handled, by type.",
	}, []string{"type"})

	// mcpCallsTotal counts MCP tool calls by mcpServerLabel. A tool_error is a
	// call the server answered with isError set.
	mcpCallsTotal = promauto.NewCounterVec(prometheus.CounterOpts{
		Name: "gitlab_workhorse_duo_workflow_mcp_calls_total",
		Help: "Total number of MCP tool calls, by server and outcome.",
	}, []string{"server", "outcome"})

	mcpCallDurationSeconds = promauto.NewHistogramVec(prometheus.HistogramOpts{
		Name:    "gitlab_workhorse_duo_workflow_mcp_call_duration_seconds",
		Help:    "Duration in seconds of MCP tool calls, by server.",
		Buckets: actionDurationBuckets,
	}, []string{"server"})

	// mcpInitFailuresTotal counts MCP servers whose tools are missing from a
	// run because connecting or listing tools failed.
	mcpInitFailuresTotal = promauto.NewCounterVec(prometheus.CounterOpts{
		Name: "gitlab_workhorse_duo_workflow_mcp_init_failures_total",
		Help: "Total number of MCP servers that failed to initialize for a run, by server.",
	}, []string{"server"})

	// sessionDurationSeconds measures a run from the start of execution until
	// the runner is closed.
	sessionDurationSeconds = promauto.NewHistogramVec(prometheus.HistogramOpts{
		Name:    "gitlab_workhorse_duo_workflow_session_duration_seconds",
		Help:    "Duration in seconds of Duo Workflow runs, by transport and what ended the stream.",
		Buckets: []float64{1, 5, 15, 30, 60, 120, 300, 600, 1800, 3600, 7200, 14400},
	}, []string{"transport", "teardown_reason"})

	// sessionSetupDurationSeconds measures the setup that runs before a run
	// can start: opening the gRPC stream and initializing the MCP servers.
	sessionSetupDurationSeconds = promauto.NewHistogramVec(prometheus.HistogramOpts{
		Name:    "gitlab_workhorse_duo_workflow_session_setup_duration_seconds",
		Help:    "Duration in seconds of setting up a Duo Workflow run, by stage.",
		Buckets: []float64{0.01, 0.025, 0.05, 0.1, 0.25, 0.5, 1, 2.5, 5, 10, 30},
	}, []string{"stage"})

	lockAcquireTotal = promauto.NewCounterVec(prometheus.CounterOpts{
		Name: "gitlab_workhorse_duo_workflow_lock_acquire_total",
		Help: "Total number of attempts to acquire a workflow lock, by outcome.",
	}, []string{"outcome"})

	// lockReleaseFailuresTotal counts locks left in Redis until they expire.
	// A lock that already expired is not a failure.
	lockReleaseFailuresTotal = promauto.NewCounter(prometheus.CounterOpts{
		Name: "gitlab_workhorse_duo_workflow_lock_release_failures_total",
		Help: "Total number of workflow locks that could not be released.",
	})

	stopRequestsTotal = promauto.NewCounterVec(prometheus.CounterOpts{
		Name: "gitlab_workhorse_duo_workflow_stop_requests_total",
		Help: "Total number of StopWorkflowRequests sent to the Duo Workflow Service, by outcome.",
	}, []string{"outcome"})
)

const (
	setupStageGRPC = "grpc"
	setupStageMCP  = "mcp"

	mcpOutcomeOK        = "ok"
	mcpOutcomeToolError = "tool_error"
	mcpOutcomeError     = "error"

	lockOutcomeAcquired       = "acquired"
	lockOutcomeTaken          = "taken"
	lockOutcomeTransientError = "transient_error"

	stopOutcomeAcked      = "acked"
	stopOutcomeTimeout    = "timeout"
	stopOutcomeSendFailed = "send_failed"

	httpMethodOther = "other"

	// mcpServerCatalog stands for every MCP server added through the AI
	// Catalog, whose names users choose.
	mcpServerCatalog = "catalog"
)

// mcpServerLabel bounds the server label to the servers Rails configures
// itself. The server name stays in the logs.
func mcpServerLabel(serverName string) string {
	switch serverName {
	case gitlabServerName, orbitServerName, slackServerName:
		return serverName
	default:
		return mcpServerCatalog
	}
}

// httpMethodLabel bounds the method label: DWS can send any valid method token.
func httpMethodLabel(method string) string {
	switch method {
	case http.MethodGet, http.MethodHead, http.MethodPost, http.MethodPut,
		http.MethodPatch, http.MethodDelete, http.MethodOptions:
		return method
	default:
		return httpMethodOther
	}
}
