package duoworkflow

import (
	"context"
	"errors"
	"fmt"
	"io"
	"net/http"
	"slices"
	"sync"
	"time"

	redsync "github.com/go-redsync/redsync/v4"
	redis "github.com/redis/go-redis/v9"
	pb "gitlab.com/gitlab-org/modelops/applied-ml/code-suggestions/ai-assist/clients/gopb/contract"

	"gitlab.com/gitlab-org/gitlab/workhorse/internal/api"
	"gitlab.com/gitlab-org/gitlab/workhorse/internal/log"

	"github.com/gorilla/websocket"
	"google.golang.org/protobuf/encoding/protojson"
	"google.golang.org/protobuf/proto"
)

const wsWriteDeadline = 60 * time.Second
const wsCloseTimeout = 5 * time.Second
const wsStopWorkflowTimeout = 10 * time.Second

// ClientCapabilities is how gitlab-lsp -> workhorse -> Duo Workflow Service communicates
// capabilities that can be used by Duo Workflow Service without breaking
// backwards compatibility. We intersect the capabilities of all parties and
// then new behavior can only depend on that behavior if it makes it all the
// way through. Whenever you add to this list you must also update the constant in
// ee/app/assets/javascripts/ai/duo_agentic_chat/utils/workflow_socket_utils.js
// and gitlab-lsp .
var ClientCapabilities = []string{
	"shell_command",
	"incremental_streaming",
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

type runner struct {
	rails       *api.API
	token       string
	originalReq *http.Request
	marshalBuf  []byte
	conn        websocketConn
	wf          workflowStream
	client      *Client
	sendMu      sync.Mutex
	mcpManager  mcpManager
	lockManager *workflowLockManager
	workflowID  string
	mutex       *redsync.Mutex
	lockFlow    bool
}

func newRunner(conn websocketConn, rails *api.API, r *http.Request, cfg *api.DuoWorkflow, rdb *redis.Client) (*runner, error) {
	userAgent := r.Header.Get("User-Agent")

	client, err := NewClient(cfg.ServiceURI, cfg.Headers, cfg.Secure, userAgent)
	if err != nil {
		return nil, fmt.Errorf("failed to initialize client: %v", err)
	}

	wf, err := client.ExecuteWorkflow(r.Context())
	if err != nil {
		return nil, fmt.Errorf("failed to initialize stream: %v", err)
	}

	mcpManager, err := newMcpManager(rails, r, cfg.McpServers)
	if err != nil {
		// Log the error while the feature is in development
		log.WithRequest(r).WithError(err).Info("failed to initialize MCP server(s)")
	}

	lockFlow := cfg.LockConcurrentFlow

	if lockFlow && rdb == nil {
		log.WithRequest(r).Info("Workflow locking will be skipped as redis is not configured")
		lockFlow = false
	}

	return &runner{
		rails:       rails,
		token:       cfg.Headers["x-gitlab-oauth-token"],
		originalReq: r,
		marshalBuf:  make([]byte, ActionResponseBodyLimit),
		conn:        conn,
		wf:          wf,
		client:      client,
		mcpManager:  mcpManager,
		lockManager: newWorkflowLockManager(rdb),
		lockFlow:    lockFlow,
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
			r.lockManager.releaseLock(ctx, r.mutex, r.workflowID)
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
		action, err := r.wf.Recv()
		if err != nil {
			if err == io.EOF {
				errCh <- nil // Expected error when a workflow ends
			} else {
				errCh <- fmt.Errorf("handleAgentMessages: failed to read a gRPC message: %v", err)
			}
			return
		}

		if err := r.handleAgentAction(ctx, action); err != nil {
			errCh <- err
			return
		}
	}
}

func (r *runner) Close() error {
	r.sendMu.Lock()
	defer r.sendMu.Unlock()

	return errors.Join(r.wf.CloseSend(), r.client.Close(), r.closeWebSocketConnection(), r.mcpManager.Close())
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
		startReq.ClientCapabilities = intersectClientCapabilities(startReq.ClientCapabilities)
		log.WithRequest(r.originalReq).WithFields(log.Fields{
			"client_capabilities": startReq.ClientCapabilities,
		}).Info("Sending startRequest")
	}

	log.WithContextFields(r.originalReq.Context(), log.Fields{
		"payload_size": proto.Size(response),
		"event_type":   fmt.Sprintf("%T", response.Response),
		"request_id":   response.GetActionResponse().GetRequestID(),
	}).Info("Sending action response")

	if err := r.threadSafeSend(response); err != nil {
		if err == io.EOF {
			// ignore EOF to let Recv() fail and return a meaningful message
			return nil
		}

		return fmt.Errorf("handleWebSocketMessage: failed to write a gRPC message: %v", err)
	}

	return nil
}

