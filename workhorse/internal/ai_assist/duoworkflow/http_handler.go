package duoworkflow

import (
	"errors"
	"fmt"
	"io"
	"net/http"

	pb "gitlab.com/gitlab-org/modelops/applied-ml/code-suggestions/ai-assist/clients/gopb/contract"

	"gitlab.com/gitlab-org/gitlab/workhorse/internal/api"
	"gitlab.com/gitlab-org/gitlab/workhorse/internal/helper/fail"
	"gitlab.com/gitlab-org/gitlab/workhorse/internal/log"
)

// startRequestBodyLimit caps the request body. A larger StartWorkflowRequest
// could not be sent to Duo Workflow Service anyway, since MaxMessageSize is
// the gRPC send limit.
const startRequestBodyLimit = MaxMessageSize

// BuildHTTP returns the handler for server-side flow execution: workhorse
// starts the workflow itself and streams the actions Duo Workflow Service
// sends back to the caller, instead of proxying between a client and Duo
// Workflow Service as Build does.
//
// It is for callers that cannot execute actions of their own, such as a chat
// turn arriving from an integration. The request body is the
// StartWorkflowRequest to start the flow with, and the response is the actions
// as newline-delimited JSON over a single chunked response. See
// ndjsonTransport.
func (h *Handler) BuildHTTP() http.Handler {
	return h.rails.PreAuthorizeHandler(func(w http.ResponseWriter, r *http.Request, a *api.Response) {
		connectionsTotal.WithLabelValues(transportHTTP).Inc()

		h.handleHTTPConnection(w, r, a.DuoWorkflow)
	}, "")
}

func (h *Handler) handleHTTPConnection(w http.ResponseWriter, r *http.Request, duoWorkflowConfig *api.DuoWorkflow) {
	if err := validateHTTPConfig(duoWorkflowConfig); err != nil {
		countOtherConnectionError(r, transportHTTP, errorStageInitialization, err)
		fail.Request(w, r, err)
		return
	}

	startEvent, err := decodeStartEvent(r, duoWorkflowConfig.WorkflowID)
	if err != nil {
		countOtherConnectionError(r, transportHTTP, errorStageRequestBody, err)
		fail.Request(w, r, err, fail.WithStatus(http.StatusBadRequest))
		return
	}

	transport := newNdjsonTransport(w, r, startEvent)

	runner, err := h.createRunner(transport, duoWorkflowConfig, r)
	if err != nil {
		countOtherConnectionError(r, transportHTTP, errorStageInitialization, err)
		fail.Request(w, r, fmt.Errorf("failed to initialize agent platform client: %v", err), fail.WithStatus(http.StatusBadGateway))
		return
	}

	// Reported after the runner is closed rather than from the callback: unlike
	// a WebSocket close frame, nothing here needs the connection to still be
	// open, and Duo Workflow Service may reject the request without the runner
	// failing at all.
	var execErr error
	h.registerAndExecuteRunner(r, transportHTTP, runner, func(err error) { execErr = err })

	h.reportHTTPOutcome(w, r, transport, execErr)
}

// reportHTTPOutcome turns the runner's outcome into a response. Until the first
// action or keepalive is written the response is still uncommitted, so a
// failure can be reported as a status code; afterwards the caller only sees the
// stream end, and tells a stopped flow apart from a finished one through the
// workflow's status.
func (h *Handler) reportHTTPOutcome(w http.ResponseWriter, r *http.Request, transport *ndjsonTransport, execErr error) {
	errorType, status, message := classifyHTTPOutcome(transport, execErr)

	if errorType == "" {
		return
	}

	if errorType == errorTypeOther {
		countOtherConnectionError(r, transportHTTP, errorStageExecution, execErr)
	} else {
		connectionErrorsTotal.WithLabelValues(transportHTTP, errorType).Inc()
	}

	if transport.HeaderWritten() {
		log.WithRequest(r).WithFields(log.Fields{
			"error_type": errorType,
		}).Error("duo workflow http: workflow failed after the response was committed")
		return
	}

	fail.Request(w, r, errors.New(message), fail.WithStatus(status))
}

// classifyHTTPOutcome maps a runner outcome to an error type, HTTP status and
// message, or returns an empty error type when the flow ended cleanly.
func classifyHTTPOutcome(transport *ndjsonTransport, execErr error) (errorType string, status int, message string) {
	switch {
	case errors.Is(execErr, errClientGone):
		// The caller hung up. There is nobody left to report to, and this is a
		// normal way for a run to end, so it is not counted as a failure.
		return "", 0, ""
	case errors.Is(execErr, errFailedToAcquireLockError):
		// The workflow is already running somewhere else. Conflict rather than
		// 429, because retrying will not help until the other run ends.
		return errorTypeLocked, http.StatusConflict, "failed to acquire lock on workflow"
	case errors.Is(execErr, errUsageQuotaExceededError):
		return errorTypeQuotaExceeded, http.StatusForbidden, "insufficient credits: quota exceeded"
	case execErr != nil:
		return errorTypeOther, http.StatusInternalServerError, "failed to execute workflow"
	}

	// Duo Workflow Service rejected the request itself, which runner reports
	// through the transport rather than as an execution error because the
	// WebSocket path forwards it to the client as a close frame.
	if reason := transport.InvalidRequestReason(); reason != "" {
		return errorTypeOther, http.StatusBadRequest, fmt.Sprintf("invalid workflow request: %s", reason)
	}

	return "", 0, ""
}

// validateHTTPConfig checks the parts of the pre-authorization response this
// endpoint cannot run without. A failure here is a misconfiguration between
// Rails and workhorse, not a problem with the caller's request.
func validateHTTPConfig(cfg *api.DuoWorkflow) error {
	if cfg == nil || cfg.Service == nil {
		return errors.New("agent platform service configuration is missing")
	}

	// Workhorse starts the workflow itself, so the ID has to come from Rails,
	// which is the only party that authorized it.
	if cfg.WorkflowID == "" {
		return errors.New("no workflow ID was authorized for this request")
	}

	return nil
}

// decodeStartEvent builds the StartWorkflowRequest to start the flow with from
// the request body, overriding the fields workhorse owns.
func decodeStartEvent(r *http.Request, workflowID string) (*pb.ClientEvent, error) {
	body, err := io.ReadAll(http.MaxBytesReader(nil, r.Body, startRequestBodyLimit))
	if err != nil {
		return nil, fmt.Errorf("failed to read request body: %w", err)
	}

	startReq := &pb.StartWorkflowRequest{}
	if err := unmarshaler.Unmarshal(body, startReq); err != nil {
		return nil, fmt.Errorf("failed to decode start workflow request: %w", err)
	}

	// The caller may name the workflow it thinks it is starting, but Rails
	// decides which one it is allowed to start. Reject a mismatch rather than
	// silently running a different workflow than the caller asked for.
	if startReq.WorkflowID != "" && startReq.WorkflowID != workflowID {
		return nil, fmt.Errorf("workflow ID %q does not match the authorized workflow", startReq.WorkflowID)
	}
	startReq.WorkflowID = workflowID

	// Client capabilities describe what the executor can do. Workhorse is not
	// an executor here, so it advertises none and lets Duo Workflow Service
	// fall back to its baseline behavior. runner still appends the server
	// capabilities Rails reported.
	startReq.ClientCapabilities = nil

	// The MCP tools available to the flow come from the configuration Rails
	// returned, which runner appends. A caller cannot add to them.
	startReq.McpTools = nil
	startReq.PreapprovedTools = nil

	return &pb.ClientEvent{
		Response: &pb.ClientEvent_StartRequest{StartRequest: startReq},
	}, nil
}
