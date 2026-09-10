package duoworkflow

import (
	"context"
	"errors"
	"fmt"
	"net/http"
	"sync"
	"time"

	redis "github.com/redis/go-redis/v9"

	"gitlab.com/gitlab-org/gitlab/workhorse/internal/api"
	"gitlab.com/gitlab-org/gitlab/workhorse/internal/helper/fail"
	"gitlab.com/gitlab-org/gitlab/workhorse/internal/helper/shutdown"
	"gitlab.com/gitlab-org/gitlab/workhorse/internal/log"
	"gitlab.com/gitlab-org/gitlab/workhorse/internal/origincheck"

	"github.com/gorilla/websocket"
)

// Handler manages Duo Workflow WebSocket connections and provides graceful shutdown
// for active workflow runners. It tracks all active runners to ensure they can be
// properly terminated during server shutdown.
type Handler struct {
	rails                 *api.API
	rdb                   *redis.Client
	backend               http.Handler
	relativeURLRoot       string
	upgrader              websocket.Upgrader
	runners               sync.Map // map[*runner]bool
	stopWorkflowTimeout   time.Duration
	trustedForwardedHosts []string
}

// NewHandler creates a new Handler for managing Duo Workflow WebSocket connections.
// The handler maintains a registry of active runners to support graceful shutdown
// of WebSocket connections during server termination.
//
// relativeURLRoot is GitLab's URL prefix (e.g. "/gitlab/"), empty at the domain
// root. It is forwarded to the action handler so DWS action paths resolve
// against the correct prefix when re-entering the upstream router.
func NewHandler(rails *api.API, rdb *redis.Client, backend http.Handler, relativeURLRoot string, trustedForwardedHosts ...string) *Handler {
	return &Handler{
		rails:                 rails,
		backend:               backend,
		relativeURLRoot:       relativeURLRoot,
		rdb:                   rdb,
		upgrader:              websocket.Upgrader{},
		trustedForwardedHosts: trustedForwardedHosts,
	}
}

// Shutdown gracefully terminates all active workflow runners within the provided context timeout.
// It collects all active runners and initiates shutdown concurrently for all of them.
func (h *Handler) Shutdown(ctx context.Context) error {
	var runners []shutdown.GracefulCloser

	h.runners.Range(func(key, _ interface{}) bool {
		if r, ok := key.(*runner); ok {
			runners = append(runners, r)
		}
		return true
	})

	return shutdown.All(ctx, runners...)
}

const (
	errorTypeQuotaExceeded = "quota_exceeded"
	errorTypeLocked        = "locked"
	errorTypeOther         = "other"
)

// The transport the client used to reach the handler. Both are reported under
// the same metrics, because the flow they run is the same and the difference
// that matters is who executes the actions.
const (
	transportWebSocket = "websocket"
	transportHTTP      = "http"
)

// Stages at which a connection can fail with errorTypeOther. Logged so the
// otherwise opaque "other" bucket can be traced back to a specific stage.
const (
	errorStageUpgrade        = "websocket_upgrade"
	errorStageRequestBody    = "request_body"
	errorStageInitialization = "runner_initialization"
	errorStageExecution      = "runner_execution"
)

// countOtherConnectionError increments connectionErrorsTotal{error_type=other}
// and logs the stage and underlying error, which the metric label alone loses.
func countOtherConnectionError(r *http.Request, transport string, stage string, err error) {
	connectionErrorsTotal.WithLabelValues(transport, errorTypeOther).Inc()
	log.WithRequest(r).WithError(err).WithFields(log.Fields{
		"transport":   transport,
		"error_stage": stage,
		"error_type":  errorTypeOther,
	}).Error("duo workflow connection failed")
}

