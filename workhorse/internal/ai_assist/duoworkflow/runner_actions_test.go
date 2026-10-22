package duoworkflow

import (
	"context"
	"errors"
	"fmt"
	"io"
	"net/http/httptest"
	"sync"
	"testing"
	"time"

	"github.com/stretchr/testify/require"
	pb "gitlab.com/gitlab-org/modelops/applied-ml/code-suggestions/ai-assist/clients/gopb/contract"
)

// chanWorkflowStream hands out the actions sent on recv, and ends the stream
// with io.EOF once recv is closed.
type chanWorkflowStream struct {
	recv    chan *pb.Action
	sent    chan *pb.ClientEvent
	sendErr error
}

func newChanWorkflowStream() *chanWorkflowStream {
	return &chanWorkflowStream{
		recv: make(chan *pb.Action),
		sent: make(chan *pb.ClientEvent, 100),
	}
}

func (s *chanWorkflowStream) Send(event *pb.ClientEvent) error {
	if s.sendErr != nil {
		return s.sendErr
	}
	s.sent <- event
	return nil
}

func (s *chanWorkflowStream) Recv() (*pb.Action, error) {
	action, ok := <-s.recv
	if !ok {
		return nil, io.EOF
	}
	return action, nil
}

func (s *chanWorkflowStream) CloseSend() error { return nil }

// funcMcpManager knows every tool and runs callTool for each call.
type funcMcpManager struct {
	callTool func(context.Context, *pb.Action) (*pb.ClientEvent, error)
}

func (m *funcMcpManager) HasTool(name string) bool   { return name != "client_tool" }
func (m *funcMcpManager) Tools() []*pb.McpTool       { return nil }
func (m *funcMcpManager) PreApprovedTools() []string { return nil }
func (m *funcMcpManager) Close() error               { return nil }
func (m *funcMcpManager) CallTool(ctx context.Context, action *pb.Action) (*pb.ClientEvent, error) {
	return m.callTool(ctx, action)
}

// recordingTransport records the actions written to the client. Its client
// sends nothing and needs no keepalive.
type recordingTransport struct {
	clientTransport
	written   chan *pb.Action
	closed    chan struct{}
	closeOnce sync.Once
}

func (t *recordingTransport) Start() error                     { return nil }
func (t *recordingTransport) KeepaliveInterval() time.Duration { return 0 }

func (t *recordingTransport) ReadClientEvent() (*pb.ClientEvent, error) {
	<-t.closed
	return nil, io.ErrClosedPipe
}

func (t *recordingTransport) ReadError(error) (string, bool) { return "", false }

func (t *recordingTransport) WriteAction(_ context.Context, action *pb.Action) error {
	t.written <- action
	return nil
}

func (t *recordingTransport) Close() error {
	t.closeOnce.Do(func() { close(t.closed) })
	return nil
}

func mcpAction(requestID, name string) *pb.Action {
	return &pb.Action{
		RequestID: requestID,
		Action:    &pb.Action_RunMCPTool{RunMCPTool: &pb.RunMCPTool{Name: name, Args: "{}"}},
	}
}

func clientAction(requestID string) *pb.Action {
	return &pb.Action{
		RequestID: requestID,
		Action:    &pb.Action_RunCommand{RunCommand: &pb.RunCommandAction{Program: "ls"}},
	}
}

func mcpResponse(action *pb.Action) *pb.ClientEvent {
	return &pb.ClientEvent{
		Response: &pb.ClientEvent_ActionResponse{
			ActionResponse: &pb.ActionResponse{
				RequestID: action.RequestID,
				ResponseType: &pb.ActionResponse_PlainTextResponse{
					PlainTextResponse: &pb.PlainTextResponse{Response: "ok"},
				},
			},
		},
	}
}

type actionTestRunner struct {
	*runner
	wf        *chanWorkflowStream
	transport *recordingTransport
	// errCh receives what Execute returns.
	errCh chan error
}

