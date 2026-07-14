package duoworkflow

import (
	"context"
	"errors"
	"fmt"
	"io"
	"net/http"
	"net/http/httptest"
	"net/url"
	"strings"
	"sync"
	"testing"
	"time"

	"github.com/gorilla/websocket"
	redis "github.com/redis/go-redis/v9"
	"github.com/stretchr/testify/assert"
	"github.com/stretchr/testify/require"
	pb "gitlab.com/gitlab-org/modelops/applied-ml/code-suggestions/ai-assist/clients/gopb/contract"
	"google.golang.org/grpc/codes"
	"google.golang.org/grpc/status"

	"gitlab.com/gitlab-org/gitlab/workhorse/internal/api"
)

type mockWebSocketConn struct {
	readMessages       [][]byte
	writeMessages      [][]byte
	readDeadlinesMu    sync.Mutex
	readDeadlines      []time.Time
	writeDeadlines     []time.Time
	readIndex          int
	readError          error
	writeError         error
	closeError         error
	writeControlError  error
	setDeadlineError   error
	clearDeadlineError error
	blockCh            chan bool
	pongHandlerMu      sync.Mutex
	pongHandler        func(string) error
}

func (m *mockWebSocketConn) ReadMessage() (int, []byte, error) {
	if m.blockCh != nil {
		<-m.blockCh
	}

	if m.readError != nil {
		return 0, nil, m.readError
	}
	if m.readIndex >= len(m.readMessages) {
		return 0, nil, io.EOF
	}
	msg := m.readMessages[m.readIndex]
	m.readIndex++
	return websocket.BinaryMessage, msg, nil
}

func (m *mockWebSocketConn) WriteMessage(_ int, data []byte) error {
	if m.writeError != nil {
		return m.writeError
	}
	m.writeMessages = append(m.writeMessages, data)
	return nil
}

func (m *mockWebSocketConn) Close() error {
	return m.closeError
}

func (m *mockWebSocketConn) WriteControl(_ int, data []byte, _ time.Time) error {
	if m.writeControlError != nil {
		return m.writeControlError
	}
	// Mirror gorilla's real WriteControl, which rejects any control frame whose
	// payload exceeds the WebSocket 125-byte limit. The previous mock ignored
	// the payload and silently accepted oversized close reasons, hiding the
	// dropped-4400 regression this test now guards against.
	const maxControlFramePayloadSize = 125
	if len(data) > maxControlFramePayloadSize {
		return errors.New("websocket: invalid control frame")
	}
	return nil
}

func (m *mockWebSocketConn) SetReadDeadline(t time.Time) error {
	m.readDeadlinesMu.Lock()
	defer m.readDeadlinesMu.Unlock()
	m.readDeadlines = append(m.readDeadlines, t)
	return m.setDeadlineError
}

func (m *mockWebSocketConn) getReadDeadlines() []time.Time {
	m.readDeadlinesMu.Lock()
	defer m.readDeadlinesMu.Unlock()
	result := make([]time.Time, len(m.readDeadlines))
	copy(result, m.readDeadlines)
	return result
}

func (m *mockWebSocketConn) SetWriteDeadline(t time.Time) error {
	m.writeDeadlines = append(m.writeDeadlines, t)
	if t.IsZero() {
		return m.clearDeadlineError
	}
	return m.setDeadlineError
}

func (m *mockWebSocketConn) SetPongHandler(h func(string) error) {
	m.pongHandlerMu.Lock()
	defer m.pongHandlerMu.Unlock()
	m.pongHandler = h
}

func (m *mockWebSocketConn) getPongHandler() func(string) error {
	m.pongHandlerMu.Lock()
	defer m.pongHandlerMu.Unlock()
	return m.pongHandler
}

type mockWorkflowStream struct {
	sendEvents  []*pb.ClientEvent
	sendMu      sync.Mutex
	recvActions []*pb.Action
	recvIndex   int
	sendError   error
	recvError   error
	blockCh     chan bool
}

func (m *mockWorkflowStream) getSendEvents() []*pb.ClientEvent {
	m.sendMu.Lock()
	defer m.sendMu.Unlock()

	return m.sendEvents
}

func (m *mockWorkflowStream) Send(event *pb.ClientEvent) error {
	m.sendMu.Lock()
	defer m.sendMu.Unlock()

	if m.sendError != nil {
		return m.sendError
	}
	m.sendEvents = append(m.sendEvents, event)
	return nil
}

func (m *mockWorkflowStream) Recv() (*pb.Action, error) {
	if m.blockCh != nil {
		<-m.blockCh
	}

	if m.recvError != nil {
		return nil, m.recvError
	}
	if m.recvIndex >= len(m.recvActions) {
		return nil, io.EOF
	}
	action := m.recvActions[m.recvIndex]
	m.recvIndex++
	return action, nil
}

func (m *mockWorkflowStream) CloseSend() error {
	return nil
}

type mockSelfHostedWorkflowStream struct {
	sendEvents  []*pb.TrackSelfHostedClientEvent
	sendMu      sync.Mutex
	recvActions []*pb.TrackSelfHostedAction
	recvIndex   int
	sendError   error
	recvError   error
	blockCh     chan bool
}

func (m *mockSelfHostedWorkflowStream) getSendEvents() []*pb.TrackSelfHostedClientEvent {
	m.sendMu.Lock()
	defer m.sendMu.Unlock()

	return m.sendEvents
}

func (m *mockSelfHostedWorkflowStream) Send(event *pb.TrackSelfHostedClientEvent) error {
	m.sendMu.Lock()
	defer m.sendMu.Unlock()

	if m.sendError != nil {
		return m.sendError
	}
	m.sendEvents = append(m.sendEvents, event)
	return nil
}

func (m *mockSelfHostedWorkflowStream) Recv() (*pb.TrackSelfHostedAction, error) {
	if m.blockCh != nil {
		<-m.blockCh
	}

	if m.recvError != nil {
		return nil, m.recvError
	}
	if m.recvIndex >= len(m.recvActions) {
		return nil, io.EOF
	}
	action := m.recvActions[m.recvIndex]
	m.recvIndex++
	return action, nil
}

func (m *mockSelfHostedWorkflowStream) CloseSend() error {
	if m == nil {
		return nil
	}
	return nil
}

type mockMcpManager struct {
	tools               []*pb.McpTool
	preApprovedTools    []string
	hasToolResult       bool
	callToolResult      *pb.ClientEvent
	callToolError       error
	closeError          error
	callToolInvocations []struct {
		name string
		args string
	}
	setWorkflowIDCalls []string
}

func (m *mockMcpManager) HasTool(_ string) bool {
	if m == nil {
		return false
	}

	return m.hasToolResult
}

func (m *mockMcpManager) Tools() []*pb.McpTool {
	if m == nil {
		return nil
	}

	return m.tools
}

func (m *mockMcpManager) PreApprovedTools() []string {
	if m == nil {
		return nil
	}

	return m.preApprovedTools
}

func (m *mockMcpManager) CallTool(_ context.Context, action *pb.Action) (*pb.ClientEvent, error) {
	mcpTool := action.GetRunMCPTool()

	m.callToolInvocations = append(m.callToolInvocations, struct {
		name string
		args string
	}{name: mcpTool.Name, args: mcpTool.Args})

	if m.callToolError != nil {
		return nil, m.callToolError
	}
	return m.callToolResult, nil
}

func (m *mockMcpManager) SetWorkflowID(id string) {
	if m == nil {
		return
	}
	m.setWorkflowIDCalls = append(m.setWorkflowIDCalls, id)
}

func (m *mockMcpManager) Close() error {
	if m == nil {
		return nil
	}

	return m.closeError
}

func Test_newRunner(t *testing.T) {
	server := setupTestServer(t)
	mockConn := &mockWebSocketConn{}

	apiServer := httptest.NewServer(http.HandlerFunc(func(w http.ResponseWriter, _ *http.Request) {
		w.Header().Set("Content-Type", api.ResponseContentType)
		w.WriteHeader(http.StatusOK)
	}))
	defer apiServer.Close()

	apiURL, err := url.Parse(apiServer.URL)
	require.NoError(t, err)

	apiClient := api.NewAPI(apiURL, "test-version", http.DefaultTransport)

	req := httptest.NewRequest("GET", "/duo", nil)
	cfg := &api.DuoWorkflow{
		Service: &api.DuoWorkflowServiceConfig{
			URI: server.Addr,
			Headers: map[string]string{
				"Authorization":        "Bearer test-token",
				"x-gitlab-oauth-token": "oauth-token-123",
			},
			Secure: false,
		},
		LockConcurrentFlow: true,
	}

	runner, err := newRunner(mockConn, apiClient, http.HandlerFunc(func(_ http.ResponseWriter, _ *http.Request) {}), "", req, cfg, initRdb(t))

	require.NoError(t, err)
	require.NotNil(t, runner)
	require.Equal(t, "oauth-token-123", runner.httpActionHandler.token)
	require.Equal(t, req, runner.originalReq)
	require.Equal(t, mockConn, runner.ws.conn)
	require.NotNil(t, runner.streamManager)

	runner.Close()
}

func Test_newRunner_WithServerCapabilities(t *testing.T) {
	server := setupTestServer(t)
	mockConn := &mockWebSocketConn{}

	apiServer := httptest.NewServer(http.HandlerFunc(func(w http.ResponseWriter, _ *http.Request) {
		w.Header().Set("Content-Type", api.ResponseContentType)
		w.WriteHeader(http.StatusOK)
	}))
	defer apiServer.Close()

	apiURL, err := url.Parse(apiServer.URL)
	require.NoError(t, err)

	apiClient := api.NewAPI(apiURL, "test-version", http.DefaultTransport)

	tests := []struct {
		name               string
		serverCapabilities []string
	}{
		{
			name:               "with capabilities",
			serverCapabilities: []string{"advanced_search"},
		},
		{
			name:               "without capabilities",
			serverCapabilities: []string{},
		},
	}

	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			req := httptest.NewRequest("GET", "/duo", nil)
			cfg := &api.DuoWorkflow{
				Service: &api.DuoWorkflowServiceConfig{
					URI:     server.Addr,
					Headers: map[string]string{},
					Secure:  false,
				},
				ServerCapabilities: tt.serverCapabilities,
				LockConcurrentFlow: false,
			}

			runner, err := newRunner(mockConn, apiClient, http.HandlerFunc(func(_ http.ResponseWriter, _ *http.Request) {}), "", req, cfg, nil)

			require.NoError(t, err)
			require.Equal(t, tt.serverCapabilities, runner.serverCapabilities)

			runner.Close()
		})
	}
}

