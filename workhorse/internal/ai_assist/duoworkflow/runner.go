package duoworkflow

import (
	"context"
	"errors"
	"fmt"
	"io"
	"net/http"
	"sync"
	"sync/atomic"
	"time"

	redsync "github.com/go-redsync/redsync/v4"
	redis "github.com/redis/go-redis/v9"
	pb "gitlab.com/gitlab-org/modelops/applied-ml/code-suggestions/ai-assist/clients/gopb/contract"

	"gitlab.com/gitlab-org/gitlab/workhorse/internal/api"
	"gitlab.com/gitlab-org/gitlab/workhorse/internal/log"
)

var errFailedToAcquireLockError = errors.New("handleWebSocketMessages: failed to acquire lock")

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

// stopCoordinator manages the graceful stop handshake between workhorse and DWS.
// When workhorse needs to stop a workflow (WebSocket close, ping failure, server
// shutdown), it sends a StopWorkflowRequest and waits for DWS to acknowledge by
// closing the gRPC stream with an Unavailable status code.
type stopCoordinator struct {
	// requested is set to true when stopWorkflow sends a StopWorkflowRequest
	// to DWS. It gates whether an Unavailable gRPC error from DWS should be
	// treated as a stop acknowledgment.
	requested atomic.Bool

	// acked is closed when DWS acknowledges a stop request by returning a
	// gRPC Unavailable error on the Recv stream. stopWorkflow selects on this
	// channel so it can return immediately instead of waiting for the full
	// timeout.
	acked chan struct{}

	// agentDone tracks the lifetime of handleAgentMessages. Close waits on
	// this before tearing down the gRPC stream so that a pending Recv can
	// observe the DWS stop acknowledgment before the connection is destroyed.
	agentDone sync.WaitGroup

	// workflowEnded is set to true when handleAgentMessages receives io.EOF,
	// meaning DWS finished the workflow naturally. When this is set,
	// handleWebSocketMessages should not attempt to send a StopWorkflowRequest
	workflowEnded atomic.Bool

	// shutdownStarted is set to true at the start of Shutdown. Close only
	// waits on shutdownDone when this is set, since Shutdown is only invoked
	// during server shutdown and never in the normal request path.
	shutdownStarted atomic.Bool

	// shutdownDone is closed by Shutdown when it finishes. Close waits on
	// this before calling closeWebSocketConnection so that Shutdown always
	// gets to send CloseGoingAway (1001) before Close sends CloseNormalClosure
	// (1000).
	shutdownDone chan struct{}
}

type runner struct {
	originalReq         *http.Request
	httpActionHandler   *runHTTPActionHandler
	ws                  *wsManager
	lockManager         *workflowLockManager
	workflowID          string
	mutex               *redsync.Mutex
	lockFlow            bool
	serverCapabilities  []string
	streamManager       *streamManager
	mcpManager          mcpManager
	stop                stopCoordinator
	stopWorkflowTimeout time.Duration
}

func newRunner(conn websocketConn, rails *api.API, backend http.Handler, relativeURLRoot string, r *http.Request, cfg *api.DuoWorkflow, rdb *redis.Client) (*runner, error) {
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

	httpActionHandler := &runHTTPActionHandler{
		backend:                   backend,
		relativeURLRoot:           relativeURLRoot,
		token:                     cfg.Service.Headers["x-gitlab-oauth-token"],
		shouldTimeoutHTTPRequests: cfg.TimeoutHTTPRequests,
		originalReq:               r,
	}

	return &runner{
		originalReq:        r,
		httpActionHandler:  httpActionHandler,
		ws:                 newWsManager(conn),
		lockManager:        newWorkflowLockManager(rdb),
		lockFlow:           lockFlow,
		serverCapabilities: cfg.ServerCapabilities,
		streamManager:      streamManager,
		mcpManager:         mcpManager,
		stop: stopCoordinator{
			acked:        make(chan struct{}),
			shutdownDone: make(chan struct{}),
		},
	}, nil
}