// Returns the intersection of what gitlab-lsp passed in and what workhorse
// supports.
func intersectClientCapabilities(fromClient []string) []string {
	var result = []string{}

	for _, cap := range ClientCapabilities {
		if slices.Contains(fromClient, cap) {
			result = append(result, cap)
		}
	}

	return result
}

func (r *runner) acquireWorkflowLock(startReq *pb.StartWorkflowRequest) error {
	r.workflowID = startReq.WorkflowID

	if r.workflowID == "" {
		log.WithRequest(r.originalReq).Error("No workflow ID provided in StartWorkflowRequest")
		return fmt.Errorf("handleWebSocketMessage: no workflow ID provided in StartWorkflowRequest")
	}

	mutex, err := r.lockManager.acquireLock(r.originalReq.Context(), r.workflowID)
	if err != nil {
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
			token:       r.token,
			originalReq: r.originalReq,
			action:      action,
		}

		event, err := handler.Execute(ctx)
		if err != nil {
			return fmt.Errorf("handleAgentAction: failed to perform API call: %v", err)
		}
		statusCode := event.GetActionResponse().GetHttpResponse().StatusCode

		log.WithContextFields(r.originalReq.Context(), log.Fields{
			"path":                 action.GetRunHTTPRequest().Path,
			"method":               action.GetRunHTTPRequest().Method,
			"status_code":          statusCode,
			"payload_size":         proto.Size(event),
			"event_type":           fmt.Sprintf("%T", event.Response),
			"action_response_type": fmt.Sprintf("%T", event.GetActionResponse().GetResponseType()),
			"request_id":           action.GetRequestID(),
		}).Info("Sending HTTP response event")

		if err := r.threadSafeSend(event); err != nil {
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

		log.WithContextFields(ctx, log.Fields{
			"request_id":           action.GetRequestID(),
			"name":                 mcpTool.Name,
			"args_size":            len(mcpTool.Args),
			"payload_size":         proto.Size(event),
			"event_type":           fmt.Sprintf("%T", event.Response),
			"action_response_type": fmt.Sprintf("%T", event.GetActionResponse().GetResponseType()),
		}).Info("Sending MCP tool response")

		if err := r.threadSafeSend(event); err != nil {
			return fmt.Errorf("handleAgentAction: failed to send gRPC message: %v", err)
		}
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
		if err != websocket.ErrCloseSent {
			return fmt.Errorf("sendActionToWs: failed to send WS message: %v", err)
		}
	}

	return nil
}

func (r *runner) threadSafeSend(event *pb.ClientEvent) error {
	r.sendMu.Lock()
	defer r.sendMu.Unlock()
	return r.wf.Send(event)
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

	if err := r.threadSafeSend(stopRequest); err != nil {
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
// It sends a stop workflow request to the agent platform and waits for acknowledgment.
// If the original request context is already canceled, it returns immediately.
// Errors during shutdown are logged but not returned to allow other runners to proceed.
func (r *runner) Shutdown(ctx context.Context) error {
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