func Test_newRunner_WithoutRedis(t *testing.T) {
	server := setupTestServer(t)
	mockConn := &mockWebSocketConn{}

	apiServer := httptest.NewServer(http.HandlerFunc(func(w http.ResponseWriter, _ *http.Request) {
		w.Header().Set("Content-Type", api.ResponseContentType)
		w.WriteHeader(http.StatusOK)
	}))
	defer apiServer.Close()

	apiURL, err := url.Parse(apiServer.URL)
	require.NoError(t, err)

	apiClient := api.NewAPI(apiURL, "test-version", http.DefaultTransport)

	req := httptest.NewRequest("GET", "/duo", nil)
	cfg := &api.DuoWorkflow{
		Service: &api.DuoWorkflowServiceConfig{
			URI:     server.Addr,
			Headers: map[string]string{},
			Secure:  false,
		},
		LockConcurrentFlow: true,
	}

	runner, err := newRunner(mockConn, apiClient, http.HandlerFunc(func(_ http.ResponseWriter, _ *http.Request) {}), "", req, cfg, nil)

	require.NoError(t, err)
	require.False(t, runner.lockFlow)
	require.Nil(t, runner.lockManager)

	runner.Close()
}

func Test_newRunner_WithCloudConnector(t *testing.T) {
	server := setupTestServer(t)
	mockConn := &mockWebSocketConn{}

	apiServer := httptest.NewServer(http.HandlerFunc(func(w http.ResponseWriter, _ *http.Request) {
		w.Header().Set("Content-Type", api.ResponseContentType)
		w.WriteHeader(http.StatusOK)
	}))
	defer apiServer.Close()

	apiURL, err := url.Parse(apiServer.URL)
	require.NoError(t, err)

	apiClient := api.NewAPI(apiURL, "test-version", http.DefaultTransport)

	req := httptest.NewRequest("GET", "/duo", nil)
	cfg := &api.DuoWorkflow{
		Service: &api.DuoWorkflowServiceConfig{
			URI:     server.Addr,
			Headers: map[string]string{},
			Secure:  false,
		},
		CloudServiceForSelfHosted: &api.DuoWorkflowServiceConfig{
			URI:     server.Addr,
			Headers: map[string]string{"Authorization": "Bearer cloud-token"},
			Secure:  false,
		},
		LockConcurrentFlow: false,
	}

	runner, err := newRunner(mockConn, apiClient, http.HandlerFunc(func(_ http.ResponseWriter, _ *http.Request) {}), "", req, cfg, nil)

	require.NoError(t, err)
	require.NotNil(t, runner.streamManager.cloudServiceClient)
	require.NotNil(t, runner.streamManager.cloudServiceStream)

	runner.Close()
}

func Test_newRunner_WithoutCloudConnector(t *testing.T) {
	server := setupTestServer(t)
	mockConn := &mockWebSocketConn{}

	apiServer := httptest.NewServer(http.HandlerFunc(func(w http.ResponseWriter, _ *http.Request) {
		w.Header().Set("Content-Type", api.ResponseContentType)
		w.WriteHeader(http.StatusOK)
	}))
	defer apiServer.Close()

	apiURL, err := url.Parse(apiServer.URL)
	require.NoError(t, err)

	apiClient := api.NewAPI(apiURL, "test-version", http.DefaultTransport)

	req := httptest.NewRequest("GET", "/duo", nil)
	cfg := &api.DuoWorkflow{
		Service: &api.DuoWorkflowServiceConfig{
			URI:     server.Addr,
			Headers: map[string]string{},
			Secure:  false,
		},
		CloudServiceForSelfHosted: nil,
		LockConcurrentFlow:        false,
	}

	runner, err := newRunner(mockConn, apiClient, http.HandlerFunc(func(_ http.ResponseWriter, _ *http.Request) {}), "", req, cfg, nil)

	require.NoError(t, err)
	require.Nil(t, runner.streamManager.cloudServiceClient)
	require.Nil(t, runner.streamManager.cloudServiceStream)

	runner.Close()
}

func TestRunner_Execute(t *testing.T) {
	tests := []struct {
		name            string
		wsMessages      [][]byte
		recvActions     []*pb.Action
		writeMsgCount   int
		sendEventsCount int
		expectedErrMsg  string
		wsBlockCh       chan bool
		wfBlockCh       chan bool
	}{
		{
			name:            "ws messages",
			wsMessages:      [][]byte{[]byte(`{"type": "test"}`), []byte(`{"type": "test2"}`)},
			wfBlockCh:       make(chan bool),
			sendEventsCount: 2,
			expectedErrMsg:  "handleWebSocketMessages: failed to read a WS message: EOF",
		},
		{
			name: "wf actions",
			recvActions: []*pb.Action{{
				Action: &pb.Action_RunCommand{
					RunCommand: &pb.RunCommandAction{
						Program: "ls",
					},
				},
			}, {
				Action: &pb.Action_RunCommand{
					RunCommand: &pb.RunCommandAction{
						Program: "ls",
					},
				},
			}},
			writeMsgCount:  2,
			wsBlockCh:      make(chan bool),
			expectedErrMsg: "",
		},
	}

	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			mockConn := &mockWebSocketConn{
				readMessages: tt.wsMessages,
				blockCh:      tt.wsBlockCh,
			}
			mockWf := &mockWorkflowStream{
				recvActions: tt.recvActions,
				blockCh:     tt.wfBlockCh,
			}

			req := httptest.NewRequest("GET", "/duo", nil)
			r := &runner{
				originalReq: req,
				ws:          newWsManager(mockConn),
				httpActionHandler: &runHTTPActionHandler{
					backend:     http.HandlerFunc(func(_ http.ResponseWriter, _ *http.Request) {}),
					token:       "test-token",
					originalReq: req,
				},
				streamManager: &streamManager{
					wf:          mockWf,
					originalReq: req,
				},
			}

			ctx := context.Background()
			err := r.Execute(ctx)

			if tt.expectedErrMsg != "" {
				require.EqualError(t, err, tt.expectedErrMsg)
			} else {
				require.NoError(t, err)
			}

			require.Len(t, mockWf.getSendEvents(), tt.sendEventsCount)
			require.Len(t, mockConn.writeMessages, tt.writeMsgCount)
		})
	}
}

func TestRunner_Execute_with_errors(t *testing.T) {
	tests := []struct {
		name           string
		wsReadError    error
		wfRecvError    error
		expectedErrMsg string
		wsBlockCh      chan bool
		wfBlockCh      chan bool
	}{
		{
			name:           "websocket read error",
			wsReadError:    errors.New("read error"),
			wfBlockCh:      make(chan bool),
			expectedErrMsg: "handleWebSocketMessages: failed to read a WS message: read error",
		},
		{
			name:           "workflow recv error",
			wfRecvError:    errors.New("recv error"),
			wsBlockCh:      make(chan bool),
			expectedErrMsg: "handleAgentMessages: failed to read a gRPC message: recv error",
		},
		{
			name:           "workflow EOF error",
			wfRecvError:    io.EOF,
			wsBlockCh:      make(chan bool),
			expectedErrMsg: "",
		},
		{
			name:           "workflow usage quota exceeded error",
			wfRecvError:    status.Error(codes.ResourceExhausted, "USAGE_QUOTA_EXCEEDED: consumer has exceeded their quota"),
			wsBlockCh:      make(chan bool),
			expectedErrMsg: "handleAgentMessages: usage quota exceeded",
		},
	}

	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			mockConn := &mockWebSocketConn{
				readError: tt.wsReadError,
				blockCh:   tt.wsBlockCh,
			}
			mockWf := &mockWorkflowStream{
				recvError: tt.wfRecvError,
				blockCh:   tt.wfBlockCh,
			}

			r := &runner{
				ws: newWsManager(mockConn),
				streamManager: &streamManager{
					wf: mockWf,
				},
			}
			err := r.Execute(context.Background())

			if tt.expectedErrMsg != "" {
				require.EqualError(t, err, tt.expectedErrMsg)
			} else {
				require.NoError(t, err)
			}
		})
	}
}

// timeoutError implements net.Error with Timeout() returning true,
// simulating the i/o timeout produced when a WebSocket pong deadline expires.
type timeoutError struct{}

func (e *timeoutError) Error() string   { return "i/o timeout" }
func (e *timeoutError) Timeout() bool   { return true }
func (e *timeoutError) Temporary() bool { return false }

func TestRunner_Execute_with_close_errors(t *testing.T) {
	tests := []struct {
		name           string
		wsReadError    error
		expectedReason string
	}{
		{
			name:           "websocket normal closure",
			wsReadError:    &websocket.CloseError{Code: websocket.CloseNormalClosure},
			expectedReason: "WORKHORSE_WEBSOCKET_CLOSE_1000",
		},
		{
			name:           "websocket going away",
			wsReadError:    &websocket.CloseError{Code: websocket.CloseGoingAway},
			expectedReason: "WORKHORSE_WEBSOCKET_CLOSE_1001",
		},
		{
			name:           "websocket pong timeout",
			wsReadError:    &timeoutError{},
			expectedReason: "WORKHORSE_WEBSOCKET_PONG_TIMEOUT",
		},
	}

	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			blockCh := make(chan bool)
			mockConn := &mockWebSocketConn{
				readError: tt.wsReadError,
			}
			mockWf := &mockWorkflowStream{
				recvError: io.EOF,
				blockCh:   blockCh,
			}

			req := httptest.NewRequest("GET", "/duo", nil)
			stopAcked := make(chan struct{})
			r := &runner{
				ws:          newWsManager(mockConn),
				originalReq: req,
				streamManager: &streamManager{
					wf:          mockWf,
					originalReq: req,
				},
				stop: stopCoordinator{
					acked: stopAcked,
				},
			}

			errCh := make(chan error, 1)
			go func() { errCh <- r.Execute(context.Background()) }()

			require.Eventually(t, func() bool {
				return len(mockWf.getSendEvents()) == 1
			}, 2*time.Second, 50*time.Millisecond)

			require.True(t, r.ws.closed.Load())

			// Simulate DWS acknowledging the stop request
			close(stopAcked)
			blockCh <- true // Unblock WF stream
			require.NoError(t, <-errCh)

			stopEvent := mockWf.getSendEvents()[0].GetStopWorkflow()
			require.NotNil(t, stopEvent)
			require.Equal(t, tt.expectedReason, stopEvent.Reason)
		})
	}
}

