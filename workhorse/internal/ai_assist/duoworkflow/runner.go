package duoworkflow

import (
	"context"
	"errors"
	"fmt"
	"io"
	"net/http"
	"slices"
	"time"

	redsync "github.com/go-redsync/redsync/v4"
	redis "github.com/redis/go-redis/v9"
	pb "gitlab.com/gitlab-org/modelops/applied-ml/code-suggestions/ai-assist/clients/gopb/contract"

	"gitlab.com/gitlab-org/gitlab/workhorse/internal/api"
	"gitlab.com/gitlab-org/gitlab/workhorse/internal/log"

	"github.com/gorilla/websocket"
	"google.golang.org/protobuf/encoding/protojson"
)

const wsWriteDeadline = 60 * time.Second
const wsCloseTimeout = 5 * time.Second
const wsStopWorkflowTimeout = 10 * time.Second

type capability string

const (
	// Client capabilities
	capabilityIncrementalStreaming capability = "incremental_streaming"
	capabilityShellCommand         capability = "shell_command"
	capabilityReadFileChunked      capability = "read_file_chunked"

	// Server capabilities
	capabilityAdvancedSearch   capability = "advanced_search"
	capabilityToolCallApproval capability = "tool_call_approval"
)

// ClientCapabilities is how gitlab-lsp -> workhorse -> Duo Workflow Service communicates
// capabilities that can be used by Duo Workflow Service without breaking
// backwards compatibility. We intersect the capabilities of all parties and
// then new behavior can only depend on that behavior if it makes it all the
// way through. Whenever you add to this list you must also update the gitlab-lsp and
// either updates the constant in ee/app/assets/javascripts/ai/constants.js or
// conditionally add to the capabilities in passed to buildStartRequest in
// ee/app/assets/javascripts/ai/duo_agentic_chat/components/duo_agentic_chat.vue.
var ClientCapabilities = []capability{
	capabilityIncrementalStreaming,
	capabilityShellCommand,
	capabilityReadFileChunked,
}

// ServerCapabilities defines the list of allowed server capabilities that
// can be communicated to Duo Workflow Service. This whitelist ensures only
// explicitly approved capabilities are sent.
//
// To add a new server capability:
// 1. Add a constant above (e.g., capabilityNewFeature capability = "new_feature")
// 2. Add it to this ServerCapabilities list
// 3. Update compute_server_capabilities in ee/lib/api/ai/duo_workflows/workflows.rb
var ServerCapabilities = []capability{
	capabilityAdvancedSearch,
	capabilityToolCallApproval,
}

var errFailedToAcquireLockError = errors.New("handleWebSocketMessages: failed to acquire lock")

var normalClosureErrCodes = []int{websocket.CloseGoingAway, websocket.CloseNormalClosure}

var marshaler = protojson.MarshalOptions{
	UseProtoNames:   true,
	EmitUnpopulated: true,
}

var unmarshaler = protojson.UnmarshalOptions{
	DiscardUnknown: true,
}

type websocketConn interface {
	ReadMessage() (int, []byte, error)
	WriteMessage(int, []byte) error
	WriteControl(int, []byte, time.Time) error
	SetReadDeadline(time.Time) error
	SetWriteDeadline(time.Time) error
	Close() error
}

type workflowStream interface {
	Send(*pb.ClientEvent) error
	Recv() (*pb.Action, error)
	CloseSend() error
}

type selfHostedWorkflowStream interface {
	Send(*pb.TrackSelfHostedClientEvent) error
	Recv() (*pb.TrackSelfHostedAction, error)
	CloseSend() error
}

type runner struct {
	rails              *api.API
	backend            http.Handler
	token              string
	originalReq        *http.Request
	marshalBuf         []byte
	conn               websocketConn
	lockManager        *workflowLockManager
	workflowID         string
	mutex              *redsync.Mutex
	lockFlow           bool
	serverCapabilities []string
	streamManager      *streamManager
	mcpManager         mcpManager
	workflowDefinition string
}

