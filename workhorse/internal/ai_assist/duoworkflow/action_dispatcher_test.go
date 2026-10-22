package duoworkflow

import (
	"context"
	"errors"
	"net/http"
	"net/http/httptest"
	"strings"
	"testing"

	"github.com/prometheus/client_golang/prometheus/testutil"
	"github.com/sirupsen/logrus"
	logrustest "github.com/sirupsen/logrus/hooks/test"
	"github.com/stretchr/testify/require"
	pb "gitlab.com/gitlab-org/modelops/applied-ml/code-suggestions/ai-assist/clients/gopb/contract"

	"gitlab.com/gitlab-org/gitlab/workhorse/internal/testhelper"
)

func newTestDispatcher(t *testing.T, wf *mockWorkflowStream, client clientTransport, mcp mcpManager, backend http.Handler) *actionDispatcher {
	t.Helper()

	sess := newSession(httptest.NewRequest(http.MethodGet, "/duo", nil))
	sm := newTestStreamManager(t, wf)
	sm.session = sess

	return &actionDispatcher{
		session:     sess,
		client:      client,
		httpActions: &runHTTPActionHandler{backend: backend, session: sess},
		mcp:         mcp,
		streams:     sm,
	}
}

func httpAction(path string) *pb.Action {
	return &pb.Action{
		RequestID: "req-http",
		Action: &pb.Action_RunHTTPRequest{
			RunHTTPRequest: &pb.RunHTTPRequest{Method: http.MethodGet, Path: path},
		},
	}
}

// newLogHook captures what the standard logger logs until the test ends.
func newLogHook(t *testing.T) *logrustest.Hook {
	t.Helper()

	logger := logrus.StandardLogger()
	hook := &logrustest.Hook{}
	previous := logger.ReplaceHooks(logrus.LevelHooks{})
	logger.AddHook(hook)
	t.Cleanup(func() { logger.ReplaceHooks(previous) })

	return hook
}

// entriesWithPrefix returns the entries whose message starts with prefix, so
// that a test isn't thrown off by logs from unrelated goroutines.
func entriesWithPrefix(hook *logrustest.Hook, prefix string) []*logrus.Entry {
	var entries []*logrus.Entry
	for _, e := range hook.AllEntries() {
		if strings.HasPrefix(e.Message, prefix) {
			entries = append(entries, e)
		}
	}
	return entries
}

func TestActionDispatcher_classify(t *testing.T) {
	tests := []struct {
		name    string
		action  *pb.Action
		hasTool bool
		want    string
	}{
		{name: "HTTP request", action: httpAction("/api/v4/user"), want: actionTypeHTTP},
		{name: "MCP tool Workhorse knows", action: mcpAction("req-mcp", "gitlab_get_issue"), hasTool: true, want: actionTypeMCP},
		{name: "MCP tool from the client", action: mcpAction("req-mcp", "local_tool"), want: actionTypeClient},
		{
			name:   "self-hosted tracking",
			action: &pb.Action{Action: &pb.Action_TrackLlmCallForSelfHosted{TrackLlmCallForSelfHosted: &pb.TrackLlmCallForSelfHosted{}}},
			want:   actionTypeSelfHostedTracking,
		},
		{name: "checkpoint", action: &pb.Action{Action: &pb.Action_NewCheckpoint{NewCheckpoint: &pb.NewCheckpoint{}}}, want: actionTypeClient},
		{name: "command", action: &pb.Action{Action: &pb.Action_RunCommand{RunCommand: &pb.RunCommandAction{}}}, want: actionTypeClient},
	}

	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			d := &actionDispatcher{mcp: &mockMcpManager{hasToolResult: tt.hasTool}}

			require.Equal(t, tt.want, d.classify(tt.action))
		})
	}
}