func TestRunner_handleWebSocketMessage(t *testing.T) {
	tests := []struct {
		name               string
		message            []byte
		clientCapabilities []string
		serverCapabilities []string
		sendError          error
		mcpManager         *mockMcpManager
		expectedErrMsg     string
		expectMcpTools     bool
	}{
		{
			name:           "send error",
			message:        []byte(`{"type": "test"}`),
			sendError:      errors.New("send error"),
			expectedErrMsg: "handleWebSocketMessage: failed to write a gRPC message: send error",
		},
		{
			name:           "send EOF error",
			message:        []byte(`{"type": "test"}`),
			sendError:      io.EOF,
			expectedErrMsg: "",
		},
		{
			name:           "successful message handling",
			message:        []byte(`{"type": "test"}`),
			expectedErrMsg: "",
		},
		{
			name:               "start request with mcp tools",
			message:            []byte(`{"startRequest": {"workflowID": "id-123", "goal": "test goal", "mcpTools": [{"name": "get_issue"}]}}`),
			clientCapabilities: []string{},
			mcpManager: &mockMcpManager{
				tools: []*pb.McpTool{
					{Name: "test_tool", Description: "A test tool"},
				},
			},
			expectMcpTools: true,
			expectedErrMsg: "",
		},
		{
			name:               "start request without mcp manager",
			message:            []byte(`{"startRequest": {"workflowID": "id-123", "goal": "test goal"}}`),
			clientCapabilities: []string{},
			mcpManager:         nil,
			expectMcpTools:     false,
			expectedErrMsg:     "",
		},
		{
			name:               "start request with supported and unsupported ClientCapabilities",
			message:            []byte(`{"startRequest": {"workflowID": "id-123", "goal": "test goal", "clientCapabilities": ["shell_command", "incremental_streaming", "read_file_chunked", "command_timeout", "unsupported_capability"]}}`),
			clientCapabilities: []string{"shell_command", "incremental_streaming", "read_file_chunked", "command_timeout"},
			expectedErrMsg:     "",
		},
		{
			name:               "start request with server capabilities",
			message:            []byte(`{"startRequest": {"workflowID": "id-123", "goal": "test goal", "clientCapabilities": ["shell_command", "read_file_chunked", "command_timeout"]}}`),
			clientCapabilities: []string{"shell_command", "read_file_chunked", "command_timeout", "advanced_search"},
			serverCapabilities: []string{"advanced_search"},
			expectedErrMsg:     "",
		},
		{
			name:               "start request without server capabilities",
			message:            []byte(`{"startRequest": {"workflowID": "id-123", "goal": "test goal", "clientCapabilities": ["shell_command", "read_file_chunked", "command_timeout"]}}`),
			clientCapabilities: []string{"shell_command", "read_file_chunked", "command_timeout"},
			serverCapabilities: []string{},
			expectedErrMsg:     "",
		},
		{
			name:               "start request with tool_call_approval server capability",
			message:            []byte(`{"startRequest": {"workflowID": "id-123", "goal": "test goal", "clientCapabilities": []}}`),
			clientCapabilities: []string{"tool_call_approval"},
			serverCapabilities: []string{"tool_call_approval"},
			expectedErrMsg:     "",
		},
		{
			name:               "start request with multiple server capabilities including tool_call_approval",
			message:            []byte(`{"startRequest": {"workflowID": "id-123", "goal": "test goal", "clientCapabilities": ["shell_command"]}}`),
			clientCapabilities: []string{"shell_command", "advanced_search", "tool_call_approval"},
			serverCapabilities: []string{"advanced_search", "tool_call_approval"},
			expectedErrMsg:     "",
		},
		{
			name:               "start request with web_search client capability",
			message:            []byte(`{"startRequest": {"workflowID": "id-123", "goal": "test goal", "clientCapabilities": ["web_search"]}}`),
			clientCapabilities: []string{"web_search"},
			expectedErrMsg:     "",
		},
		{
			name:               "start request with web_search and other client capabilities",
			message:            []byte(`{"startRequest": {"workflowID": "id-123", "goal": "test goal", "clientCapabilities": ["shell_command", "web_search"]}}`),
			clientCapabilities: []string{"shell_command", "web_search"},
			expectedErrMsg:     "",
		},
		{
			name:               "start request with unknown web_search variant is filtered out",
			message:            []byte(`{"startRequest": {"workflowID": "id-123", "goal": "test goal", "clientCapabilities": ["web_search_unknown"]}}`),
			clientCapabilities: []string{},
			expectedErrMsg:     "",
		},
	}

	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			mockWf := &mockWorkflowStream{
				sendError: tt.sendError,
			}

			rdb := initRdb(t)

			req := httptest.NewRequest("GET", "/duo", nil)
			r := &runner{
				originalReq: req,
				ws:          newWsManager(&mockWebSocketConn{}),
				httpActionHandler: &runHTTPActionHandler{
					backend:     http.HandlerFunc(func(_ http.ResponseWriter, _ *http.Request) {}),
					token:       "test-token",
					originalReq: req,
				},
				streamManager: &streamManager{
					wf:          mockWf,
					originalReq: req,
				},
				mcpManager:         tt.mcpManager,
				lockManager:        newWorkflowLockManager(rdb),
				serverCapabilities: tt.serverCapabilities,
			}

			event := &pb.ClientEvent{}
			require.NoError(t, unmarshaler.Unmarshal(tt.message, event))

			err := r.handleWebSocketMessage(event)

			if tt.expectedErrMsg != "" {
				require.Error(t, err)
				require.Contains(t, err.Error(), tt.expectedErrMsg)
			} else {
				require.NoError(t, err)

				if tt.expectMcpTools {
					require.Len(t, mockWf.sendEvents, 1)
					startReq := mockWf.sendEvents[0].GetStartRequest()
					require.NotNil(t, startReq)
					require.Len(t, startReq.McpTools, 2)
					assert.Equal(t, "get_issue", startReq.McpTools[0].Name)
					assert.Equal(t, "test_tool", startReq.McpTools[1].Name)
					assert.Equal(t, "A test tool", startReq.McpTools[1].Description)
				}

				if tt.clientCapabilities != nil {
					require.Len(t, mockWf.sendEvents, 1)
					startReq := mockWf.sendEvents[0].GetStartRequest()
					require.NotNil(t, startReq)
					assert.ElementsMatch(t, tt.clientCapabilities, startReq.ClientCapabilities)
				}

				if tt.mcpManager != nil {
					require.Len(t, tt.mcpManager.setWorkflowIDCalls, 1)
					assert.Equal(t, "id-123", tt.mcpManager.setWorkflowIDCalls[0])
				}
			}
		})
	}
}