func newRunner(conn websocketConn, rails *api.API, backend http.Handler, r *http.Request, cfg *api.DuoWorkflow, rdb *redis.Client) (*runner, error) {
	if cfg.Service == nil {
		return nil, fmt.Errorf("failed to initialize client: Service configuration is nil")
	}

	lockFlow := cfg.LockConcurrentFlow
	if lockFlow && rdb == nil {
		log.WithRequest(r).Info("Workflow locking will be skipped as redis is not configured")
		lockFlow = false
	}

	streamManager, err := newStreamManager(r, cfg)
	if err != nil {
		return nil, fmt.Errorf("failed to initialize stream manager: %v", err)
	}

	mcpManager, err := newMcpManager(rails, r, cfg.McpServers)
	if err != nil {
		// Log the error while the feature is in development
		log.WithRequest(r).WithError(err).Info("failed to initialize MCP server(s)")
	}

	return &runner{
		rails:              rails,
		backend:            backend,
		token:              cfg.Service.Headers["x-gitlab-oauth-token"],
		originalReq:        r,
		marshalBuf:         make([]byte, ActionResponseBodyLimit),
		conn:               conn,
		lockManager:        newWorkflowLockManager(rdb),
		lockFlow:           lockFlow,
		serverCapabilities: cfg.ServerCapabilities,
		streamManager:      streamManager,
		mcpManager:         mcpManager,
	}, nil
}

func (r *runner) Execute(ctx context.Context) error {
	errCh := make(chan error, 2)

	go r.handleWebSocketMessages(errCh)
	go r.handleAgentMessages(ctx, errCh)

	// Unfortunately the lock is acquired in handleWebSocketMessage.  This is
	// because the workflowID is not known until after we see the startReq. But
	// we need to keep it as long as either of these connections is running. So
	// we release it here instead.
	defer func() {
		if r.lockFlow {
			log.WithRequest(r.originalReq).Info("Releasing lock for workflow")
			r.lockManager.releaseLock(ctx, r.mutex, r.workflowID, r.workflowDefinition)
		}
	}()

	return <-errCh
}

func (r *runner) handleWebSocketMessages(errCh chan<- error) {
	for {
		_, message, err := r.conn.ReadMessage()
		if err != nil {
			if e, ok := err.(*websocket.CloseError); ok && slices.Contains(normalClosureErrCodes, e.Code) {
				reason := fmt.Sprintf("WORKHORSE_WEBSOCKET_CLOSE_%d", e.Code)
				stopErr := r.stopWorkflow(reason, err)
				errCh <- fmt.Errorf("handleWebSocketMessages: %v", stopErr)
				return
			}

			errCh <- fmt.Errorf("handleWebSocketMessages: failed to read a WS message: %v", err)
			return
		}

		if err := r.handleWebSocketMessage(message); err != nil {
			errCh <- err
			return
		}
	}
}

func (r *runner) handleAgentMessages(ctx context.Context, errCh chan<- error) {
	for {
		action, err := r.streamManager.Recv()
		if err != nil {
			if err == io.EOF {
				log.WithRequest(r.originalReq).Info("handleAgentMessages: EOF, expected when workflow ends")
				errCh <- nil // Expected error when a workflow ends
			} else {
				errCh <- fmt.Errorf("handleAgentMessages: %w", err)
			}
			return
		}

		if err := r.handleAgentAction(ctx, action); err != nil {
			errCh <- err
			return
		}
	}
}

func (r *runner) logClose(name string, err error) error {
	if err != nil {
		log.WithRequest(r.originalReq).WithFields(log.Fields{
			"connection_type": name,
		}).WithError(err).Error("failed to close")
	} else {
		log.WithRequest(r.originalReq).WithFields(log.Fields{
			"connection_type": name,
		}).Info("closed")
	}
	return err
}

func (r *runner) Close() error {
	streamManagerCloseErr := r.logClose("stream manager", r.streamManager.Close())
	wsCloseErr := r.logClose("websocket connection", r.closeWebSocketConnection())
	mcpManagerCloseErr := r.logClose("mcp manager", r.mcpManager.Close())

	return errors.Join(streamManagerCloseErr, wsCloseErr, mcpManagerCloseErr)
}

