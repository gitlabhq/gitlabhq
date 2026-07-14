package duoworkflow

import (
	"context"
	"encoding/json"
	"errors"
	"net"
	"strings"
	"testing"

	"github.com/gorilla/websocket"
	"github.com/stretchr/testify/assert"
	"github.com/stretchr/testify/require"
	pb "gitlab.com/gitlab-org/modelops/applied-ml/code-suggestions/ai-assist/clients/gopb/contract"
)

func TestWsManager_ReadClientEvent(t *testing.T) {
	t.Run("returns parsed event on valid message", func(t *testing.T) {
		msg := []byte(`{"startRequest": {"workflowID": "wf-1", "goal": "test"}}`)
		ws := newWsManager(&mockWebSocketConn{readMessages: [][]byte{msg}})

		event, err := ws.ReadClientEvent()

		require.NoError(t, err)
		require.NotNil(t, event)
		require.NotNil(t, event.GetStartRequest())
		assert.Equal(t, "wf-1", event.GetStartRequest().WorkflowID)
	})

	t.Run("returns error and marks closed on read failure", func(t *testing.T) {
		readErr := errors.New("connection reset")
		ws := newWsManager(&mockWebSocketConn{readError: readErr})

		_, err := ws.ReadClientEvent()

		require.ErrorIs(t, err, readErr)
		assert.True(t, ws.closed.Load(), "connection should be marked closed after read error")
	})

	t.Run("returns error on invalid JSON without marking closed", func(t *testing.T) {
		ws := newWsManager(&mockWebSocketConn{readMessages: [][]byte{[]byte("invalid json")}})

		_, err := ws.ReadClientEvent()

		require.Error(t, err)
		require.Contains(t, err.Error(), "ReadClientEvent: failed to unmarshal WS message")
		assert.False(t, ws.closed.Load(), "unmarshal error should not mark connection as closed")
	})
}

func TestWsManager_WriteAction(t *testing.T) {
	sampleAction := func() *pb.Action {
		return &pb.Action{
			RequestID: "req-1",
			Action:    &pb.Action_RunCommand{RunCommand: &pb.RunCommandAction{Program: "ls"}},
		}
	}

	t.Run("successful send sets and clears write deadline", func(t *testing.T) {
		mockConn := &mockWebSocketConn{}
		ws := newWsManager(mockConn)

		require.NoError(t, ws.WriteAction(context.Background(), sampleAction()))

		require.Len(t, mockConn.writeMessages, 1)
		require.Len(t, mockConn.writeDeadlines, 2)
		assert.False(t, mockConn.writeDeadlines[0].IsZero(), "first deadline should be non-zero")
		assert.True(t, mockConn.writeDeadlines[1].IsZero(), "second deadline should clear the deadline")
	})

	t.Run("no-op when connection is already closed", func(t *testing.T) {
		mockConn := &mockWebSocketConn{}
		ws := newWsManager(mockConn)
		ws.closed.Store(true)

		require.NoError(t, ws.WriteAction(context.Background(), sampleAction()))

		assert.Empty(t, mockConn.writeMessages, "no message should be written to a closed connection")
	})

	t.Run("ErrCloseSent is swallowed silently", func(t *testing.T) {
		ws := newWsManager(&mockWebSocketConn{writeError: websocket.ErrCloseSent})

		require.NoError(t, ws.WriteAction(context.Background(), sampleAction()))
	})

	tests := []struct {
		name           string
		conn           *mockWebSocketConn
		expectedErrMsg string
	}{
		{
			name:           "write error",
			conn:           &mockWebSocketConn{writeError: errors.New("write failed")},
			expectedErrMsg: "WriteAction: failed to send WS message: write failed",
		},
		{
			name:           "set write deadline error",
			conn:           &mockWebSocketConn{setDeadlineError: errors.New("set deadline failed")},
			expectedErrMsg: "WriteAction: failed to set write deadline: set deadline failed",
		},
		{
			name:           "clear write deadline error",
			conn:           &mockWebSocketConn{clearDeadlineError: errors.New("clear deadline failed")},
			expectedErrMsg: "WriteAction: failed to clear write deadline: clear deadline failed",
		},
	}
	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			ws := newWsManager(tt.conn)

			err := ws.WriteAction(context.Background(), sampleAction())

			require.EqualError(t, err, tt.expectedErrMsg)
		})
	}
}

