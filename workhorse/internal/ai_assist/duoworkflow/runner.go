package duoworkflow

import (
	"context"
	"errors"
	"fmt"
	"io"
	"net/http"
	"time"

	redis "github.com/redis/go-redis/v9"
	pb "gitlab.com/gitlab-org/modelops/applied-ml/code-suggestions/ai-assist/clients/gopb/contract"
	"google.golang.org/protobuf/proto"

	"gitlab.com/gitlab-org/gitlab/workhorse/internal/api"
	"gitlab.com/gitlab-org/gitlab/workhorse/internal/log"
)

var errDuplicateStartRequest = errors.New("handleClientEvent: the workflow was already started on this connection")

// Stamped unconditionally: a client must not get to choose its own value here.
func markClientInjected(tools []*pb.McpTool) {
	for _, tool := range tools {
		tool.ClientInjected = proto.Bool(true)
	}
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
	session             *session
	httpActionHandler   *runHTTPActionHandler
	client              clientTransport
	lease               *workflowLease
	serverCapabilities  []string
	streamManager       *streamManager
	mcpManager          mcpManager
	stop                stopCoordinator
	stopWorkflowTimeout time.Duration

	// maxConcurrentActions is the size of the action pool. At 1 or below,
	// actions run one at a time on the goroutine receiving them.
	maxConcurrentActions int
	// actions is nil when actions run one at a time. Set by Execute before
	// any goroutine starts.
	actions *actionPool

	// started is set once the start request has been handled. Only the
	// goroutine reading client events touches it.
	started bool

	// teardown is read by Recv when it labels sessionErrorsTotal.
	teardown teardownTracker
}

func newRunner(client clientTransport, rails *api.API, backend http.Handler, relativeURLRoot string, r *http.Request, cfg *api.DuoWorkflow, rdb *redis.Client) (*runner, error) {
	if cfg.Service == nil {
		return nil, fmt.Errorf("failed to initialize client: Service configuration is nil")
	}

	var lockManager *workflowLockManager
	if cfg.LockConcurrentFlow {
		if rdb == nil {
			log.WithRequest(r).Info("Workflow locking will be skipped as redis is not configured")
		} else {
			lockManager = newWorkflowLockManager(rdb)
		}
	}

	sess := newSession(r)

	start := time.Now()
	streamManager, err := newStreamManager(sess, cfg)
	if err != nil {
		sess.Close()
		return nil, fmt.Errorf("failed to initialize stream manager: %v", err)
	}
	sessionSetupDurationSeconds.WithLabelValues(setupStageGRPC).Observe(time.Since(start).Seconds())

	// Servers that fail to initialize are reported one by one; the run goes
	// ahead without their tools.
	start = time.Now()
	mcpManager, _ := newMcpManager(rails, sess, cfg.McpServers)
	if len(cfg.McpServers) > 0 {
		sessionSetupDurationSeconds.WithLabelValues(setupStageMCP).Observe(time.Since(start).Seconds())
	}

	httpActionHandler := &runHTTPActionHandler{
		backend:                   backend,
		relativeURLRoot:           relativeURLRoot,
		token:                     cfg.Service.Headers["x-gitlab-oauth-token"],
		shouldTimeoutHTTPRequests: cfg.TimeoutHTTPRequests,
		session:                   sess,
		clientType:                cfg.Service.Headers["x-gitlab-client-type"],
		clientName:                cfg.Service.Headers["x-gitlab-client-name"],
	}

	rnr := &runner{
		session:              sess,
		httpActionHandler:    httpActionHandler,
		client:               client,
		lease:                newWorkflowLease(lockManager),
		serverCapabilities:   cfg.ServerCapabilities,
		streamManager:        streamManager,
		mcpManager:           mcpManager,
		maxConcurrentActions: cfg.MaxConcurrentActions,
		stop: stopCoordinator{
			acked:        make(chan struct{}),
			shutdownDone: make(chan struct{}),
		},
	}

	// Let Recv read back the cause workhorse recorded, so every session error
	// is labeled with what ended the stream.
	streamManager.teardownReason = rnr.teardown.load

	return rnr, nil
}