// Build returns an HTTP handler that processes Duo Workflow WebSocket connections.
// The handler performs pre-authorization checks, upgrades the connection to WebSocket,
// and manages the lifecycle of the workflow runner including registration and cleanup.
func (h *Handler) Build() http.Handler {
	return h.rails.PreAuthorizeHandler(func(w http.ResponseWriter, r *http.Request, a *api.Response) {
		connectionsTotal.WithLabelValues(transportWebSocket).Inc()

		upgrader := h.upgrader
		if len(h.trustedForwardedHosts) > 0 {
			upgrader.CheckOrigin = origincheck.ByForwardedHost(h.trustedForwardedHosts)
		}

		conn, err := upgrader.Upgrade(w, r, nil)
		if err != nil {
			countOtherConnectionError(r, transportWebSocket, errorStageUpgrade, err)
			fail.Request(w, r, fmt.Errorf("failed to upgrade: %v", err))
			return
		}

		h.handleWebSocketConnection(w, r, conn, a.DuoWorkflow)
	}, "")
}

func (h *Handler) handleWebSocketConnection(w http.ResponseWriter, r *http.Request, conn *websocket.Conn, duoWorkflowConfig *api.DuoWorkflow) {
	runner, err := h.createRunner(newWsManager(conn), duoWorkflowConfig, r)
	if err != nil {
		countOtherConnectionError(r, transportWebSocket, errorStageInitialization, err)
		h.handleInitializationError(w, r, conn, err)
		return
	}

	h.registerAndExecuteRunner(r, transportWebSocket, runner, func(err error) {
		h.handleWebSocketExecutionError(r, conn, err)
	})
}

func (h *Handler) createRunner(client clientTransport, duoWorkflowConfig *api.DuoWorkflow, r *http.Request) (*runner, error) {
	runner, err := newRunner(client, h.rails, h.backend, h.relativeURLRoot, r, duoWorkflowConfig, h.rdb)
	if err != nil {
		return nil, err
	}
	runner.stopWorkflowTimeout = h.stopWorkflowTimeout
	return runner, nil
}

func (h *Handler) handleInitializationError(w http.ResponseWriter, r *http.Request, conn *websocket.Conn, err error) {
	fail.Request(w, r, fmt.Errorf("failed to initialize agent platform client: %v", err))
	if closeErr := conn.Close(); closeErr != nil {
		log.WithRequest(r).WithError(closeErr).Error("failed to close connection")
	}
}

// registerAndExecuteRunner tracks the runner for the duration of the workflow
// so that a server shutdown can stop it gracefully.
//
// reportError is called with a non-nil execution error while the connection is
// still open, before the runner is closed, so that a transport can still tell
// its client what went wrong.
func (h *Handler) registerAndExecuteRunner(r *http.Request, transport string, runner *runner, reportError func(error)) {
	openConnections := connectionsOpen.WithLabelValues(transport)

	h.runners.Store(runner, true)
	openConnections.Inc()
	defer func() {
		defer openConnections.Dec()
		h.runners.Delete(runner)
		_ = runner.Close()
	}()

	start := time.Now()
	if err := runner.Execute(r.Context()); err != nil {
		log.WithRequest(r).WithError(err).WithFields(log.Fields{
			"duration_ms": time.Since(start).Milliseconds(),
		}).Error("error executing workflow")

		reportError(err)
	}
}

func (h *Handler) handleWebSocketExecutionError(r *http.Request, conn *websocket.Conn, err error) {
	switch {
	case errors.Is(err, errFailedToAcquireLockError):
		// We provide the client with specific error details
		// for this case so it can tell the user about the
		// conflicting flow
		connectionErrorsTotal.WithLabelValues(transportWebSocket, errorTypeLocked).Inc()
		h.sendCloseMessage(r, conn, websocket.CloseTryAgainLater, "Failed to acquire lock on workflow")
	case errors.Is(err, errUsageQuotaExceededError):
		// We close the connection with the specific error
		// so client can process and inform user about the lack
		// of credits
		connectionErrorsTotal.WithLabelValues(transportWebSocket, errorTypeQuotaExceeded).Inc()
		h.sendCloseMessage(r, conn, websocket.ClosePolicyViolation, "Insufficient credits: quota exceeded")
	default:
		countOtherConnectionError(r, transportWebSocket, errorStageExecution, err)
	}
}

func (h *Handler) sendCloseMessage(r *http.Request, conn *websocket.Conn, code int, reason string) {
	closeMessage := websocket.FormatCloseMessage(code, reason)
	if err := conn.WriteMessage(websocket.CloseMessage, closeMessage); err != nil {
		log.WithRequest(r).WithError(err).Error()
	}
}