func TestRunner_handleAgentAction(t *testing.T) {
	tests := []struct {
		name           string
		action         *pb.Action
		wsWriteError   error
		wfSendError    error
		mcpManager     *mockMcpManager
		expectedErrMsg string
		shouldCallWS   bool
		shouldCallWF   bool
		shouldCallMcp  bool
	}{
		{
			name: "successful HTTP request action",
			action: &pb.Action{
				RequestID: "req-123",
				Action: &pb.Action_RunHTTPRequest{
					RunHTTPRequest: &pb.RunHTTPRequest{
						Method: "GET",
						Path:   "/api/test",
					},
				},
			},
			shouldCallWF: true,
		},
		{
			name: "HTTP request action with workflow send error",
			action: &pb.Action{
				RequestID: "req-456",
				Action: &pb.Action_RunHTTPRequest{
					RunHTTPRequest: &pb.RunHTTPRequest{
						Method: "GET",
						Path:   "/api/test",
					},
				},
			},
			wfSendError:    errors.New("workflow send failed"),
			expectedErrMsg: "handleAgentAction: failed to send gRPC message: workflow send failed",
		},
		{
			name: "successful non-HTTP action forwarded to websocket",
			action: &pb.Action{
				RequestID: "req-789",
				Action: &pb.Action_RunCommand{
					RunCommand: &pb.RunCommandAction{
						Program: "ls",
					},
				},
			},
			shouldCallWS: true,
		},
		{
			name: "non-HTTP action with websocket write error",
			action: &pb.Action{
				RequestID: "req-error",
				Action: &pb.Action_RunCommand{
					RunCommand: &pb.RunCommandAction{
						Program: "ls",
					},
				},
			},
			wsWriteError:   errors.New("websocket write failed"),
			expectedErrMsg: "WriteAction: failed to send WS message: websocket write failed",
		},
		{
			name: "non-HTTP action with websocket write close sent error",
			action: &pb.Action{
				RequestID: "req-error",
				Action: &pb.Action_RunCommand{
					RunCommand: &pb.RunCommandAction{
						Program: "ls",
					},
				},
			},
			wsWriteError: websocket.ErrCloseSent,
		},
		{
			name: "action with nil action type",
			action: &pb.Action{
				RequestID: "req-nil",
				Action:    nil,
			},
			shouldCallWS: true,
		},
		{
			name: "MCP tool action with mcp manager",
			action: &pb.Action{
				RequestID: "req-mcp-123",
				Action: &pb.Action_RunMCPTool{
					RunMCPTool: &pb.RunMCPTool{
						Name: "gitlab_get_issue",
						Args: `{"issue_id": "123"}`,
					},
				},
			},
			mcpManager: &mockMcpManager{
				hasToolResult: true,
				callToolResult: &pb.ClientEvent{
					Response: &pb.ClientEvent_ActionResponse{
						ActionResponse: &pb.ActionResponse{
							ResponseType: &pb.ActionResponse_PlainTextResponse{
								PlainTextResponse: &pb.PlainTextResponse{
									Response: `{"id": 123, "title": "Test Issue"}`,
								},
							},
						},
					},
				},
			},
			shouldCallMcp: true,
			shouldCallWF:  true,
		},
		{
			name: "MCP tool action without mcp manager",
			action: &pb.Action{
				RequestID: "req-mcp-no-manager",
				Action: &pb.Action_RunMCPTool{
					RunMCPTool: &pb.RunMCPTool{
						Name: "gitlab_get_issue",
						Args: `{"issue_id": "123"}`,
					},
				},
			},
			mcpManager:   nil,
			shouldCallWS: true,
		},
		{
			name: "MCP tool action with tool not recognized",
			action: &pb.Action{
				RequestID: "req-mcp-unknown",
				Action: &pb.Action_RunMCPTool{
					RunMCPTool: &pb.RunMCPTool{
						Name: "unknown_tool",
						Args: `{"param": "value"}`,
					},
				},
			},
			mcpManager: &mockMcpManager{
				hasToolResult: false,
			},
			shouldCallWS: true,
		},
		{
			name: "MCP tool action with call error",
			action: &pb.Action{
				RequestID: "req-mcp-error",
				Action: &pb.Action_RunMCPTool{
					RunMCPTool: &pb.RunMCPTool{
						Name: "gitlab_get_issue",
						Args: `{"issue_id": "123"}`,
					},
				},
			},
			mcpManager: &mockMcpManager{
				hasToolResult: true,
				callToolError: errors.New("mcp call failed"),
			},
			shouldCallMcp:  true,
			expectedErrMsg: "handleAgentAction: failed to call MCP tool: mcp call failed",
		},
	}

	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			server := httptest.NewServer(http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
				assert.Equal(t, "/api/test", r.URL.Path)
				assert.Equal(t, "GET", r.Method)

				w.WriteHeader(http.StatusOK)
				fmt.Fprint(w, `[{"id": 123, "name": "test-project"}]`)
			}))
			defer server.Close()

			mockConn := &mockWebSocketConn{
				writeError: tt.wsWriteError,
			}
			mockWf := &mockWorkflowStream{
				sendError: tt.wfSendError,
			}

			req := httptest.NewRequest("GET", "/duo", nil)
			r := &runner{
				originalReq: req,
				ws:          newWsManager(mockConn),
				httpActionHandler: &runHTTPActionHandler{
					backend:     createBackendHandler(server.Client(), server.Listener.Addr().String()),
					token:       "test-token",
					originalReq: req,
				},
				streamManager: &streamManager{
					wf:          mockWf,
					originalReq: req,
				},
				mcpManager: tt.mcpManager,
			}

			ctx := context.Background()
			err := r.handleAgentAction(ctx, tt.action)

			if tt.expectedErrMsg != "" {
				require.EqualError(t, err, tt.expectedErrMsg)
			} else {
				require.NoError(t, err)
			}

			if tt.shouldCallWS {
				require.Len(t, mockConn.writeMessages, 1, "Expected one WebSocket message to be written")
			} else {
				require.Empty(t, mockConn.writeMessages)
			}

			sendEvents := mockWf.getSendEvents()
			if tt.shouldCallWF {
				require.Len(t, sendEvents, 1, "Expected one workflow event to be sent")

				if tt.action.GetRunHTTPRequest() != nil {
					response := mockWf.sendEvents[0].Response.(*pb.ClientEvent_ActionResponse).ActionResponse
					responseBody := response.ResponseType.(*pb.ActionResponse_HttpResponse).HttpResponse.Body
					require.JSONEq(t, `[{"id": 123, "name": "test-project"}]`, responseBody)
				}
			} else {
				require.Empty(t, sendEvents)
			}

			if tt.shouldCallMcp {
				require.Len(t, tt.mcpManager.callToolInvocations, 1, "Expected MCP tool to be called")
				mcpAction := tt.action.GetRunMCPTool()
				require.Equal(t, mcpAction.Name, tt.mcpManager.callToolInvocations[0].name)
				require.Equal(t, mcpAction.Args, tt.mcpManager.callToolInvocations[0].args)
			}
		})
	}
}

func TestRunner_Close_WithCloudConnector(t *testing.T) {
	t.Run("successful close with cloud service", func(t *testing.T) {
		server := setupTestServer(t)

		// Create real clients to test the full close flow
		mainClient, err := NewClient(&api.DuoWorkflowServiceConfig{
			URI:     server.Addr,
			Headers: map[string]string{},
			Secure:  false,
		}, "test-agent", "")
		require.NoError(t, err)

		cloudClient, err := NewClient(&api.DuoWorkflowServiceConfig{
			URI:     server.Addr,
			Headers: map[string]string{},
			Secure:  false,
		}, "test-agent", "")
		require.NoError(t, err)

		mockConn := &mockWebSocketConn{}
		mockWf := &mockWorkflowStream{}
		mockCloudStream := &mockSelfHostedWorkflowStream{}

		r := &runner{
			ws: newWsManager(mockConn),
			streamManager: &streamManager{
				wf:                 mockWf,
				client:             mainClient,
				cloudServiceStream: mockCloudStream,
				cloudServiceClient: cloudClient,
			},
			mcpManager: &mockMcpManager{},
		}

		err = r.Close()
		require.NoError(t, err)
	})

	t.Run("close without cloud service", func(t *testing.T) {
		server := setupTestServer(t)

		mainClient, err := NewClient(&api.DuoWorkflowServiceConfig{
			URI:     server.Addr,
			Headers: map[string]string{},
			Secure:  false,
		}, "test-agent", "")
		require.NoError(t, err)

		mockConn := &mockWebSocketConn{}
		mockWf := &mockWorkflowStream{}

		r := &runner{
			ws: newWsManager(mockConn),
			streamManager: &streamManager{
				wf:                 mockWf,
				client:             mainClient,
				cloudServiceStream: nil,
				cloudServiceClient: nil,
			},
			mcpManager: &mockMcpManager{},
		}

		err = r.Close()
		require.NoError(t, err)
	})

	t.Run("close with only cloud service stream", func(t *testing.T) {
		server := setupTestServer(t)

		mainClient, err := NewClient(&api.DuoWorkflowServiceConfig{
			URI:     server.Addr,
			Headers: map[string]string{},
			Secure:  false,
		}, "test-agent", "")
		require.NoError(t, err)

		mockConn := &mockWebSocketConn{}
		mockWf := &mockWorkflowStream{}
		mockCloudStream := &mockSelfHostedWorkflowStream{}

		r := &runner{
			ws: newWsManager(mockConn),
			streamManager: &streamManager{
				wf:                 mockWf,
				client:             mainClient,
				cloudServiceStream: mockCloudStream,
				cloudServiceClient: nil,
			},
			mcpManager: &mockMcpManager{},
		}

		err = r.Close()
		require.NoError(t, err)
	})
}

func Test_intersectServerCapabilities(t *testing.T) {
	tests := []struct {
		name       string
		fromServer []string
		expected   []string
	}{
		{
			name:       "filters to whitelisted capabilities",
			fromServer: []string{"advanced_search", "unknown_capability"},
			expected:   []string{"advanced_search"},
		},
		{
			name:       "returns empty when no matches",
			fromServer: []string{"unknown_capability", "another_unknown"},
			expected:   []string{},
		},
		{
			name:       "empty input returns empty",
			fromServer: []string{},
			expected:   []string{},
		},
		{
			name:       "nil input returns empty",
			fromServer: nil,
			expected:   []string{},
		},
		{
			name:       "all allowlisted capabilities pass through",
			fromServer: []string{"advanced_search", "tool_call_approval", "tool_call_pattern_approval", "job_trace_pagination"},
			expected:   []string{"advanced_search", "tool_call_approval", "tool_call_pattern_approval", "job_trace_pagination"},
		},
		{
			name:       "incremental_checkpoints server capability passes through",
			fromServer: []string{"incremental_checkpoints"},
			expected:   []string{"incremental_checkpoints"},
		},
	}

	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			result := intersectServerCapabilities(tt.fromServer)
			assert.Equal(t, tt.expected, result)
		})
	}
}

func Test_intersectClientCapabilities(t *testing.T) {
	tests := []struct {
		name       string
		fromClient []string
		expected   []string
	}{
		{
			name:       "returns empty when no matches",
			fromClient: []string{"unknown_capability"},
			expected:   []string{},
		},
		{
			name:       "empty input returns empty",
			fromClient: []string{},
			expected:   []string{},
		},
		{
			name:       "nil input returns empty",
			fromClient: nil,
			expected:   []string{},
		},
		{
			name:       "web_search capability passes through",
			fromClient: []string{"web_search"},
			expected:   []string{"web_search"},
		},
		{
			name:       "web_search combined with other capabilities",
			fromClient: []string{"shell_command", "web_search"},
			expected:   []string{"shell_command", "web_search"},
		},
		{
			name:       "unknown web_search variant is filtered out",
			fromClient: []string{"web_search_unknown"},
			expected:   []string{},
		},
	}

	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			result := intersectClientCapabilities(tt.fromClient)
			assert.Equal(t, tt.expected, result)
		})
	}
}