func (r *runner) Execute(ctx context.Context) error {
	// Arm the transport before any goroutine reads from it, so liveness
	// tracking is in place from the very first client event.
	if err := r.client.Start(); err != nil {
		return fmt.Errorf("Execute: failed to start client transport: %w", err)
	}

	errCh := make(chan error, 4) // one slot per sender: client reader, agent reader, keepalive, action pool

	if r.maxConcurrentActions > 1 {
		r.actions = newActionPool(ctx, r.maxConcurrentActions, errCh)
	}

	r.stop.agentDone.Add(1)

	go r.handleClientEvents(errCh)
	go func() {
		defer r.stop.agentDone.Done()
		r.handleAgentMessages(ctx, errCh)
	}()
	go r.keepaliveClient(ctx, errCh)

	return <-errCh
}

// keepaliveClient signals liveness to the client at a fixed interval. A dead
// client eventually makes ReadClientEvent fail, which terminates
// handleClientEvents. A transport with no interval has nothing to keep alive.
func (r *runner) keepaliveClient(ctx context.Context, errCh chan<- error) {
	interval := r.client.KeepaliveInterval()
	if interval <= 0 {
		return
	}

	ticker := time.NewTicker(interval)
	defer ticker.Stop()

	for {
		select {
		case <-ctx.Done():
			return
		case <-ticker.C:
			if err := r.client.Keepalive(); err != nil {
				r.teardown.record(teardownClientKeepaliveFailed)
				errCh <- r.stopAndWrapError("keepaliveClient", reasonKeepaliveFailed, err)
				return
			}
		}
	}
}