func (r *runner) Execute(ctx context.Context) error {
	// Register the pong handler before any goroutine calls ReadMessage.
	// In gorilla/websocket, pong frames are dispatched inside ReadMessage, so
	// if a pong arrives before SetPongHandler is called the default no-op
	// handler runs and the read deadline is never reset.
	r.ws.SetPongHandler(func(string) error {
		return r.ws.SetReadDeadline(time.Now().Add(wsPongTimeout))
	})

	errCh := make(chan error, 3) // one slot per goroutine: WS reader, agent reader, pinger

	r.stop.agentDone.Add(1)

	go r.handleWebSocketMessages(errCh)
	go func() {
		defer r.stop.agentDone.Done()
		r.handleAgentMessages(ctx, errCh)
	}()
	go r.pingWebSocket(ctx, errCh, wsPingInterval)

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

// pingWebSocket sends periodic WebSocket ping frames. It sets an initial read
// deadline before the first ping fires; after that the pong handler (registered
// in Execute) resets the deadline on every pong reply. A missing pong causes
// ReadClientEvent to return a timeout error which terminates handleWebSocketMessages.
func (r *runner) pingWebSocket(ctx context.Context, errCh chan<- error, interval time.Duration) {
	// Set the initial read deadline before any ping is sent. Subsequent resets
	// are handled by the pong handler registered in Execute().
	if err := r.ws.SetReadDeadline(time.Now().Add(wsPongTimeout)); err != nil {
		errCh <- fmt.Errorf("pingWebSocket: failed to set initial read deadline: %w", err)
		return
	}

	ticker := time.NewTicker(interval)
	defer ticker.Stop()

	for {
		select {
		case <-ctx.Done():
			return
		case <-ticker.C:
			if err := r.ws.Ping(); err != nil {
				errCh <- r.stopAndWrapError("pingWebSocket", "WORKHORSE_WEBSOCKET_PING_FAILED", err)
				return
			}
		}
	}
}

func (r *runner) handleWebSocketMessages(errCh chan<- error) {
	for {
		event, err := r.ws.ReadClientEvent()
		if err != nil {
			if reason, ok := r.ws.ReadError(err); ok {
				errCh <- r.stopAndWrapError("handleWebSocketMessages", reason, err)
			} else {
				errCh <- fmt.Errorf("handleWebSocketMessages: failed to read a WS message: %v", err)
			}
			return
		}

		if err := r.handleWebSocketMessage(event); err != nil {
			errCh <- err
			return
		}
	}
}

// stopAndWrapError sends a StopWorkflowRequest and returns the result. If the
// stop succeeds (DWS acknowledged) it returns nil; otherwise it wraps the error
// with the given caller label.
func (r *runner) stopAndWrapError(caller string, reason string, closeErr error) error {
	stopErr := r.stopWorkflow(reason, closeErr)
	if stopErr != nil {
		return fmt.Errorf("%s: %w", caller, stopErr)
	}
	return nil
}

func (r *runner) handleAgentMessages(ctx context.Context, errCh chan<- error) {
	for {
		action, err := r.streamManager.Recv()
		if err != nil {
			switch {
			case err == io.EOF:
				log.WithRequest(r.originalReq).Info("handleAgentMessages: EOF, expected when workflow ends")
				r.stop.workflowEnded.Store(true)
				errCh <- nil // Expected error when a workflow ends
			case errors.Is(err, errStreamUnavailable) && r.stop.requested.Load():
				log.WithRequest(r.originalReq).Info("handleAgentMessages: DWS acknowledged stop request")
				close(r.stop.acked)
				errCh <- nil
			case errors.Is(err, errInvalidRequest):
				log.WithRequest(r.originalReq).WithError(err).Info("handleAgentMessages: DWS rejected reconnect with INVALID_ARGUMENT")
				if wsErr := r.ws.SendInvalidRequest(err.Error()); wsErr != nil {
					log.WithRequest(r.originalReq).WithError(wsErr).Error("handleAgentMessages: failed to send invalid-request close frame")
				}
				errCh <- nil
			default:
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
	// Wait for handleAgentMessages to finish before closing the gRPC stream.
	// This ensures a pending Recv can observe the DWS stop acknowledgment
	// (Unavailable) before the connection is torn down.
	r.stop.agentDone.Wait()

	// When a server shutdown is in progress, wait for Shutdown to finish before
	// closing the WebSocket connection. Shutdown sends CloseGoingAway (1001) to
	// signal the client to reconnect; if Close races ahead and sends
	// CloseNormalClosure (1000) first, the client never sees the 1001 and won't
	// reconnect to the new instance. In the normal request path Shutdown is
	// never called, so we must not block on shutdownDone there.
	if r.stop.shutdownStarted.Load() {
		<-r.stop.shutdownDone
	}

	streamManagerCloseErr := r.logClose("stream manager", r.streamManager.Close())
	wsCloseErr := r.logClose("websocket connection", r.ws.Close())
	mcpManagerCloseErr := r.logClose("mcp manager", r.mcpManager.Close())

	return errors.Join(streamManagerCloseErr, wsCloseErr, mcpManagerCloseErr)
}

func (r *runner) handleWebSocketMessage(response *pb.ClientEvent) error {
	if startReq := response.GetStartRequest(); startReq != nil {
		// Acquire distributed lock when workflow starts
		if r.lockFlow {
			if err := r.acquireWorkflowLock(startReq); err != nil {
				return err
			}
		}

		// Make the workflow ID available to RunHTTPRequest actions so they can
		// tag outbound GitLab API calls with X-Gitlab-Duo-Workflow-Id. Runs
		// outside the lockFlow guard so the header is set even when Redis is
		// unavailable or LockConcurrentFlow is disabled.
		if r.httpActionHandler != nil {
			r.httpActionHandler.workflowID = startReq.WorkflowID
		}

		r.mcpManager.SetWorkflowID(startReq.WorkflowID)

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

func (r *runner) acquireWorkflowLock(startReq *pb.StartWorkflowRequest) error {
	r.workflowID = startReq.WorkflowID

	if r.workflowID == "" {
		log.WithRequest(r.originalReq).Error("No workflow ID provided in StartWorkflowRequest")
		return fmt.Errorf("handleWebSocketMessage: no workflow ID provided in StartWorkflowRequest")
	}

	mutex, err := r.lockManager.acquireLock(r.originalReq.Context(), r.workflowID)
	if err != nil && err != errLockIsUnavailable {
		return errFailedToAcquireLockError
	}

	r.mutex = mutex
	return nil
}

func (r *runner) handleAgentAction(ctx context.Context, action *pb.Action) error {
	switch action.Action.(type) {
	case *pb.Action_RunHTTPRequest:
		event, err := r.httpActionHandler.Execute(ctx, action)
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
			return r.ws.WriteAction(ctx, action)
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
		return r.ws.WriteAction(ctx, action)
	}

	return nil
}

func (r *runner) stopWorkflow(reason string, closeErr error) error {
	log.WithRequest(r.originalReq).WithFields(log.Fields{
		"close_error": closeErr.Error(),
	}).Info("stopWorkflow: sending stop workflow request...")

	r.stop.requested.Store(true)

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

	timeout := r.stopWorkflowTimeout
	if timeout == 0 {
		timeout = wsStopWorkflowTimeout
	}

	select {
	case <-r.stop.acked:
		return nil
	case <-time.After(timeout):
		return fmt.Errorf("workflow didn't stop on time")
	}
}

// Shutdown gracefully stops the workflow runner during server shutdown.
// It first waits for the workflow to finish naturally within the shutdown grace
// period. If either the request context or the shutdown context expires before
// the workflow completes, it sends a StopWorkflowRequest to DWS, releases the
// distributed lock, and sends a CloseGoingAway frame to the WebSocket client so
// the executor can reconnect to a new workhorse instance and resume from the
// last DWS checkpoint.
// Errors during shutdown are logged but not returned to allow other runners to proceed.
func (r *runner) Shutdown(ctx context.Context) error {
	// Signal Close that a shutdown is in progress so it waits for shutdownDone
	// before closing the WebSocket connection.
	r.stop.shutdownStarted.Store(true)

	// requestContextDone is set to true when the original request context fires
	// first. In that case the client is already gone, so we skip sending
	// CloseGoingAway — there is no one to receive it.
	var requestContextDone bool

	select {
	case <-r.originalReq.Context().Done():
		requestContextDone = true
		log.WithRequest(r.originalReq).Info("Shutdown: request context done, sending stop workflow")
	case <-ctx.Done():
		log.WithRequest(r.originalReq).Info("Shutdown: shutdown context done, sending stop workflow")
	}

	workflowEnded := r.stop.workflowEnded.Load()

	// If the workflow already ended naturally (DWS sent EOF), there is nothing
	// to stop and no reason to send CloseGoingAway — the client does not need
	// to reconnect to resume a workflow that has already finished.
	if !workflowEnded {
		err := r.stopWorkflow(
			"WORKHORSE_SERVER_SHUTDOWN",
			fmt.Errorf("duoworkflow: stopping workflow due to server shutdown"),
		)
		if err != nil {
			log.WithRequest(r.originalReq).WithError(err).Info("Shutdown: failed to stop workflow gracefully")
		} else {
			log.WithRequest(r.originalReq).Info("Shutdown: workflow stopped gracefully")
		}
	}

	// Always release the lock so the executor can acquire it on the new
	// workhorse instance. Even if the stop request failed or timed out, the
	// instance is going away and holding the lock would block reconnection
	// for up to 2 hours (the lock TTL).
	if r.lockFlow {
		// Use a detached context because the request context may already be
		// canceled during shutdown, but we still need to reach Redis.
		r.lockManager.releaseLock(context.Background(), r.mutex, r.workflowID) // lint:allow context.Background
	}

	// Send CloseGoingAway (1001) to signal the client to reconnect. Skip this
	// when the request context fired first (client is already gone) or when
	// the workflow ended naturally (nothing to reconnect to).
	if !requestContextDone && !workflowEnded {
		if wsErr := r.ws.SendGoingAway(); wsErr != nil {
			log.WithRequest(r.originalReq).WithError(wsErr).Info("Shutdown: failed to send CloseGoingAway to client")
		} else {
			log.WithRequest(r.originalReq).Info("Shutdown: successfully sent CloseGoingAway to client")
		}
	}

	if r.stop.shutdownDone != nil {
		close(r.stop.shutdownDone)
	}

	return nil
}