func TestRunner_Shutdown(t *testing.T) {
	t.Run("waits for context then sends stop and releases lock on ack", func(t *testing.T) {
		rdb := initRdb(t)
		mockWf := &mockWorkflowStream{}
		mockConn := &mockWebSocketConn{}
		ctx, cancel := context.WithCancel(context.Background())
		defer cancel()
		req := httptest.NewRequest("GET", "/duo", nil)
		req = req.WithContext(ctx)

		r := &runner{
			originalReq: req,
			ws:          newWsManager(mockConn),
			lockFlow:    true,
			streamManager: &streamManager{
				wf:          mockWf,
				originalReq: req,
			},
			lockManager: newWorkflowLockManager(rdb),
			workflowID:  "shutdown-lock-test-234",
			stop: stopCoordinator{
				acked: make(chan struct{}),
			},
		}

		// Pre-acquire the lock so we can verify it gets released
		mutex, err := r.lockManager.acquireLock(context.Background(), r.workflowID)
		require.NoError(t, err)
		r.mutex = mutex

		shutdownDone := make(chan error, 1)
		shutdownCtx, shutdownCancel := context.WithCancel(context.Background())
		defer shutdownCancel()

		go func() {
			shutdownDone <- r.Shutdown(shutdownCtx)
		}()

		// Verify Shutdown blocks while contexts are alive
		select {
		case <-shutdownDone:
			t.Fatal("Shutdown should not return before a context expires")
		case <-time.After(50 * time.Millisecond):
			// expected: still waiting
		}

		// Cancel the shutdown context to unblock
		shutdownCancel()

		require.Eventually(t, func() bool {
			return len(mockWf.getSendEvents()) > 0
		}, 100*time.Millisecond, 10*time.Millisecond)

		// Simulate DWS acknowledging the stop
		close(r.stop.acked)

		err = <-shutdownDone
		require.NoError(t, err)

		sendEvents := mockWf.getSendEvents()
		require.Len(t, sendEvents, 1)
		stopEvent := sendEvents[0].GetStopWorkflow()
		require.NotNil(t, stopEvent)
		require.Equal(t, "WORKHORSE_SERVER_SHUTDOWN", stopEvent.Reason)

		// Verify the lock was released: acquiring it again should succeed
		newMutex, lockErr := r.lockManager.acquireLock(context.Background(), r.workflowID)
		require.NoError(t, lockErr)
		require.NotNil(t, newMutex)
		r.lockManager.releaseLock(context.Background(), newMutex, r.workflowID)
	})

	t.Run("sends CloseGoingAway to websocket when shutdown context fires", func(t *testing.T) {
		mockWf := &mockWorkflowStream{}
		controlMessages := []struct {
			msgType int
			data    []byte
		}{}
		mockConn := &mockWebSocketConn{}
		wrappedConn := &shutdownTrackingConn{
			mockWebSocketConn: mockConn,
			controlMessages:   &controlMessages,
		}

		// Use a live request context so the shutdown context fires first (not the request context).
		req := httptest.NewRequest("GET", "/duo", nil)

		stopAcked := make(chan struct{})
		r := &runner{
			originalReq: req,
			ws:          newWsManager(wrappedConn),
			streamManager: &streamManager{
				wf:          mockWf,
				originalReq: req,
			},
			stop: stopCoordinator{
				acked: stopAcked,
			},
		}

		go func() {
			for len(mockWf.getSendEvents()) == 0 {
				time.Sleep(5 * time.Millisecond)
			}
			close(stopAcked)
		}()

		// Cancel the shutdown context immediately so it fires first.
		shutdownCtx, shutdownCancel := context.WithCancel(context.Background())
		shutdownCancel()
		err := r.Shutdown(shutdownCtx)
		require.NoError(t, err)

		// Verify a CloseGoingAway frame was sent
		require.Len(t, controlMessages, 1)
		require.Equal(t, websocket.CloseMessage, controlMessages[0].msgType)
		expectedMsg := websocket.FormatCloseMessage(websocket.CloseGoingAway, "server shutdown")
		require.Equal(t, expectedMsg, controlMessages[0].data)
	})

	t.Run("skips CloseGoingAway when request context fires first", func(t *testing.T) {
		mockWf := &mockWorkflowStream{}
		controlMessages := []struct {
			msgType int
			data    []byte
		}{}
		mockConn := &mockWebSocketConn{}
		wrappedConn := &shutdownTrackingConn{
			mockWebSocketConn: mockConn,
			controlMessages:   &controlMessages,
		}

		ctx, cancel := context.WithCancel(context.Background())
		cancel() // cancel immediately so originalReq context is already done
		req := httptest.NewRequest("GET", "/duo", nil)
		req = req.WithContext(ctx)

		stopAcked := make(chan struct{})
		r := &runner{
			originalReq: req,
			ws:          newWsManager(wrappedConn),
			streamManager: &streamManager{
				wf:          mockWf,
				originalReq: req,
			},
			stopWorkflowTimeout: 10 * time.Millisecond,
			stop: stopCoordinator{
				acked: stopAcked,
			},
		}

		// Use a live shutdown context so only the request context fires.
		err := r.Shutdown(context.Background())
		require.NoError(t, err)

		// CloseGoingAway must NOT be sent when the request context fired first.
		require.Empty(t, controlMessages, "CloseGoingAway should not be sent when request context is done")
	})

	t.Run("returns nil even when stop times out", func(t *testing.T) {
		mockWf := &mockWorkflowStream{}
		mockConn := &mockWebSocketConn{}

		ctx, cancel := context.WithCancel(context.Background())
		cancel() // cancel immediately to unblock the select
		req := httptest.NewRequest("GET", "/duo", nil)
		req = req.WithContext(ctx)

		r := &runner{
			originalReq: req,
			ws:          newWsManager(mockConn),
			streamManager: &streamManager{
				wf:          mockWf,
				originalReq: req,
			},
			stopWorkflowTimeout: 10 * time.Millisecond,
			stop: stopCoordinator{
				acked: make(chan struct{}), // never closed = timeout
			},
		}

		err := r.Shutdown(context.Background())
		require.NoError(t, err, "Shutdown should always return nil")
	})

	t.Run("releases lock even when stop fails", func(t *testing.T) {
		rdb := initRdb(t)
		mockWf := &mockWorkflowStream{}
		mockConn := &mockWebSocketConn{}

		ctx, cancel := context.WithCancel(context.Background())
		cancel() // cancel immediately to unblock the select
		req := httptest.NewRequest("GET", "/duo", nil)
		req = req.WithContext(ctx)

		r := &runner{
			originalReq: req,
			ws:          newWsManager(mockConn),
			lockFlow:    true,
			streamManager: &streamManager{
				wf:          mockWf,
				originalReq: req,
			},
			lockManager:         newWorkflowLockManager(rdb),
			workflowID:          "shutdown-no-release-test",
			stopWorkflowTimeout: 10 * time.Millisecond,
			stop: stopCoordinator{
				acked: make(chan struct{}), // never closed = timeout
			},
		}

		// Pre-acquire the lock
		mutex, err := r.lockManager.acquireLock(context.Background(), r.workflowID)
		require.NoError(t, err)
		r.mutex = mutex

		err = r.Shutdown(context.Background())
		require.NoError(t, err)

		// Lock should have been released even though stop timed out,
		// so the executor can reconnect to a new workhorse instance.
		newMutex, lockErr := r.lockManager.acquireLock(context.Background(), r.workflowID)
		require.NoError(t, lockErr, "lock should be released even when stop fails")
		r.lockManager.releaseLock(context.Background(), newMutex, r.workflowID)
	})
}

func TestRunner_stopWorkflow_returnsNilOnAck(t *testing.T) {
	mockWf := &mockWorkflowStream{}
	req := httptest.NewRequest("GET", "/duo", nil)

	r := &runner{
		originalReq: req,
		streamManager: &streamManager{
			wf:          mockWf,
			originalReq: req,
		},
		stop: stopCoordinator{
			acked: make(chan struct{}),
		},
	}

	// Simulate DWS ack arriving shortly after the stop request is sent
	go func() {
		for len(mockWf.getSendEvents()) == 0 {
			time.Sleep(10 * time.Millisecond)
		}
		close(r.stop.acked)
	}()

	err := r.stopWorkflow("TEST_REASON", fmt.Errorf("test close error"))
	require.NoError(t, err)
	require.True(t, r.stop.requested.Load(), "stopRequested should be set")

	sendEvents := mockWf.getSendEvents()
	require.Len(t, sendEvents, 1)
	stopEvent := sendEvents[0].GetStopWorkflow()
	require.NotNil(t, stopEvent)
	require.Equal(t, "TEST_REASON", stopEvent.Reason)
}

func TestRunner_handleAgentMessages_setsWorkflowEndedOnEOF(t *testing.T) {
	mockWf := &mockWorkflowStream{
		recvError: io.EOF,
	}
	req := httptest.NewRequest("GET", "/duo", nil)

	r := &runner{
		originalReq: req,
		streamManager: &streamManager{
			wf:          mockWf,
			originalReq: req,
		},
		stop: stopCoordinator{
			acked: make(chan struct{}),
		},
	}

	errCh := make(chan error, 1)
	r.handleAgentMessages(context.Background(), errCh)

	require.NoError(t, <-errCh)
	require.True(t, r.stop.workflowEnded.Load(), "workflowEnded should be set when DWS sends EOF")
}

func TestRunner_Shutdown_skipsStopAndCloseGoingAwayWhenWorkflowEnded(t *testing.T) {
	mockWf := &mockWorkflowStream{}
	controlMessages := []struct {
		msgType int
		data    []byte
	}{}
	mockConn := &mockWebSocketConn{}
	wrappedConn := &shutdownTrackingConn{
		mockWebSocketConn: mockConn,
		controlMessages:   &controlMessages,
	}

	req := httptest.NewRequest("GET", "/duo", nil)
	r := &runner{
		originalReq: req,
		ws:          newWsManager(wrappedConn),
		streamManager: &streamManager{
			wf:          mockWf,
			originalReq: req,
		},
		stop: stopCoordinator{
			acked:        make(chan struct{}),
			shutdownDone: make(chan struct{}),
		},
	}
	r.stop.workflowEnded.Store(true)

	shutdownCtx, shutdownCancel := context.WithCancel(context.Background())
	shutdownCancel() // fire immediately

	err := r.Shutdown(shutdownCtx)
	require.NoError(t, err)

	require.Empty(t, mockWf.getSendEvents(), "no StopWorkflowRequest should be sent when workflow already ended")
	require.Empty(t, controlMessages, "CloseGoingAway should not be sent when workflow already ended")
}

func TestRunner_handleAgentMessages_stopAck(t *testing.T) {
	t.Run("closes stop.acked when Unavailable received after stop requested", func(t *testing.T) {
		mockWf := &mockWorkflowStream{
			recvError: status.Error(codes.Unavailable, "service unavailable"),
		}
		req := httptest.NewRequest("GET", "/duo", nil)

		r := &runner{
			originalReq: req,
			streamManager: &streamManager{
				wf:          mockWf,
				originalReq: req,
			},
			stop: stopCoordinator{
				acked: make(chan struct{}),
			},
		}
		r.stop.requested.Store(true)

		errCh := make(chan error, 1)
		r.handleAgentMessages(context.Background(), errCh)

		err := <-errCh
		require.NoError(t, err, "should return nil when DWS acknowledges stop")

		// Verify stop.acked channel is closed
		select {
		case <-r.stop.acked:
			// expected: channel is closed
		default:
			t.Fatal("stop.acked channel should be closed")
		}
	})

	t.Run("returns error when Unavailable received without stop requested", func(t *testing.T) {
		mockWf := &mockWorkflowStream{
			recvError: status.Error(codes.Unavailable, "service unavailable"),
		}
		req := httptest.NewRequest("GET", "/duo", nil)

		r := &runner{
			originalReq: req,
			streamManager: &streamManager{
				wf:          mockWf,
				originalReq: req,
			},
			stop: stopCoordinator{
				acked: make(chan struct{}),
			},
		}
		// stop.requested is false by default

		errCh := make(chan error, 1)
		r.handleAgentMessages(context.Background(), errCh)

		err := <-errCh
		require.Error(t, err, "should return error when stop was not requested")
		require.Contains(t, err.Error(), "stream unavailable")
	})
}

