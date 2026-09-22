package duoworkflow

import (
	"context"
	"encoding/json"
	"errors"
	"net"
	"runtime"
	"strings"
	"testing"
	"time"

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

func largeTestAction(size int) *pb.Action {
	return &pb.Action{
		RequestID: "req-large",
		Action: &pb.Action_RunCommand{
			RunCommand: &pb.RunCommandAction{Program: strings.Repeat("x", size)},
		},
	}
}

// TestWsManager_MarshalBufferPooling guards the memory footprint of the action
// marshaling buffer. It was first allocated at the full 4MB message ceiling
// for every connection, then grown on demand but still held per connection.
// Both pinned memory for the whole multi-hour connection lifetime, which at
// gprd's near-thousand concurrent connections reached the container limit.
// Buffers now come from a shared pool, so retention follows concurrent writes
// rather than open connections.
func TestWsManager_MarshalBufferPooling(t *testing.T) {
	t.Run("connection holds no marshaling buffer of its own", func(t *testing.T) {
		conn := &mockWebSocketConn{}
		var sink *wsManager

		allocs := testing.AllocsPerRun(100, func() {
			sink = newWsManager(conn)
		})
		runtime.KeepAlive(sink)

		assert.LessOrEqual(t, allocs, 1.0,
			"a new connection must allocate only the wsManager struct, not a marshaling buffer")
	})

	t.Run("never hands out a buffer holding a previous payload", func(t *testing.T) {
		// Capacity is deliberately not asserted: a pooled buffer may have been
		// grown by an earlier write, and sync.Pool gives no guarantee about
		// which entry Get returns. Zero length is the actual invariant.
		for i := 0; i < 8; i++ {
			bufp := marshalBufPool.Get().(*[]byte)
			assert.Empty(t, *bufp, "a pooled buffer must be reset before reuse")
			releaseMarshalBuf(bufp)
		}
	})

	t.Run("clears the payload before returning a buffer to the pool", func(t *testing.T) {
		buf := []byte(`{"requestID":"secret-prompt-text"}`)
		releaseMarshalBuf(&buf)

		assert.Empty(t, buf, "the previous action's payload must not stay reachable")
	})

	t.Run("grows on demand to write an action larger than the initial buffer", func(t *testing.T) {
		const size = 300 << 10
		mockConn := &mockWebSocketConn{}
		ws := newWsManager(mockConn)

		require.NoError(t, ws.WriteAction(context.Background(), largeTestAction(size)))

		require.Len(t, mockConn.writeMessages, 1)
		assert.Greater(t, len(mockConn.writeMessages[0]), size,
			"the full action must be written even though the buffer started small")
	})

	t.Run("keeps buffers up to the cap and drops larger ones", func(t *testing.T) {
		// The cap must stay clear of the sizes real actions reach. Dropping a
		// buffer costs a full regrow on the next write, so a cap set near the
		// message size would thrash on the largest actions instead of
		// protecting against outliers.
		assert.True(t, shouldPoolMarshalBuf(initialMarshalBufSize),
			"a fresh buffer must be poolable")
		assert.True(t, shouldPoolMarshalBuf(gprdActionSize),
			"a buffer grown to a production action size must be poolable")
		assert.True(t, shouldPoolMarshalBuf(maxPooledMarshalBufSize),
			"the cap itself must be poolable")
		assert.False(t, shouldPoolMarshalBuf(maxPooledMarshalBufSize+1),
			"a buffer past the cap must be dropped")
	})
}

// Force heap escape so the benchmark measures per-connection allocations.
var wsManagerSink *wsManager

// discardConn drops writes so a benchmark measures only wsManager allocation,
// not the mock's retained write log.
type discardConn struct{}

func (discardConn) ReadMessage() (int, []byte, error)         { return 0, nil, nil }
func (discardConn) WriteMessage(int, []byte) error            { return nil }
func (discardConn) WriteControl(int, []byte, time.Time) error { return nil }
func (discardConn) SetReadDeadline(time.Time) error           { return nil }
func (discardConn) SetWriteDeadline(time.Time) error          { return nil }
func (discardConn) SetPongHandler(func(string) error)         {}
func (discardConn) Close() error                              { return nil }

func BenchmarkNewWsManager(b *testing.B) {
	b.ReportAllocs()
	for i := 0; i < b.N; i++ {
		wsManagerSink = newWsManager(&mockWebSocketConn{})
	}
}

// gprdActionSize mirrors the 1.42MB actions seen in gprd.
const gprdActionSize = 1420 << 10

// BenchmarkWriteActionLarge guards the steady-state cost of a connection that
// repeatedly writes large actions, which is the gprd pattern. B/op must stay
// small: if it approaches the payload size the buffer is being reallocated on
// every action instead of reused from the pool.
func BenchmarkWriteActionLarge(b *testing.B) {
	ws := newWsManager(discardConn{})
	action := largeTestAction(gprdActionSize)
	ctx := context.Background()

	b.ReportAllocs()
	b.ResetTimer()
	for i := 0; i < b.N; i++ {
		if err := ws.WriteAction(ctx, action); err != nil {
			b.Fatal(err)
		}
	}
}

// BenchmarkConnectionsRetainedBytes measures the heap pinned by a fleet of idle
// connections that have each written one large action, which is the gprd shape:
// connections live for hours and spend nearly all of it waiting on model and
// tool latency.
//
// This is the regression guard for the per-connection buffer. When each
// connection owned its buffer this reported roughly the action size per
// connection, so a thousand concurrent connections pinned well over a
// gigabyte. Pooling must keep it near the size of a wsManager struct.
//
// Two collections run before the measurement because sync.Pool entries survive
// one cycle in the victim cache; the second frees them, leaving only memory the
// live connections actually pin.
func BenchmarkConnectionsRetainedBytes(b *testing.B) {
	const connections = 500

	action := largeTestAction(gprdActionSize)
	ctx := context.Background()

	var retainedPerConn float64

	for i := 0; i < b.N; i++ {
		conns := make([]*wsManager, 0, connections)

		runtime.GC()
		runtime.GC()
		var before runtime.MemStats
		runtime.ReadMemStats(&before)

		for j := 0; j < connections; j++ {
			ws := newWsManager(discardConn{})
			if err := ws.WriteAction(ctx, action); err != nil {
				b.Fatal(err)
			}
			conns = append(conns, ws)
		}

		runtime.GC()
		runtime.GC()
		var after runtime.MemStats
		runtime.ReadMemStats(&after)
		runtime.KeepAlive(conns)

		// Guard the unsigned subtraction: a collection that frees more than
		// the loop allocated would otherwise report a nonsense huge number
		// instead of a small one.
		if after.HeapAlloc < before.HeapAlloc {
			retainedPerConn = 0
			continue
		}
		retainedPerConn = float64(after.HeapAlloc-before.HeapAlloc) / connections
	}

	b.ReportMetric(retainedPerConn, "B-retained/conn")
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

func TestWsManager_Start(t *testing.T) {
	t.Run("arms the initial read deadline", func(t *testing.T) {
		mockConn := &mockWebSocketConn{}
		ws := newWsManager(mockConn)

		require.NoError(t, ws.Start())

		deadlines := mockConn.getReadDeadlines()
		require.Len(t, deadlines, 1)
		assert.True(t, deadlines[0].After(time.Now()), "read deadline should be in the future")
	})

	t.Run("registers a pong handler that extends the read deadline", func(t *testing.T) {
		mockConn := &mockWebSocketConn{}
		ws := newWsManager(mockConn)

		require.NoError(t, ws.Start())

		before := len(mockConn.getReadDeadlines())
		require.NoError(t, mockConn.getPongHandler()("test"))

		deadlines := mockConn.getReadDeadlines()
		require.Greater(t, len(deadlines), before, "pong handler should have extended the read deadline")
		assert.True(t, deadlines[len(deadlines)-1].After(time.Now()), "read deadline should be in the future")
	})

	t.Run("returns the error when the read deadline cannot be set", func(t *testing.T) {
		ws := newWsManager(&mockWebSocketConn{setDeadlineError: errors.New("conn gone")})

		require.ErrorContains(t, ws.Start(), "conn gone")
	})
}

func TestWsManager_Keepalive(t *testing.T) {
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

			err := ws.Keepalive()

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

			err := ws.SendGoingAway(closeReasonWorkhorseShutdown)

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
	t.Run("closes the transport without a close frame when already marked closed", func(t *testing.T) {
		mockConn := &mockWebSocketConn{writeControlError: errors.New("should not be called")}
		ws := newWsManager(mockConn)
		ws.closed.Store(true)

		require.NoError(t, ws.Close())
		assert.Equal(t, 1, mockConn.closeCalls, "underlying connection must be closed even when a close frame was already sent")
	})

	t.Run("returns the close error when already marked closed", func(t *testing.T) {
		ws := newWsManager(&mockWebSocketConn{closeError: errors.New("close failed")})
		ws.closed.Store(true)

		require.EqualError(t, ws.Close(), "failed to close connection: close failed")
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