// startActionTestRunner executes a runner allowed size concurrent actions.
func startActionTestRunner(t *testing.T, size int, callTool func(context.Context, *pb.Action) (*pb.ClientEvent, error)) *actionTestRunner {
	t.Helper()

	wf := newChanWorkflowStream()
	transport := &recordingTransport{
		written: make(chan *pb.Action, 100),
		closed:  make(chan struct{}),
	}

	r := &runner{
		session:              newSession(httptest.NewRequest("GET", "/duo", nil)),
		client:               transport,
		lease:                newWorkflowLease(nil),
		streamManager:        newTestStreamManager(t, wf),
		mcpManager:           &funcMcpManager{callTool: callTool},
		maxConcurrentActions: size,
	}

	errCh := make(chan error, 1)
	go func() { errCh <- r.Execute(r.session.Context()) }()

	return &actionTestRunner{runner: r, wf: wf, transport: transport, errCh: errCh}
}

func receive[T any](t *testing.T, ch <-chan T) T {
	t.Helper()

	select {
	case v := <-ch:
		return v
	case <-time.After(5 * time.Second):
		t.Fatal("timed out waiting")
		var zero T
		return zero
	}
}

func requireNothingOn[T any](t *testing.T, ch <-chan T, msg string) {
	t.Helper()

	select {
	case <-ch:
		t.Fatal(msg)
	case <-time.After(50 * time.Millisecond):
	}
}

func TestRunner_handleAgentMessages_runsWorkhorseActionsConcurrently(t *testing.T) {
	const parallel = 3

	var started sync.WaitGroup
	started.Add(parallel)
	release := make(chan struct{})

	tr := startActionTestRunner(t, parallel, func(_ context.Context, action *pb.Action) (*pb.ClientEvent, error) {
		started.Done()
		<-release
		return mcpResponse(action), nil
	})

	tr.wf.recv <- mcpAction("mcp-1", "gitlab_search")
	tr.wf.recv <- clientAction("client-1")
	tr.wf.recv <- mcpAction("mcp-2", "gitlab_search")
	tr.wf.recv <- mcpAction("local", "client_tool")
	tr.wf.recv <- mcpAction("mcp-3", "gitlab_search")
	tr.wf.recv <- clientAction("client-2")

	allStarted := make(chan struct{})
	go func() {
		started.Wait()
		close(allStarted)
	}()
	receive(t, allStarted)
	require.NotNil(t, tr.actions)

	// While every MCP call is still in flight, client-bound actions, including
	// MCP tools workhorse doesn't know, reach the client in receive order.
	require.Equal(t, "client-1", receive(t, tr.transport.written).RequestID)
	require.Equal(t, "local", receive(t, tr.transport.written).RequestID)
	require.Equal(t, "client-2", receive(t, tr.transport.written).RequestID)
	requireNothingOn(t, tr.wf.sent, "no MCP call has completed yet")

	close(release)

	var answered []string
	for range parallel {
		answered = append(answered, receive(t, tr.wf.sent).GetActionResponse().RequestID)
	}
	require.ElementsMatch(t, []string{"mcp-1", "mcp-2", "mcp-3"}, answered)

	close(tr.wf.recv)
	require.NoError(t, receive(t, tr.errCh))
	require.NoError(t, tr.Close())
}

func TestRunner_handleAgentMessages_runsActionsInOrderWithoutPool(t *testing.T) {
	for _, size := range []int{0, 1} {
		t.Run(fmt.Sprintf("size %d", size), func(t *testing.T) {
			release := make(chan struct{})
			tr := startActionTestRunner(t, size, func(_ context.Context, action *pb.Action) (*pb.ClientEvent, error) {
				<-release
				return mcpResponse(action), nil
			})
			tr.wf.recv <- mcpAction("mcp-1", "gitlab_search")
			require.Nil(t, tr.actions)
			go func() { tr.wf.recv <- clientAction("client-1") }()

			requireNothingOn(t, tr.transport.written, "the client action must wait for the MCP call before it")

			close(release)
			require.Equal(t, "mcp-1", receive(t, tr.wf.sent).GetActionResponse().RequestID)
			require.Equal(t, "client-1", receive(t, tr.transport.written).RequestID)

			close(tr.wf.recv)
			require.NoError(t, receive(t, tr.errCh))
			require.NoError(t, tr.Close())
		})
	}
}