func TestRunner_Execute_stopAckFromDWS(t *testing.T) {
	t.Run("websocket close triggers stop and DWS ack completes cleanly", func(t *testing.T) {
		acked := make(chan struct{})
		mockWf := &mockWorkflowStream{
			blockCh: make(chan bool, 1),
		}
		mockConn := &mockWebSocketConn{
			readError: &websocket.CloseError{Code: websocket.CloseNormalClosure},
		}

		req := httptest.NewRequest("GET", "/duo", nil)
		r := &runner{
			ws:          newWsManager(mockConn),
			originalReq: req,
			streamManager: &streamManager{
				wf:          mockWf,
				originalReq: req,
			},
			stop: stopCoordinator{
				acked: acked,
			},
		}

		errCh := make(chan error, 1)
		go func() { errCh <- r.Execute(context.Background()) }()

		// Wait for the stop request to be sent to DWS
		require.Eventually(t, func() bool {
			return len(mockWf.getSendEvents()) == 1
		}, 2*time.Second, 10*time.Millisecond)

		// Simulate DWS acknowledging the stop
		close(acked)
		// Unblock the agent messages goroutine
		mockWf.blockCh <- true

		err := <-errCh
		// stopWorkflow returns nil via acked, so handleWebSocketMessages sends nil error
		require.NoError(t, err)
	})
}

func TestRunner_Close_waitsForAgentDone(t *testing.T) {
	server := setupTestServer(t)

	mainClient, err := NewClient(&api.DuoWorkflowServiceConfig{
		URI:     server.Addr,
		Headers: map[string]string{},
		Secure:  false,
	}, "test-agent", "")
	require.NoError(t, err)

	mockWf := &mockWorkflowStream{}
	mockConn := &mockWebSocketConn{}

	r := &runner{
		ws: newWsManager(mockConn),
		streamManager: &streamManager{
			wf:     mockWf,
			client: mainClient,
		},
		mcpManager: &mockMcpManager{},
		stop: stopCoordinator{
			acked: make(chan struct{}),
		},
	}

	// Simulate an in-flight handleAgentMessages goroutine
	r.stop.agentDone.Add(1)

	closeDone := make(chan error, 1)
	go func() {
		closeDone <- r.Close()
	}()

	// Close should be blocked waiting for agentDone
	select {
	case <-closeDone:
		t.Fatal("Close should not return before agentDone is signaled")
	case <-time.After(100 * time.Millisecond):
		// expected: Close is still waiting
	}

	// Signal that handleAgentMessages has finished
	r.stop.agentDone.Done()

	select {
	case err := <-closeDone:
		require.NoError(t, err)
	case <-time.After(2 * time.Second):
		t.Fatal("Close should return after agentDone is signaled")
	}
}

func TestRunner_Close_shutdownCoordination(t *testing.T) {
	newRunnerForClose := func(t *testing.T) *runner {
		t.Helper()
		server := setupTestServer(t)

		mainClient, err := NewClient(&api.DuoWorkflowServiceConfig{
			URI:     server.Addr,
			Headers: map[string]string{},
			Secure:  false,
		}, "test-agent", "")
		require.NoError(t, err)

		return &runner{
			ws: newWsManager(&mockWebSocketConn{}),
			streamManager: &streamManager{
				wf:     &mockWorkflowStream{},
				client: mainClient,
			},
			mcpManager: &mockMcpManager{},
			stop: stopCoordinator{
				acked:        make(chan struct{}),
				shutdownDone: make(chan struct{}),
			},
		}
	}

	t.Run("returns without waiting for shutdownDone when no shutdown is in progress", func(t *testing.T) {
		r := newRunnerForClose(t)
		// shutdownStarted is false and shutdownDone is never closed, simulating
		// the normal request path where Shutdown is never invoked. Close must
		// not block on shutdownDone.
		closeDone := make(chan error, 1)
		go func() {
			closeDone <- r.Close()
		}()

		select {
		case err := <-closeDone:
			require.NoError(t, err)
		case <-time.After(2 * time.Second):
			t.Fatal("Close should not block on shutdownDone when no shutdown is in progress")
		}
	})

	t.Run("waits for shutdownDone before closing when a shutdown is in progress", func(t *testing.T) {
		r := newRunnerForClose(t)
		// Simulate a shutdown in progress: shutdownStarted is set but
		// shutdownDone has not been closed yet.
		r.stop.shutdownStarted.Store(true)

		closeDone := make(chan error, 1)
		go func() {
			closeDone <- r.Close()
		}()

		// Close should block until shutdownDone is closed.
		select {
		case <-closeDone:
			t.Fatal("Close should not return before shutdownDone is closed")
		case <-time.After(100 * time.Millisecond):
			// expected: Close is still waiting
		}

		// Signal that Shutdown has finished.
		close(r.stop.shutdownDone)

		select {
		case err := <-closeDone:
			require.NoError(t, err)
		case <-time.After(2 * time.Second):
			t.Fatal("Close should return after shutdownDone is closed")
		}
	})
}

func TestRunner_AcquireWorkflowLock_ConcurrentAttempts(t *testing.T) {
	rdb := initRdb(t)
	mockConn1 := &mockWebSocketConn{}
	mockWf1 := &mockWorkflowStream{}

	// We only mock websocket connection 2 as we are calling
	// handleWorkflowMessage directly for the first runner. The second runner
	// we want to call Execute on so we need to mock it properly.
	mockConn2 := &mockWebSocketConn{
		readMessages: [][]byte{
			[]byte(`{"startRequest": {"goal": "test", "workflowID": "concurrent-test-123"}}`),
		},
	}
	mockWf2 := &mockWorkflowStream{
		blockCh: make(chan bool),
	}

	req1 := httptest.NewRequest("GET", "/", nil)
	r1 := &runner{
		originalReq: req1,
		ws:          newWsManager(mockConn1),
		httpActionHandler: &runHTTPActionHandler{
			backend:     http.HandlerFunc(func(_ http.ResponseWriter, _ *http.Request) {}),
			originalReq: req1,
		},
		streamManager: &streamManager{
			wf:          mockWf1,
			originalReq: req1,
		},
		lockManager: newWorkflowLockManager(rdb),
		mcpManager:  &mockMcpManager{},
		lockFlow:    true,
	}

	req2 := httptest.NewRequest("GET", "/", nil)
	r2 := &runner{
		originalReq: req2,
		ws:          newWsManager(mockConn2),
		httpActionHandler: &runHTTPActionHandler{
			backend:     http.HandlerFunc(func(_ http.ResponseWriter, _ *http.Request) {}),
			originalReq: req2,
		},
		streamManager: &streamManager{
			wf:          mockWf2,
			originalReq: req2,
		},
		lockManager: newWorkflowLockManager(rdb),
		mcpManager:  &mockMcpManager{},
		lockFlow:    true,
	}

	startReq := &pb.StartWorkflowRequest{
		Goal:       "test workflow",
		WorkflowID: "concurrent-test-123",
		McpTools:   []*pb.McpTool{},
	}

	// First runner acquires the lock
	err := r1.acquireWorkflowLock(startReq)
	require.NoError(t, err)
	assert.NotNil(t, r1.mutex)

	// Second runner should fail to acquire the same lock. This uses the full
	// Execute() code path to be closer to an integration test.
	err = r2.Execute(context.Background())
	require.Error(t, err)
	assert.Contains(t, err.Error(), "failed to acquire lock")
	assert.Nil(t, r2.mutex)

	// Clean up
	r1.lockManager.releaseLock(context.Background(), r1.mutex, r1.workflowID)
}

func TestRunner_HandleWebSocketMessage_AcquiresLock(t *testing.T) {
	rdb := initRdb(t)
	mockConn := &mockWebSocketConn{}
	mockWf := &mockWorkflowStream{}

	req := httptest.NewRequest("GET", "/", nil)
	r := &runner{
		originalReq: req,
		ws:          newWsManager(mockConn),
		httpActionHandler: &runHTTPActionHandler{
			backend:     http.HandlerFunc(func(_ http.ResponseWriter, _ *http.Request) {}),
			originalReq: req,
		},
		streamManager: &streamManager{
			wf:          mockWf,
			originalReq: req,
		},
		lockManager: newWorkflowLockManager(rdb),
		mcpManager:  &mockMcpManager{},
		lockFlow:    true,
	}

	event := &pb.ClientEvent{}
	require.NoError(t, unmarshaler.Unmarshal([]byte(`{"startRequest": {"goal": "test", "workflowID": "msg-test-123"}}`), event))
	err := r.handleWebSocketMessage(event)
	require.NoError(t, err)

	// Verify lock was acquired
	assert.Equal(t, "msg-test-123", r.workflowID)
	assert.NotNil(t, r.mutex)

	// Clean up
	r.lockManager.releaseLock(context.Background(), r.mutex, r.workflowID)
}

func TestRunner_Execute_ReleasesLock(t *testing.T) {
	rdb := initRdb(t)

	mockConn := &mockWebSocketConn{
		readMessages: [][]byte{
			[]byte(`{"startRequest": {"goal": "test", "workflowID": "execute-test-123"}}`),
		},
	}

	mockWf := &mockWorkflowStream{
		blockCh: make(chan bool),
	}

	req := httptest.NewRequest("GET", "/", nil)
	r := &runner{
		originalReq: req,
		ws:          newWsManager(mockConn),
		httpActionHandler: &runHTTPActionHandler{
			backend:     http.HandlerFunc(func(_ http.ResponseWriter, _ *http.Request) {}),
			originalReq: req,
		},
		streamManager: &streamManager{
			wf:          mockWf,
			originalReq: req,
		},
		lockManager: newWorkflowLockManager(rdb),
		mcpManager:  &mockMcpManager{},
		lockFlow:    true,
	}

	ctx := context.Background()
	err := r.Execute(ctx)

	// since we block gRPC stream we expect websockets to end with EOF
	require.Equal(t, "handleWebSocketMessages: failed to read a WS message: EOF", err.Error())

	// Verify lock was released (we can acquire it again)
	mutex, err := r.lockManager.acquireLock(ctx, "execute-test-123")
	require.NoError(t, err)
	require.NotNil(t, mutex)
}