func (r *runner) closeWebSocketConnection() error {
	deadline := time.Now().Add(wsCloseTimeout)
	if err := r.conn.WriteControl(websocket.CloseMessage, websocket.FormatCloseMessage(websocket.CloseNormalClosure, ""), deadline); err != nil {
		// If we can't send the close message, just close the connection
		closeErr := r.conn.Close()
		if closeErr != nil {
			return fmt.Errorf("failed to send close message and failed to close connection: %w", closeErr)
		}
		return fmt.Errorf("failed to send close message: %w", err)
	}

	if err := r.conn.SetReadDeadline(deadline); err != nil {
		closeErr := r.conn.Close()
		if closeErr != nil {
			return fmt.Errorf("failed to set read deadline and failed to close connection: %w", closeErr)
		}
		return fmt.Errorf("failed to set read deadline: %w", err)
	}

	if err := r.conn.Close(); err != nil {
		return fmt.Errorf("failed to close connection: %w", err)
	}

	return nil
}

func (r *runner) handleWebSocketMessage(message []byte) error {
	response := &pb.ClientEvent{}
	if err := unmarshaler.Unmarshal(message, response); err != nil {
		return fmt.Errorf("handleWebSocketMessage: failed to unmarshal a WS message: %v", err)
	}

	if startReq := response.GetStartRequest(); startReq != nil {
		// Acquire distributed lock when workflow starts
		if r.lockFlow {
			if err := r.acquireWorkflowLock(startReq); err != nil {
				return err
			}
		}

		startReq.McpTools = append(startReq.McpTools, r.mcpManager.Tools()...)
		startReq.PreapprovedTools = append(startReq.PreapprovedTools, r.mcpManager.PreApprovedTools()...)
		startReq.ClientCapabilities = append(
			intersectClientCapabilities(startReq.ClientCapabilities),
			intersectServerCapabilities(r.serverCapabilities)...,
		)
		log.WithRequest(r.originalReq).WithFields(log.Fields{
			"client_capabilities": startReq.ClientCapabilities,
		}).Info("Sending startRequest")
	}

	if err := r.streamManager.Send(response); err != nil {
		if err == io.EOF {
			// ignore EOF to let Recv() fail and return a meaningful message
			return nil
		}

		return fmt.Errorf("handleWebSocketMessage: failed to write a gRPC message: %v", err)
	}

	return nil
}

// intersectClientCapabilities returns the intersection of what gitlab-lsp passed in and what workhorse
// supports.
func intersectClientCapabilities(fromClient []string) []string {
	result := []string{}

	for _, cap := range ClientCapabilities {
		if slices.Contains(fromClient, string(cap)) {
			result = append(result, string(cap))
		}
	}

	return result
}

// intersectServerCapabilities returns the intersection of what is passed from server and what workhorse
// supports.
func intersectServerCapabilities(fromServer []string) []string {
	result := []string{}

	for _, cap := range ServerCapabilities {
		if slices.Contains(fromServer, string(cap)) {
			result = append(result, string(cap))
		}
	}

	return result
}

func (r *runner) acquireWorkflowLock(startReq *pb.StartWorkflowRequest) error {
	r.workflowID = startReq.WorkflowID
	r.workflowDefinition = startReq.WorkflowDefinition

	if r.workflowID == "" {
		log.WithRequest(r.originalReq).Error("No workflow ID provided in StartWorkflowRequest")
		return fmt.Errorf("handleWebSocketMessage: no workflow ID provided in StartWorkflowRequest")
	}

	mutex, err := r.lockManager.acquireLock(r.originalReq.Context(), r.workflowID, r.workflowDefinition)
	if err != nil && err != errLockIsUnavailable {
		return errFailedToAcquireLockError
	}

	r.mutex = mutex
	return nil
}