func TestActionDispatcher_dispatch_metrics(t *testing.T) {
	testhelper.ConfigureSecret()

	errorStatusBackend := http.HandlerFunc(func(w http.ResponseWriter, _ *http.Request) {
		w.WriteHeader(http.StatusInternalServerError)
	})
	abortingBackend := http.HandlerFunc(func(_ http.ResponseWriter, _ *http.Request) {
		panic(http.ErrAbortHandler)
	})
	toolError := &pb.ClientEvent{Response: &pb.ClientEvent_ActionResponse{ActionResponse: &pb.ActionResponse{
		ResponseType: &pb.ActionResponse_PlainTextResponse{PlainTextResponse: &pb.PlainTextResponse{Error: "not found"}},
	}}}

	tests := []struct {
		name        string
		action      *pb.Action
		backend     http.Handler
		mcp         *mockMcpManager
		client      clientTransport
		sendErr     error
		wantType    string
		wantOutcome string
		wantErr     bool
	}{
		{
			name:        "an HTTP error status is still an answer",
			action:      httpAction("/api/v4/user"),
			backend:     errorStatusBackend,
			wantType:    actionTypeHTTP,
			wantOutcome: actionOutcomeOK,
		},
		{
			name:        "an HTTP request that could not complete",
			action:      httpAction("/api/v4/user"),
			backend:     abortingBackend,
			wantType:    actionTypeHTTP,
			wantOutcome: actionOutcomeError,
		},
		{
			name:        "an MCP tool that reports an error",
			action:      mcpAction("req-mcp", "gitlab_get_issue"),
			mcp:         &mockMcpManager{hasToolResult: true, callToolResult: toolError},
			wantType:    actionTypeMCP,
			wantOutcome: actionOutcomeError,
		},
		{
			name:        "an MCP call that fails",
			action:      mcpAction("req-mcp", "gitlab_get_issue"),
			mcp:         &mockMcpManager{hasToolResult: true, callToolError: errors.New("connection refused")},
			wantType:    actionTypeMCP,
			wantOutcome: actionOutcomeError,
		},
		{
			name:        "an action the client can't execute",
			action:      mcpAction("req-mcp", "local_tool"),
			client:      &unsupportedActionTransport{},
			wantType:    actionTypeClient,
			wantOutcome: actionOutcomeError,
		},
		{
			name:        "a response that can't be sent",
			action:      httpAction("/api/v4/user"),
			backend:     errorStatusBackend,
			sendErr:     errors.New("stream closed"),
			wantType:    actionTypeHTTP,
			wantOutcome: actionOutcomeFatal,
			wantErr:     true,
		},
	}

	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			mcp := tt.mcp
			if mcp == nil {
				mcp = &mockMcpManager{}
			}
			client := tt.client
			if client == nil {
				client = newWsManager(&mockWebSocketConn{})
			}
			d := newTestDispatcher(t, &mockWorkflowStream{sendError: tt.sendErr}, client, mcp, tt.backend)

			counter := actionsTotal.WithLabelValues(tt.wantType, tt.wantOutcome)
			before := testutil.ToFloat64(counter)

			err := d.dispatch(context.Background(), tt.action)
			if tt.wantErr {
				require.Error(t, err)
			} else {
				require.NoError(t, err)
			}

			require.InDelta(t, before+1, testutil.ToFloat64(counter), 0)
			require.Zero(t, testutil.ToFloat64(actionsInFlight.WithLabelValues(tt.wantType)))
		})
	}
}

func TestActionDispatcher_dispatch_logging(t *testing.T) {
	testhelper.ConfigureSecret()

	hook := newLogHook(t)

	backend := http.HandlerFunc(func(w http.ResponseWriter, _ *http.Request) {
		w.WriteHeader(http.StatusOK)
	})

	t.Run("logs one line per HTTP action, without the query string", func(t *testing.T) {
		hook.Reset()
		d := newTestDispatcher(t, &mockWorkflowStream{}, newWsManager(&mockWebSocketConn{}), &mockMcpManager{}, backend)

		require.NoError(t, d.dispatch(context.Background(), httpAction("/api/v4/search?search=secret")))

		entries := entriesWithPrefix(hook, "Handled action")
		require.Len(t, entries, 1)
		require.Equal(t, "/api/v4/search", entries[0].Data["path"])
		require.Equal(t, actionTypeHTTP, entries[0].Data["action_type"])
		require.Equal(t, "runHTTPRequest", entries[0].Data["action"])
		require.EqualValues(t, http.StatusOK, entries[0].Data["status_code"])
		require.Positive(t, entries[0].Data["response_size"])
	})

	t.Run("doesn't log actions forwarded to the client", func(t *testing.T) {
		hook.Reset()
		d := newTestDispatcher(t, &mockWorkflowStream{}, newWsManager(&mockWebSocketConn{}), &mockMcpManager{}, backend)

		checkpoint := &pb.Action{Action: &pb.Action_NewCheckpoint{NewCheckpoint: &pb.NewCheckpoint{}}}
		require.NoError(t, d.dispatch(context.Background(), checkpoint))

		require.Empty(t, entriesWithPrefix(hook, "Handled action"))
	})
}