func TestRunner_isUsageQuotaExceededError(t *testing.T) {
	tests := []struct {
		name     string
		err      error
		expected bool
	}{
		{
			name:     "resource exhausted with quota exceeded message",
			err:      status.Error(codes.ResourceExhausted, "USAGE_QUOTA_EXCEEDED: consumer has exceeded their quota"),
			expected: true,
		},
		{
			name:     "resource exhausted without quota exceeded message",
			err:      status.Error(codes.ResourceExhausted, "some other resource exhausted error"),
			expected: false,
		},
		{
			name:     "different error code with quota exceeded message",
			err:      status.Error(codes.Internal, "USAGE_QUOTA_EXCEEDED: consumer has exceeded their quota"),
			expected: false,
		},
		{
			name:     "non-gRPC error",
			err:      errors.New("regular error"),
			expected: false,
		},
		{
			name:     "nil error",
			err:      nil,
			expected: false,
		},
		{
			name:     "OK status",
			err:      status.Error(codes.OK, "success"),
			expected: false,
		},
	}

	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			sm := &streamManager{}
			result := sm.isUsageQuotaExceededError(tt.err)
			require.Equal(t, tt.expected, result)
		})
	}
}

func TestStreamManager_Recv_returnsErrStreamUnavailable(t *testing.T) {
	sm := newTestStreamManager(t, &mockWorkflowStream{
		recvError: status.Error(codes.Unavailable, "service unavailable"),
	})

	_, err := sm.Recv()
	require.Error(t, err)
	require.ErrorIs(t, err, errStreamUnavailable, "Recv should wrap errStreamUnavailable for Unavailable gRPC errors")
}

func TestStreamManager_Recv_nonUnavailableError(t *testing.T) {
	sm := newTestStreamManager(t, &mockWorkflowStream{
		recvError: status.Error(codes.Internal, "internal server error"),
	})

	_, err := sm.Recv()
	require.Error(t, err)
	require.NotErrorIs(t, err, errStreamUnavailable, "Recv should not return errStreamUnavailable for non-Unavailable gRPC errors")
}

func TestStreamManager_Recv_returnsErrInvalidRequest(t *testing.T) {
	sm := newTestStreamManager(t, &mockWorkflowStream{
		recvError: status.Error(codes.InvalidArgument, "workflow is paused"),
	})

	_, err := sm.Recv()
	require.Error(t, err)
	require.ErrorIs(t, err, errInvalidRequest, "Recv should wrap errInvalidRequest for InvalidArgument gRPC errors")
	require.Contains(t, err.Error(), "workflow is paused", "Recv should preserve the DWS status message")
}

func TestRunner_handleAgentMessages_invalidRequest(t *testing.T) {
	// realistic full-length DWS message for the empty-goal rejection (121 bytes);
	// this is what actually broke production, where the old code forwarded the
	// whole wrapped error chain (>125 bytes) and the close frame was dropped.
	const dwsInvalidGoalMsg = "RESPONSE event must include a non-empty message. " +
		"The workflow remains paused; please provide real user input to continue."

	t.Run("sends 4400 with the clean DWS message and returns nil on INVALID_ARGUMENT", func(t *testing.T) {
		controlMessages := []struct {
			msgType int
			data    []byte
		}{}
		mockConn := &mockWebSocketConn{}
		wrappedConn := &shutdownTrackingConn{
			mockWebSocketConn: mockConn,
			controlMessages:   &controlMessages,
		}
		mockWf := &mockWorkflowStream{
			recvError: status.Error(codes.InvalidArgument, dwsInvalidGoalMsg),
		}

		req := httptest.NewRequest("GET", "/duo", nil)
		r := &runner{
			originalReq: req,
			ws:          newWsManager(wrappedConn),
			streamManager: &streamManager{
				wf:          mockWf,
				originalReq: req,
			},
			stop: stopCoordinator{
				acked: make(chan struct{}),
			},
		}

		errCh := make(chan error, 1)
		r.handleAgentMessages(context.Background(), errCh)

		err := <-errCh
		require.NoError(t, err, "handleAgentMessages should return nil for INVALID_ARGUMENT")

		// A close frame with code 4400 (private-use Bad Request) must actually be
		// sent, carrying the clean DWS status message (not the wrapped chain).
		require.Len(t, controlMessages, 1)
		require.Equal(t, websocket.CloseMessage, controlMessages[0].msgType)
		// FormatCloseMessage encodes as 2-byte big-endian code + UTF-8 reason.
		require.LessOrEqual(t, len(controlMessages[0].data), 125, "close frame must fit the 125-byte control-frame limit")
		closeCode := int(controlMessages[0].data[0])<<8 | int(controlMessages[0].data[1])
		require.Equal(t, closeInvalidRequest, closeCode, "close code should be 4400 (private-use Bad Request)")
		closeReason := string(controlMessages[0].data[2:])
		require.Equal(t, dwsInvalidGoalMsg, closeReason, "close reason should be the clean DWS status message")
		require.NotContains(t, closeReason, "failed to read a gRPC message", "close reason must not include the wrapped error chain")

		// Verify the connection is marked closed
		require.True(t, r.ws.closed.Load(), "websocket should be marked closed after SendInvalidRequest")
	})

	t.Run("truncates an over-long DWS message so the 4400 frame is still sent", func(t *testing.T) {
		controlMessages := []struct {
			msgType int
			data    []byte
		}{}
		wrappedConn := &shutdownTrackingConn{
			mockWebSocketConn: &mockWebSocketConn{},
			controlMessages:   &controlMessages,
		}
		mockWf := &mockWorkflowStream{
			recvError: status.Error(codes.InvalidArgument, strings.Repeat("x", 300)),
		}

		req := httptest.NewRequest("GET", "/duo", nil)
		r := &runner{
			originalReq: req,
			ws:          newWsManager(wrappedConn),
			streamManager: &streamManager{
				wf:          mockWf,
				originalReq: req,
			},
			stop: stopCoordinator{acked: make(chan struct{})},
		}

		errCh := make(chan error, 1)
		r.handleAgentMessages(context.Background(), errCh)
		require.NoError(t, <-errCh)

		// Even a 300-byte message must not drop the close frame: it is truncated
		// to fit, so the client still receives 4400 rather than falling back to 1000.
		require.Len(t, controlMessages, 1)
		require.LessOrEqual(t, len(controlMessages[0].data), 125, "close frame must fit the 125-byte control-frame limit")
		closeCode := int(controlMessages[0].data[0])<<8 | int(controlMessages[0].data[1])
		require.Equal(t, closeInvalidRequest, closeCode, "close code should be 4400")
		require.True(t, r.ws.closed.Load(), "websocket should be marked closed after SendInvalidRequest")
	})

	t.Run("returns nil even when SendInvalidRequest write fails", func(t *testing.T) {
		mockWf := &mockWorkflowStream{
			recvError: status.Error(codes.InvalidArgument, "workflow is paused"),
		}

		req := httptest.NewRequest("GET", "/duo", nil)
		r := &runner{
			originalReq: req,
			ws:          newWsManager(&mockWebSocketConn{writeControlError: errors.New("write failed")}),
			streamManager: &streamManager{
				wf:          mockWf,
				originalReq: req,
			},
			stop: stopCoordinator{
				acked: make(chan struct{}),
			},
		}

		errCh := make(chan error, 1)
		r.handleAgentMessages(context.Background(), errCh)

		err := <-errCh
		require.NoError(t, err, "handleAgentMessages should return nil even when the WS write fails")
	})
}

func TestRunner_AcquireWorkflowLock_MisconfiguredRedis(t *testing.T) {
	// Create a misconfigured Redis client (not connected to any server)
	rdb := redis.NewClient(&redis.Options{})
	lockManager := newWorkflowLockManager(rdb)
	require.NotNil(t, lockManager)

	mockConn := &mockWebSocketConn{}
	mockWf := &mockWorkflowStream{}

	r := &runner{
		originalReq: httptest.NewRequest("GET", "/", nil),
		ws:          newWsManager(mockConn),
		streamManager: &streamManager{
			wf: mockWf,
		},
		lockManager: lockManager,
		lockFlow:    true,
	}

	startReq := &pb.StartWorkflowRequest{
		Goal:       "test workflow",
		WorkflowID: "misconfigured-redis-test",
		McpTools:   []*pb.McpTool{},
	}

	// With misconfigured Redis, acquireLock should return errLockIsUnavailable
	// but acquireWorkflowLock should not return an error (it should proceed without lock)
	err := r.acquireWorkflowLock(startReq)
	require.NoError(t, err)
	require.Equal(t, "misconfigured-redis-test", r.workflowID)
	require.Nil(t, r.mutex)
}