func (r *runner) handleAgentAction(ctx context.Context, action *pb.Action) error {
	switch action.Action.(type) {
	case *pb.Action_RunHTTPRequest:
		handler := &runHTTPActionHandler{
			rails:       r.rails,
			backend:     r.backend,
			token:       r.token,
			originalReq: r.originalReq,
			action:      action,
		}

		event, err := handler.Execute(ctx)
		if err != nil {
			return fmt.Errorf("handleAgentAction: failed to perform API call: %v", err)
		}

		if err := r.streamManager.Send(event); err != nil {
			return fmt.Errorf("handleAgentAction: failed to send gRPC message: %v", err)
		}

		log.WithContextFields(r.originalReq.Context(), log.Fields{
			"path": action.GetRunHTTPRequest().Path,
		}).Info("Successfully sent HTTP response event")
	case *pb.Action_RunMCPTool:
		mcpTool := action.GetRunMCPTool()

		// If a tool is not recongnized, propagate the message to the client
		// It's possible when a user has local MCP servers configured in IDE
		if !r.mcpManager.HasTool(mcpTool.Name) {
			return r.sendActionToWs(action)
		}

		event, err := r.mcpManager.CallTool(ctx, action)
		if err != nil {
			return fmt.Errorf("handleAgentAction: failed to call MCP tool: %v", err)
		}

		if err := r.streamManager.Send(event); err != nil {
			return fmt.Errorf("handleAgentAction: failed to send gRPC message: %v", err)
		}
	case *pb.Action_TrackLlmCallForSelfHosted:
		return r.streamManager.HandleCloudServiceTracking(ctx, action)
	default:
		return r.sendActionToWs(action)
	}

	return nil
}

func (r *runner) sendActionToWs(action *pb.Action) error {
	var err error
	r.marshalBuf, err = marshaler.MarshalAppend(r.marshalBuf[:0], action)
	if err != nil {
		return fmt.Errorf("sendActionToWs: failed to unmarshal action: %v", err)
	}

	deadline := time.Now().Add(wsWriteDeadline)
	if deadlineErr := r.conn.SetWriteDeadline(deadline); deadlineErr != nil {
		return fmt.Errorf("sendActionToWs: failed to set write deadline: %v", deadlineErr)
	}

	if err = r.conn.WriteMessage(websocket.BinaryMessage, r.marshalBuf); err != nil {
		if err == websocket.ErrCloseSent {
			log.WithRequest(r.originalReq).Info("sendActionToWs: failed to send WS message because websocket closed, ignoring")
			return nil
		}

		return fmt.Errorf("sendActionToWs: failed to send WS message: %v", err)
	}

	return nil
}

func (r *runner) stopWorkflow(reason string, closeErr error) error {
	log.WithRequest(r.originalReq).WithFields(log.Fields{
		"close_error": closeErr.Error(),
	}).Info("stopWorkflow: sending stop workflow request...")

	stopRequest := &pb.ClientEvent{
		Response: &pb.ClientEvent_StopWorkflow{
			StopWorkflow: &pb.StopWorkflowRequest{
				Reason: reason,
			},
		},
	}

	if err := r.streamManager.Send(stopRequest); err != nil {
		return fmt.Errorf("failed to send stop request: %v", err)
	}

	select {
	case <-r.originalReq.Context().Done():
		return nil
	case <-time.After(wsStopWorkflowTimeout):
		return fmt.Errorf("workflow didn't stop on time")
	}
}

// Shutdown gracefully stops the workflow runner during server shutdown.
// It releases the distributed lock immediately to allow other instances to acquire it.
// Then it waits for shutdown timeout to expire, sends a stop workflow request to the agent platform, and waits for
// acknowledgment.
// If the original request context is already canceled, it returns immediately.
// Errors during shutdown are logged but not returned to allow other runners to proceed.
func (r *runner) Shutdown(ctx context.Context) error {
	if r.lockFlow {
		r.lockManager.releaseLock(ctx, r.mutex, r.workflowID, r.workflowDefinition)
	}

	select {
	case <-r.originalReq.Context().Done():
		return nil
	case <-ctx.Done():
		err := r.stopWorkflow(
			"WORKHORSE_SERVER_SHUTDOWN",
			fmt.Errorf("duoworkflow: stopping workflow due to server shutdown"),
		)
		if err == nil {
			log.WithRequest(r.originalReq).WithError(
				fmt.Errorf("duoworkflow: stopped gracefully due to server shutdown"),
			).Error()
		} else {
			log.WithRequest(r.originalReq).WithError(
				fmt.Errorf("duoworkflow: failed to gracefully stop a workflow: %v", err),
			).Error()
		}

		return err
	}
}