// Regression guard: the agent_context_usage field must survive the proto→JSON
// round-trip so the WebSocket client can display token usage information.
func TestWsManager_WriteAction_AgentContextUsage(t *testing.T) {
	mockConn := &mockWebSocketConn{}
	ws := newWsManager(mockConn)

	action := &pb.Action{
		RequestID: "req-checkpoint",
		Action: &pb.Action_NewCheckpoint{
			NewCheckpoint: &pb.NewCheckpoint{
				Status: "running",
				AgentContextUsage: map[string]*pb.TokenBreakdown{
					"chat": {TotalTokens: 1234, MaxTokens: 200000},
				},
			},
		},
	}

	require.NoError(t, ws.WriteAction(context.Background(), action))
	require.Len(t, mockConn.writeMessages, 1)

	var payload struct {
		NewCheckpoint struct {
			AgentContextUsage map[string]struct {
				TotalTokens int `json:"total_tokens"`
				MaxTokens   int `json:"max_tokens"`
			} `json:"agent_context_usage"`
		} `json:"newCheckpoint"`
	}
	require.NoError(t, json.Unmarshal(mockConn.writeMessages[0], &payload))
	require.Contains(t, payload.NewCheckpoint.AgentContextUsage, "chat")
	assert.Equal(t, 1234, payload.NewCheckpoint.AgentContextUsage["chat"].TotalTokens)
	assert.Equal(t, 200000, payload.NewCheckpoint.AgentContextUsage["chat"].MaxTokens)
}

func TestWsManager_ReadError(t *testing.T) {
	ws := newWsManager(&mockWebSocketConn{})

	tests := []struct {
		name           string
		err            error
		expectedReason string
		expectedOk     bool
	}{
		{
			name:           "CloseNormalClosure",
			err:            &websocket.CloseError{Code: websocket.CloseNormalClosure},
			expectedReason: "WORKHORSE_WEBSOCKET_CLOSE_1000",
			expectedOk:     true,
		},
		{
			name:           "CloseGoingAway",
			err:            &websocket.CloseError{Code: websocket.CloseGoingAway},
			expectedReason: "WORKHORSE_WEBSOCKET_CLOSE_1001",
			expectedOk:     true,
		},
		{
			name:           "net timeout",
			err:            &net.OpError{Op: "read", Err: &timeoutError{}},
			expectedReason: "WORKHORSE_WEBSOCKET_PONG_TIMEOUT",
			expectedOk:     true,
		},
		{
			name:       "unexpected close code",
			err:        &websocket.CloseError{Code: websocket.CloseInternalServerErr},
			expectedOk: false,
		},
		{
			name:       "generic error",
			err:        errors.New("something unexpected"),
			expectedOk: false,
		},
	}

	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			reason, ok := ws.ReadError(tt.err)

			assert.Equal(t, tt.expectedOk, ok)
			assert.Equal(t, tt.expectedReason, reason)
		})
	}
}

func TestWsManager_Ping(t *testing.T) {
	tests := []struct {
		name         string
		writeCtrlErr error
		expectClosed bool
		expectErr    bool
	}{
		{
			name:         "success does not mark connection closed",
			expectClosed: false,
		},
		{
			name:         "failure marks connection closed",
			writeCtrlErr: errors.New("network gone"),
			expectClosed: true,
			expectErr:    true,
		},
	}

	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			ws := newWsManager(&mockWebSocketConn{writeControlError: tt.writeCtrlErr})

			err := ws.Ping()

			assert.Equal(t, tt.expectErr, err != nil)
			assert.Equal(t, tt.expectClosed, ws.closed.Load())
		})
	}
}