func TestRunner_handleAgentAction_TrackLlmCallForSelfHosted(t *testing.T) {
	t.Run("successful tracking of LLM call", func(t *testing.T) {
		mockConn := &mockWebSocketConn{}
		mockWf := &mockWorkflowStream{}
		mockCloudStream := &mockSelfHostedWorkflowStream{
			recvActions: []*pb.TrackSelfHostedAction{
				{
					RequestID: "req-123",
				},
			},
		}

		req := httptest.NewRequest("GET", "/duo", nil)
		r := &runner{
			originalReq: req,
			ws:          newWsManager(mockConn),
			streamManager: &streamManager{
				wf:                 mockWf,
				cloudServiceStream: mockCloudStream,
				originalReq:        req,
			},
		}

		action := &pb.Action{
			RequestID: "req-123",
			Action: &pb.Action_TrackLlmCallForSelfHosted{
				TrackLlmCallForSelfHosted: &pb.TrackLlmCallForSelfHosted{
					WorkflowID:           "wf-456",
					FeatureQualifiedName: "duo_workflow",
					FeatureAiCatalogItem: true,
				},
			},
		}

		ctx := context.Background()
		err := r.handleAgentAction(ctx, action)

		require.NoError(t, err)

		// Verify cloud service stream received the correct event
		sentEvents := mockCloudStream.getSendEvents()
		require.Len(t, sentEvents, 1)
		require.Equal(t, "req-123", sentEvents[0].RequestID)
		require.Equal(t, "wf-456", sentEvents[0].WorkflowID)
		require.Equal(t, "duo_workflow", sentEvents[0].FeatureQualifiedName)
		require.True(t, sentEvents[0].FeatureAiCatalogItem)

		// Verify workflow stream received the acknowledgment
		wfEvents := mockWf.getSendEvents()
		require.Len(t, wfEvents, 1)
		actionResponse := wfEvents[0].GetActionResponse()
		require.NotNil(t, actionResponse)
		require.Equal(t, "req-123", actionResponse.RequestID)
		plainTextResp := actionResponse.GetPlainTextResponse()
		require.NotNil(t, plainTextResp)
		require.Empty(t, plainTextResp.Response)
	})

	t.Run("error when cloud service stream not initialized", func(t *testing.T) {
		mockConn := &mockWebSocketConn{}
		mockWf := &mockWorkflowStream{}

		req := httptest.NewRequest("GET", "/duo", nil)
		r := &runner{
			originalReq: req,
			ws:          newWsManager(mockConn),
			streamManager: &streamManager{
				wf:                 mockWf,
				cloudServiceStream: nil,
				originalReq:        req,
			},
		}

		action := &pb.Action{
			RequestID: "req-456",
			Action: &pb.Action_TrackLlmCallForSelfHosted{
				TrackLlmCallForSelfHosted: &pb.TrackLlmCallForSelfHosted{
					WorkflowID:           "wf-789",
					FeatureQualifiedName: "duo_workflow",
					FeatureAiCatalogItem: false,
				},
			},
		}

		ctx := context.Background()
		err := r.handleAgentAction(ctx, action)

		require.Error(t, err)
		require.Contains(t, err.Error(), "cloud service stream not initialized")
	})

	t.Run("error when sending to cloud service fails", func(t *testing.T) {
		mockConn := &mockWebSocketConn{}
		mockWf := &mockWorkflowStream{}
		mockCloudStream := &mockSelfHostedWorkflowStream{
			sendError: errors.New("send failed"),
		}

		req := httptest.NewRequest("GET", "/duo", nil)
		r := &runner{
			originalReq: req,
			ws:          newWsManager(mockConn),
			streamManager: &streamManager{
				wf:                 mockWf,
				cloudServiceStream: mockCloudStream,
				originalReq:        req,
			},
		}

		action := &pb.Action{
			RequestID: "req-789",
			Action: &pb.Action_TrackLlmCallForSelfHosted{
				TrackLlmCallForSelfHosted: &pb.TrackLlmCallForSelfHosted{
					WorkflowID:           "wf-101",
					FeatureQualifiedName: "duo_workflow",
					FeatureAiCatalogItem: true,
				},
			},
		}

		ctx := context.Background()
		err := r.handleAgentAction(ctx, action)

		require.Error(t, err)
		require.Contains(t, err.Error(), "failed to send to cloud service")
	})

	t.Run("error when receiving from cloud service fails", func(t *testing.T) {
		mockConn := &mockWebSocketConn{}
		mockWf := &mockWorkflowStream{}
		mockCloudStream := &mockSelfHostedWorkflowStream{
			recvError: errors.New("recv failed"),
		}

		req := httptest.NewRequest("GET", "/duo", nil)
		r := &runner{
			originalReq: req,
			ws:          newWsManager(mockConn),
			streamManager: &streamManager{
				wf:                 mockWf,
				cloudServiceStream: mockCloudStream,
				originalReq:        req,
			},
		}

		action := &pb.Action{
			RequestID: "req-012",
			Action: &pb.Action_TrackLlmCallForSelfHosted{
				TrackLlmCallForSelfHosted: &pb.TrackLlmCallForSelfHosted{
					WorkflowID:           "wf-112",
					FeatureQualifiedName: "duo_workflow",
					FeatureAiCatalogItem: false,
				},
			},
		}

		ctx := context.Background()
		err := r.handleAgentAction(ctx, action)

		require.Error(t, err)
		require.Contains(t, err.Error(), "failed to receive from cloud service")
	})
}

func TestRunner_pingWebSocket(t *testing.T) {
	t.Run("sends ping and sets read deadline", func(t *testing.T) {
		mockConn := &mockWebSocketConn{}

		req := httptest.NewRequest("GET", "/duo", nil)
		r := &runner{
			originalReq: req,
			ws:          newWsManager(mockConn),
		}

		ctx, cancel := context.WithCancel(context.Background())
		defer cancel()

		errCh := make(chan error, 1)

		// Replace WriteControl with a version that signals and then cancels.
		// We do this by running pingWebSocket with a very short interval using
		// a test-specific runner that wraps the mock.
		pingSent := make(chan struct{})
		wrappedConn := &pingTrackingConn{
			mockWebSocketConn: mockConn,
			onPing: func() {
				select {
				case pingSent <- struct{}{}:
				default:
				}
				cancel() // stop the goroutine after the first ping
			},
		}
		r.ws = newWsManager(wrappedConn)

		go r.pingWebSocket(ctx, errCh, 10*time.Millisecond)

		select {
		case <-pingSent:
			// ping was sent — verify a read deadline was set on the mock
			assert.NotEmpty(t, mockConn.getReadDeadlines(), "expected read deadline to be set before ping")
		case err := <-errCh:
			t.Fatalf("unexpected error from pingWebSocket: %v", err)
		case <-time.After(5 * time.Second):
			t.Fatal("timed out waiting for ping to be sent")
		}
	})

	t.Run("pong handler resets read deadline", func(t *testing.T) {
		mockConn := &mockWebSocketConn{}
		req := httptest.NewRequest("GET", "/duo", nil)

		r := &runner{
			originalReq: req,
			ws:          newWsManager(mockConn),
		}

		ctx, cancel := context.WithCancel(context.Background())
		defer cancel()

		// Register the pong handler before launching any goroutine, mirroring
		// what Execute() does. pingWebSocket no longer calls SetPongHandler
		// itself, so we must set it up here.
		r.ws.SetPongHandler(func(string) error {
			return r.ws.SetReadDeadline(time.Now().Add(wsPongTimeout))
		})

		errCh := make(chan error, 1)
		// Use a long interval so no pings fire during the test; we only care
		// about the pong handler behavior.
		go r.pingWebSocket(ctx, errCh, time.Hour)

		// The pong handler is already registered synchronously above, so invoke
		// it directly and verify it extends the read deadline.
		before := len(mockConn.getReadDeadlines())
		err := mockConn.getPongHandler()("test")
		require.NoError(t, err)
		deadlines := mockConn.getReadDeadlines()
		require.Greater(t, len(deadlines), before, "pong handler should have extended the read deadline")
		lastDeadline := deadlines[len(deadlines)-1]
		assert.True(t, lastDeadline.After(time.Now()), "read deadline should be in the future")
	})

	t.Run("stops workflow and marks websocket closed when WriteControl fails", func(t *testing.T) {
		writeErr := fmt.Errorf("network gone")
		wrappedConn := &pingTrackingConn{
			mockWebSocketConn: &mockWebSocketConn{
				writeControlError: writeErr,
			},
		}
		mockWf := &mockWorkflowStream{}

		ctx, cancel := context.WithCancel(context.Background())
		defer cancel()
		req, _ := http.NewRequestWithContext(ctx, "GET", "/duo", nil)
		stopAcked := make(chan struct{})
		r := &runner{
			originalReq: req,
			ws:          newWsManager(wrappedConn),
			streamManager: &streamManager{
				wf:          mockWf,
				originalReq: req,
			},
			stop: stopCoordinator{
				acked: stopAcked,
			},
		}

		errCh := make(chan error, 1)
		go r.pingWebSocket(ctx, errCh, 10*time.Millisecond)

		// Wait for the StopWorkflow event to be sent, then close stopAcked
		// so stopWorkflow unblocks and pingWebSocket can send to errCh.
		require.Eventually(t, func() bool {
			return len(mockWf.getSendEvents()) == 1
		}, 2*time.Second, 10*time.Millisecond)

		stopEvent := mockWf.getSendEvents()[0].GetStopWorkflow()
		require.NotNil(t, stopEvent)
		assert.Equal(t, "WORKHORSE_WEBSOCKET_PING_FAILED", stopEvent.Reason)
		assert.True(t, r.ws.closed.Load())

		close(stopAcked)

		select {
		case err := <-errCh:
			// stopWorkflow returned nil (via acked), so pingWebSocket forwards nil
			require.NoError(t, err)
		case <-time.After(5 * time.Second):
			t.Fatal("timed out waiting for pingWebSocket to return")
		}
	})
}

// shutdownTrackingConn wraps mockWebSocketConn and records WriteControl calls
// so tests can verify the close frame sent during Shutdown.
type shutdownTrackingConn struct {
	*mockWebSocketConn
	controlMessages *[]struct {
		msgType int
		data    []byte
	}
}

func (s *shutdownTrackingConn) WriteControl(msgType int, data []byte, deadline time.Time) error {
	*s.controlMessages = append(*s.controlMessages, struct {
		msgType int
		data    []byte
	}{msgType: msgType, data: data})
	return s.mockWebSocketConn.WriteControl(msgType, data, deadline)
}

func (s *shutdownTrackingConn) SetPongHandler(h func(string) error) {
	s.mockWebSocketConn.SetPongHandler(h)
}

// pingTrackingConn wraps mockWebSocketConn and calls onPing when WriteControl
// is called with a PingMessage, allowing tests to observe ping sends.
type pingTrackingConn struct {
	*mockWebSocketConn
	onPing func()
}

func (p *pingTrackingConn) WriteControl(msgType int, data []byte, deadline time.Time) error {
	if msgType == websocket.PingMessage && p.onPing != nil {
		p.onPing()
	}
	return p.mockWebSocketConn.WriteControl(msgType, data, deadline)
}

func (p *pingTrackingConn) SetPongHandler(h func(string) error) {
	p.mockWebSocketConn.SetPongHandler(h)
}