func (r *runner) handleClientEvents(errCh chan<- error) {
	for {
		event, err := r.client.ReadClientEvent()
		if err != nil {
			if reason, ok := r.client.ReadError(err); ok {
				r.teardown.record(clientDisconnectReason(reason))
				errCh <- r.stopAndWrapError("handleClientEvents", reason, err)
			} else {
				// Not an orderly disconnect, so no stop request is sent and the
				// stream is torn down locally instead.
				r.teardown.record(teardownClientReadFailed)
				errCh <- fmt.Errorf("handleClientEvents: failed to read a client event: %w", err)
			}
			return
		}

		if err := r.handleClientEvent(event); err != nil {
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
	dispatcher := r.actionDispatcher()

	for {
		action, err := r.streamManager.Recv()
		if err != nil {
			switch {
			case err == io.EOF:
				r.session.logger().Info("handleAgentMessages: EOF, expected when workflow ends")
				r.stop.workflowEnded.Store(true)
				errCh <- nil // Expected error when a workflow ends
			case errors.Is(err, errStreamUnavailable) && r.stop.requested.Load():
				r.session.logger().Info("handleAgentMessages: DWS acknowledged stop request")
				r.stop.acknowledge()
				errCh <- nil
			case errors.Is(err, errStreamUnavailable):
				// DWS closed the stream on its own, e.g. its instance is draining on
				// SIGTERM. The session is resumable from its last checkpoint, so tell
				// the client to reconnect the same way Shutdown does for a workhorse
				// drain. Nothing is left to stop on the DWS side.
				r.session.logger().Info("handleAgentMessages: DWS closed the stream as unavailable, signaling client to reconnect")
				r.stop.workflowEnded.Store(true)
				if clientErr := r.client.SendGoingAway(closeReasonDWSUnavailable); clientErr != nil {
					r.session.logger().WithError(clientErr).Error("handleAgentMessages: failed to signal going away to client")
				}
				errCh <- nil
			case errors.Is(err, errInvalidRequest):
				r.session.logger().WithError(err).Info("handleAgentMessages: DWS rejected reconnect with INVALID_ARGUMENT")
				if clientErr := r.client.SendInvalidRequest(err.Error()); clientErr != nil {
					r.session.logger().WithError(clientErr).Error("handleAgentMessages: failed to send invalid-request signal")
				}
				errCh <- nil
			default:
				errCh <- fmt.Errorf("handleAgentMessages: %w", err)
			}
			return
		}

		if err := dispatcher.dispatch(ctx, action); err != nil {
			errCh <- err
			return
		}
	}
}

func (r *runner) logClose(name string, err error) error {
	if err != nil {
		r.session.logger().WithFields(log.Fields{
			"connection_type": name,
		}).WithError(err).Error("failed to close")
	} else {
		r.session.logger().WithFields(log.Fields{
			"connection_type": name,
		}).Info("closed")
	}
	return err
}

func (r *runner) Close() error {
	// Deferred so the lock is released even if closing panics. It still runs
	// last, once the stream to DWS is closed, so a reconnect elsewhere can't run
	// alongside it. Shutdown releases earlier on purpose, as it is draining.
	defer func() {
		r.lease.release(r.session.Context())
		r.session.Close()
	}()

	// Wait for handleAgentMessages to finish before closing the gRPC stream, so
	// that a pending Recv can observe the DWS stop acknowledgment (Unavailable)
	// before the connection is torn down.
	//
	// Only when a stop was actually requested. Otherwise there is no
	// acknowledgment coming and the wait would block until the stream fails on
	// its own: a workflow that never started, because the lock was held
	// elsewhere, leaves DWS waiting on its first Recv and workhorse waiting on
	// ours.
	if r.stop.requested.Load() && !r.stop.waitForAgent(r.stop.remaining(r.stopTimeout())) {
		// Closing the stream below is what unblocks the pending Recv.
		r.session.logger().Info("Close: DWS did not end the stream after a stop request, closing it")
	}

	// The run is over, so actions still in flight are canceled. They are
	// waited for so that none sends its response on a closed stream.
	if !r.actions.close(r.stopTimeout()) {
		r.session.logger().Info("Close: actions still in flight after the stop timeout, closing the stream")
	}

	// When a server shutdown is in progress, wait for Shutdown to finish before
	// closing the client transport. Shutdown signals the client to reconnect;
	// if Close races ahead and terminates the connection normally first, the
	// client never sees that signal and won't reconnect to the new instance. In
	// the normal request path Shutdown is never called, so we must not block on
	// shutdownDone there.
	//
	// Not when the workflow already ended: Shutdown sends nothing to the client
	// then, and it only wakes on the drain deadline, so waiting would hold a
	// finished session's connection open for the whole grace period.
	if r.stop.shutdownStarted.Load() && !r.stop.workflowEnded.Load() {
		<-r.stop.shutdownDone
	}

	streamManagerCloseErr := r.logClose("stream manager", r.streamManager.Close())
	clientCloseErr := r.logClose("client transport", r.client.Close())
	mcpManagerCloseErr := r.logClose("mcp manager", r.mcpManager.Close())

	return errors.Join(streamManagerCloseErr, clientCloseErr, mcpManagerCloseErr)
}

func (r *runner) stopTimeout() time.Duration {
	if r.stopWorkflowTimeout == 0 {
		return wsStopWorkflowTimeout
	}
	return r.stopWorkflowTimeout
}

func (r *runner) handleClientEvent(response *pb.ClientEvent) error {
	if startReq := response.GetStartRequest(); startReq != nil {
		// The lock, the workflow ID and the injected MCP tools all belong to
		// the first start request; a client reconnects to start again.
		if r.started {
			return errDuplicateStartRequest
		}
		r.started = true

		// WorkflowDefinition is deprecated, but there is no strategy yet to stop using and eventually
		// remove it. Legacy/chat flows have no concept of a flow definition until they are migrated to
		// the flow registry, so this field is still the only value we get for them today.
		//lint:ignore SA1019 see comment above
		if err := r.lease.acquire(r.session.Context(), startReq.WorkflowID, startReq.WorkflowDefinition); err != nil { //nolint:staticcheck // SA1019: see comment above
			return err
		}

		// RunHTTPRequest actions and MCP calls tag outbound requests with the
		// workflow ID, whether or not locking is enabled.
		r.session.setWorkflowID(startReq.WorkflowID)

		for _, tool := range startReq.McpTools {
			tool.Trusted = nil
		}
		markClientInjected(startReq.McpTools)

		startReq.McpTools = append(startReq.McpTools, r.mcpManager.Tools()...)
		startReq.PreapprovedTools = append(startReq.PreapprovedTools, r.mcpManager.PreApprovedTools()...)
		startReq.ClientCapabilities = append(
			intersectClientCapabilities(startReq.ClientCapabilities),
			intersectServerCapabilities(r.serverCapabilities)...,
		)
		r.session.logger().WithFields(log.Fields{
			"client_capabilities": startReq.ClientCapabilities,
		}).Info("Sending startRequest")
	}

	if err := r.streamManager.Send(response); err != nil {
		if err == io.EOF {
			// ignore EOF to let Recv() fail and return a meaningful message
			return nil
		}

		return fmt.Errorf("handleClientEvent: failed to write a gRPC message: %v", err)
	}

	return nil
}

func (r *runner) stopWorkflow(reason string, closeErr error) error {
	return r.stop.request(func() error {
		r.session.logger().WithFields(log.Fields{
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
			return fmt.Errorf("failed to send stop request: %w", err)
		}
		return nil
	}, r.stopTimeout())
}

// Shutdown gracefully stops the workflow runner during server shutdown.
// It first waits for the workflow to finish naturally within the shutdown grace
// period. If either the session context or the shutdown context expires before
// the workflow completes, it sends a StopWorkflowRequest to DWS, releases the
// distributed lock, and signals the client to go away so the executor can
// reconnect to a new workhorse instance and resume from the last DWS
// checkpoint.
// Errors during shutdown are logged but not returned to allow other runners to proceed.
func (r *runner) Shutdown(ctx context.Context) error {
	// Signal Close that a shutdown is in progress so it waits for shutdownDone
	// before closing the WebSocket connection.
	r.stop.shutdownStarted.Store(true)

	// sessionDone is set to true when the session context fires
	// first. In that case the client is already gone, so we skip the going-away
	// signal — there is no one to receive it.
	var sessionDone bool

	select {
	case <-r.session.Context().Done():
		sessionDone = true
		r.session.logger().Info("Shutdown: session context done, sending stop workflow")
	case <-ctx.Done():
		r.session.logger().Info("Shutdown: shutdown context done, sending stop workflow")
	}

	workflowEnded := r.stop.workflowEnded.Load()

	// If the workflow already ended naturally (DWS sent EOF), there is nothing
	// to stop and no reason to signal going away — the client does not need to
	// reconnect to resume a workflow that has already finished.
	if !workflowEnded {
		r.teardown.record(teardownWorkhorseShutdown)
		err := r.stopWorkflow(
			reasonServerShutdown,
			fmt.Errorf("duoworkflow: stopping workflow due to server shutdown"),
		)
		if err != nil {
			r.session.logger().WithError(err).Info("Shutdown: failed to stop workflow gracefully")
		} else {
			r.session.logger().Info("Shutdown: workflow stopped gracefully")
		}
	}

	// Always release the lock so the executor can acquire it on the new
	// workhorse instance. Even if the stop request failed or timed out, the
	// instance is going away and holding the lock would block reconnection
	// for up to 2 hours (the lock TTL).
	r.lease.release(r.session.Context())

	// Signal the client to reconnect. Skip this when the session context fired
	// first (client is already gone) or when the workflow ended naturally
	// (nothing to reconnect to).
	if !sessionDone && !workflowEnded {
		if clientErr := r.client.SendGoingAway(closeReasonWorkhorseShutdown); clientErr != nil {
			r.session.logger().WithError(clientErr).Info("Shutdown: failed to signal going away to client")
		} else {
			r.session.logger().Info("Shutdown: successfully signaled going away to client")
		}
	}

	if r.stop.shutdownDone != nil {
		close(r.stop.shutdownDone)
	}

	return nil
}