func TestWsManager_SendGoingAway(t *testing.T) {
	tests := []struct {
		name         string
		writeCtrlErr error
		expectClosed bool
		expectErr    bool
	}{
		{
			name:         "success marks connection closed",
			expectClosed: true,
		},
		{
			name:         "failure does not mark connection closed",
			writeCtrlErr: errors.New("write failed"),
			expectClosed: false,
			expectErr:    true,
		},
	}

	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			ws := newWsManager(&mockWebSocketConn{writeControlError: tt.writeCtrlErr})

			err := ws.SendGoingAway()

			assert.Equal(t, tt.expectErr, err != nil)
			assert.Equal(t, tt.expectClosed, ws.closed.Load())
		})
	}
}

func TestTruncateCloseReason(t *testing.T) {
	tests := []struct {
		name  string
		input string
		want  string
	}{
		{
			name:  "short string is unchanged",
			input: "short reason",
			want:  "short reason",
		},
		{
			name:  "exactly 123 bytes is unchanged",
			input: strings.Repeat("a", 123),
			want:  strings.Repeat("a", 123),
		},
		{
			name:  "longer than 123 bytes is truncated",
			input: strings.Repeat("a", 200),
			want:  strings.Repeat("a", 123),
		},
		{
			name:  "truncation respects UTF-8 boundaries",
			input: strings.Repeat("a", 122) + "é", // é is 2 bytes; total = 124 bytes
			want:  strings.Repeat("a", 122),       // drop the incomplete rune
		},
	}

	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			got := truncateCloseReason(tt.input)
			assert.Equal(t, tt.want, got)
			assert.LessOrEqual(t, len(got), wsCloseMaxReasonBytes)
		})
	}
}

func TestWsManager_SendInvalidRequest(t *testing.T) {
	tests := []struct {
		name         string
		reason       string
		writeCtrlErr error
		expectClosed bool
		expectErr    bool
	}{
		{
			name:         "success marks connection closed",
			reason:       "workflow rejected the reconnect due to invalid input",
			expectClosed: true,
		},
		{
			name:         "long reason is truncated and succeeds",
			reason:       strings.Repeat("x", 200),
			expectClosed: true,
		},
		{
			name:         "failure does not mark connection closed",
			reason:       "workflow rejected the reconnect due to invalid input",
			writeCtrlErr: errors.New("write failed"),
			expectClosed: false,
			expectErr:    true,
		},
	}

	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			ws := newWsManager(&mockWebSocketConn{writeControlError: tt.writeCtrlErr})

			err := ws.SendInvalidRequest(tt.reason)

			assert.Equal(t, tt.expectErr, err != nil)
			assert.Equal(t, tt.expectClosed, ws.closed.Load())
		})
	}
}

func TestWsManager_Close(t *testing.T) {
	t.Run("no-op when already closed", func(t *testing.T) {
		ws := newWsManager(&mockWebSocketConn{writeControlError: errors.New("should not be called")})
		ws.closed.Store(true)

		require.NoError(t, ws.Close())
	})

	tests := []struct {
		name              string
		writeControlError error
		setDeadlineError  error
		closeError        error
		expectedErrMsg    string
	}{
		{
			name: "successful close",
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
			ws := newWsManager(&mockWebSocketConn{
				writeControlError: tt.writeControlError,
				setDeadlineError:  tt.setDeadlineError,
				closeError:        tt.closeError,
			})

			err := ws.Close()

			if tt.expectedErrMsg != "" {
				require.EqualError(t, err, tt.expectedErrMsg)
			} else {
				require.NoError(t, err)
			}
		})
	}
}

// timeoutError is defined in runner_test.go; it is accessible here because
// both files share the same test package (package duoworkflow).
var _ net.Error = &timeoutError{}
