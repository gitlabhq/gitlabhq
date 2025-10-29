package duoworkflow

import (
	"context"
	"errors"
	"fmt"
	"io"
	"net/http"
	"net/http/httptest"
	"net/url"
	"sync"
	"testing"
	"time"

	"github.com/gorilla/websocket"
	"github.com/stretchr/testify/assert"
	"github.com/stretchr/testify/require"
	pb "gitlab.com/gitlab-org/modelops/applied-ml/code-suggestions/ai-assist/clients/gopb/contract"

	"gitlab.com/gitlab-org/gitlab/workhorse/internal/api"
)

type mockWebSocketConn struct {
	readMessages      [][]byte
	writeMessages     [][]byte
	readIndex         int
	readError         error
	writeError        error
	closeError        error
	writeControlError error
	setDeadlineError  error
	blockCh           chan bool
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

func (m *mockWebSocketConn) WriteControl(_ int, _ []byte, _ time.Time) error {
	return m.writeControlError
}

func (m *mockWebSocketConn) SetReadDeadline(_ time.Time) error {
	return m.setDeadlineError
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

type mockMcpManager struct {
	tools               []*pb.McpTool
	hasToolResult       bool
	callToolResult      *pb.ClientEvent
	callToolError       error
	closeError          error
	callToolInvocations []struct {
		name string
		args string
	}
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
		ServiceURI: server.Addr,
		Headers: map[string]string{
			"Authorization":        "Bearer test-token",
			"x-gitlab-oauth-token": "oauth-token-123",
		},
		Secure: false,
	}

	runner, err := newRunner(mockConn, apiClient, req, cfg)

	require.NoError(t, err)
	require.NotNil(t, runner)
	require.Equal(t, "oauth-token-123", runner.token)
	require.Equal(t, req, runner.originalReq)
	require.Equal(t, mockConn, runner.conn)
	require.NotNil(t, runner.wf)
	require.NotNil(t, runner.client)
	require.Equal(t, apiClient, runner.rails)

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

			testURL, _ := url.Parse("http://example.com")
			r := &runner{
				rails: &api.API{
					Client: &http.Client{},
					URL:    testURL,
				},
				token:       "test-token",
				originalReq: &http.Request{},
				conn:        mockConn,
				wf:          mockWf,
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

			r := &runner{conn: mockConn, wf: mockWf}
			err := r.Execute(context.Background())

			if tt.expectedErrMsg != "" {
				require.EqualError(t, err, tt.expectedErrMsg)
			} else {
				require.NoError(t, err)
			}
		})
	}
}

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

			r := &runner{conn: mockConn, wf: mockWf}

			errCh := make(chan error, 1)
			go func() { errCh <- r.Execute(context.Background()) }()

			require.Eventually(t, func() bool {
				return len(mockWf.getSendEvents()) == 1
			}, 2*time.Second, 50*time.Millisecond)

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
		name           string
		message        []byte
		sendError      error
		mcpManager     *mockMcpManager
		expectedErrMsg string
		expectMcpTools bool
	}{
		{
			name:           "invalid json",
			message:        []byte("invalid json"),
			expectedErrMsg: "handleWebSocketMessage: failed to unmarshal a WS message: proto:",
		},
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
			name:    "start request with mcp tools",
			message: []byte(`{"startRequest": {"goal": "test goal", "mcpTools": [{"name": "get_issue"}]}}`),
			mcpManager: &mockMcpManager{
				tools: []*pb.McpTool{
					{Name: "test_tool", Description: "A test tool"},
				},
			},
			expectMcpTools: true,
			expectedErrMsg: "",
		},
		{
			name:           "start request without mcp manager",
			message:        []byte(`{"startRequest": {"goal": "test goal"}}`),
			mcpManager:     nil,
			expectMcpTools: false,
			expectedErrMsg: "",
		},
	}

	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			mockWf := &mockWorkflowStream{
				sendError: tt.sendError,
			}

			testURL, _ := url.Parse("http://example.com")
			r := &runner{
				rails: &api.API{
					Client: &http.Client{},
					URL:    testURL,
				},
				token:       "test-token",
				originalReq: &http.Request{},
				conn:        &mockWebSocketConn{},
				wf:          mockWf,
				mcpManager:  tt.mcpManager,
			}

			err := r.handleWebSocketMessage(tt.message)

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
			expectedErrMsg: "sendActionToWs: failed to send WS message: websocket write failed",
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

			serverURL, err := url.Parse(server.URL)
			require.NoError(t, err)

			mockConn := &mockWebSocketConn{
				writeError: tt.wsWriteError,
			}
			mockWf := &mockWorkflowStream{
				sendError: tt.wfSendError,
			}

			r := &runner{
				rails: &api.API{
					Client: server.Client(),
					URL:    serverURL,
				},
				token:       "test-token",
				originalReq: &http.Request{},
				conn:        mockConn,
				wf:          mockWf,
				mcpManager:  tt.mcpManager,
			}

			ctx := context.Background()
			err = r.handleAgentAction(ctx, tt.action)

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

