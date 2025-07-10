package duoworkflow

import (
	"context"
	"errors"
	"fmt"
	"io"
	"net/http"
	"net/http/httptest"
	"net/url"
	"testing"

	"github.com/gorilla/websocket"
	"github.com/stretchr/testify/assert"
	"github.com/stretchr/testify/require"
	pb "gitlab.com/gitlab-org/modelops/applied-ml/code-suggestions/ai-assist/clients/gopb/contract"

	"gitlab.com/gitlab-org/gitlab/workhorse/internal/api"
)

type mockWebSocketConn struct {
	readMessages  [][]byte
	writeMessages [][]byte
	readIndex     int
	readError     error
	writeError    error
	blockCh       chan bool
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

type mockWorkflowStream struct {
	sendEvents  []*pb.ClientEvent
	recvActions []*pb.Action
	recvIndex   int
	sendError   error
	recvError   error
	blockCh     chan bool
}

func (m *mockWorkflowStream) Send(event *pb.ClientEvent) error {
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
			expectedErrMsg:  "handleWebSocketMessage: failed to read a WS message: EOF",
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

			require.Len(t, mockWf.sendEvents, tt.sendEventsCount)
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
			expectedErrMsg: "handleWebSocketMessage: failed to read a WS message: read error",
		},
		{
			name:           "workflow recv error",
			wfRecvError:    errors.New("recv error"),
			wsBlockCh:      make(chan bool),
			expectedErrMsg: "duoworkflow: failed to read a gRPC message: recv error",
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
		})
	}
}

func TestRunner_handleWebSocketMessage(t *testing.T) {
	tests := []struct {
		name           string
		message        []byte
		readError      error
		sendError      error
		expectedErrMsg string
	}{
		{
			name:           "read error",
			readError:      errors.New("read error"),
			expectedErrMsg: "handleWebSocketMessage: failed to read a WS message: read error",
		},
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
			expectedErrMsg: "handleWebSocketMessage: failed to write a gRPC message: EOF",
		},
		{
			name:           "successful message handling",
			message:        []byte(`{"type": "test"}`),
			expectedErrMsg: "",
		},
	}

	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			mockConn := &mockWebSocketConn{
				readMessages: [][]byte{tt.message},
				readError:    tt.readError,
			}
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
				conn:        mockConn,
				wf:          mockWf,
			}

			err := r.handleWebSocketMessage()

			if tt.expectedErrMsg != "" {
				require.Error(t, err)
				require.Contains(t, err.Error(), tt.expectedErrMsg)
			} else {
				require.NoError(t, err)
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
		expectedErrMsg string
		shouldCallWS   bool
		shouldCallWF   bool
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
			expectedErrMsg: "handleAgentAction: failed to send WS message: websocket write failed",
		},
		{
			name: "action with nil action type",
			action: &pb.Action{
				RequestID: "req-nil",
				Action:    nil,
			},
			shouldCallWS: true,
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

			if tt.shouldCallWF {
				require.Len(t, mockWf.sendEvents, 1, "Expected one workflow event to be sent")

				response := mockWf.sendEvents[0].Response.(*pb.ClientEvent_ActionResponse).ActionResponse.Response
				require.Equal(t, `[{"id": 123, "name": "test-project"}]`, response)
			} else {
				require.Empty(t, mockWf.sendEvents)
			}
		})
	}
}