func TestRunner_handleAgentMessages_answersPanickingActionWithError(t *testing.T) {
	tr := startActionTestRunner(t, 2, func(_ context.Context, action *pb.Action) (*pb.ClientEvent, error) {
		if action.RequestID == "boom" {
			panic("unexpected nil")
		}
		return mcpResponse(action), nil
	})

	tr.wf.recv <- mcpAction("boom", "gitlab_search")
	tr.wf.recv <- mcpAction("fine", "gitlab_search")

	responses := map[string]*pb.ActionResponse{}
	for range 2 {
		response := receive(t, tr.wf.sent).GetActionResponse()
		responses[response.RequestID] = response
	}

	require.Equal(t, errActionPanicked.Error(), responses["boom"].GetPlainTextResponse().Error)
	require.Equal(t, "ok", responses["fine"].GetPlainTextResponse().Response)

	close(tr.wf.recv)
	require.NoError(t, receive(t, tr.errCh), "a panic in one action must not end the run")
	require.NoError(t, tr.Close())
}

func TestRunner_handleAgentMessages_endsRunWhenResponseCannotBeSent(t *testing.T) {
	tr := startActionTestRunner(t, 2, func(_ context.Context, action *pb.Action) (*pb.ClientEvent, error) {
		return mcpResponse(action), nil
	})
	tr.wf.sendErr = errors.New("stream closed")

	tr.wf.recv <- mcpAction("mcp-1", "gitlab_search")

	require.ErrorContains(t, receive(t, tr.errCh), "stream closed")

	close(tr.wf.recv)
	require.NoError(t, tr.Close())
}

func TestRunner_Close_cancelsActionsInFlight(t *testing.T) {
	started := make(chan struct{})
	canceled := make(chan error, 1)

	tr := startActionTestRunner(t, 2, func(ctx context.Context, action *pb.Action) (*pb.ClientEvent, error) {
		close(started)
		<-ctx.Done()
		canceled <- context.Cause(ctx)
		return mcpResponse(action), nil
	})

	tr.wf.recv <- mcpAction("mcp-1", "gitlab_search")
	receive(t, started)

	close(tr.wf.recv)
	require.NoError(t, receive(t, tr.errCh))

	require.NoError(t, tr.Close())

	select {
	case err := <-canceled:
		require.ErrorIs(t, err, errActionPoolClosed)
	default:
		t.Fatal("Close must return only once the action in flight has returned")
	}
}

func TestStreamManager_HandleCloudServiceTracking_concurrentCalls(t *testing.T) {
	const calls = 5

	cloudStream := &mockSelfHostedWorkflowStream{}
	for i := range calls {
		cloudStream.recvActions = append(cloudStream.recvActions, &pb.TrackSelfHostedAction{RequestID: fmt.Sprint(i)})
	}

	wf := &mockWorkflowStream{}
	sm := newTestStreamManager(t, wf)
	sm.cloudServiceStream = cloudStream

	errs := make([]error, calls)

	var wg sync.WaitGroup
	for i := range calls {
		wg.Go(func() {
			action := &pb.Action{
				RequestID: fmt.Sprint(i),
				Action: &pb.Action_TrackLlmCallForSelfHosted{
					TrackLlmCallForSelfHosted: &pb.TrackLlmCallForSelfHosted{WorkflowID: "wf"},
				},
			}
			errs[i] = sm.HandleCloudServiceTracking(context.Background(), action)
		})
	}
	wg.Wait()

	require.NoError(t, errors.Join(errs...))

	require.Len(t, cloudStream.getSendEvents(), calls)
	require.Len(t, wf.getSendEvents(), calls)
}