func TestRunner_closeWebSocketConnection(t *testing.T) {
	tests := []struct {
		name              string
		writeControlError error
		setDeadlineError  error
		closeError        error
		expectedErrMsg    string
	}{
		{
			name:           "successful close",
			expectedErrMsg: "",
		},
		{
			name:              "write control error followed by successful close",
			writeControlError: errors.New("write control failed"),
			expectedErrMsg:    "failed to send close message: write control failed",
		},
		{
			name:              "write control error followed by close error",
			writeControlError: errors.New("write control failed"),
			closeError:        errors.New("close failed"),
			expectedErrMsg:    "failed to send close message and failed to close connection: close failed",
		},
		{
			name:             "set deadline error followed by successful close",
			setDeadlineError: errors.New("set deadline failed"),
			expectedErrMsg:   "failed to set read deadline: set deadline failed",
		},
		{
			name:             "set deadline error followed by close error",
			setDeadlineError: errors.New("set deadline failed"),
			closeError:       errors.New("close failed"),
			expectedErrMsg:   "failed to set read deadline and failed to close connection: close failed",
		},
		{
			name:           "close error after successful control operations",
			closeError:     errors.New("close failed"),
			expectedErrMsg: "failed to close connection: close failed",
		},
	}

	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			mockConn := &mockWebSocketConn{
				writeControlError: tt.writeControlError,
				setDeadlineError:  tt.setDeadlineError,
				closeError:        tt.closeError,
			}

			r := &runner{
				conn: mockConn,
			}

			err := r.closeWebSocketConnection()

			if tt.expectedErrMsg != "" {
				require.EqualError(t, err, tt.expectedErrMsg)
			} else {
				require.NoError(t, err)
			}
		})
	}
}

func TestRunner_sendActionToWs(t *testing.T) {
	tests := []struct {
		name           string
		action         *pb.Action
		writeError     error
		expectedErrMsg string
	}{
		{
			name: "successful send",
			action: &pb.Action{
				RequestID: "req-123",
				Action: &pb.Action_RunCommand{
					RunCommand: &pb.RunCommandAction{
						Program: "ls",
					},
				},
			},
			expectedErrMsg: "",
		},
		{
			name: "write error",
			action: &pb.Action{
				RequestID: "req-456",
				Action: &pb.Action_RunCommand{
					RunCommand: &pb.RunCommandAction{
						Program: "ls",
					},
				},
			},
			writeError:     errors.New("write failed"),
			expectedErrMsg: "sendActionToWs: failed to send WS message: write failed",
		},
	}

	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			mockConn := &mockWebSocketConn{
				writeError: tt.writeError,
			}

			testURL, _ := url.Parse("http://example.com")
			r := &runner{
				rails: &api.API{
					Client: &http.Client{},
					URL:    testURL,
				},
				conn: mockConn,
			}

			err := r.sendActionToWs(tt.action)

			if tt.expectedErrMsg != "" {
				require.EqualError(t, err, tt.expectedErrMsg)
			} else {
				require.NoError(t, err)
				require.Len(t, mockConn.writeMessages, 1)
			}
		})
	}
}
