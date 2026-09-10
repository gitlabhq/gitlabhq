package duoworkflow

import (
	"fmt"
	"io"
	"net/http"
	"net/http/httptest"
	"net/url"
	"strings"
	"testing"
	"time"

	"github.com/gorilla/websocket"
	"github.com/prometheus/client_golang/prometheus"
	"github.com/prometheus/client_golang/prometheus/testutil"
	"github.com/stretchr/testify/assert"
	"github.com/stretchr/testify/require"
	pb "gitlab.com/gitlab-org/modelops/applied-ml/code-suggestions/ai-assist/clients/gopb/contract"
	"google.golang.org/grpc/codes"
	"google.golang.org/grpc/status"

	"gitlab.com/gitlab-org/gitlab/workhorse/internal/api"
	"gitlab.com/gitlab-org/gitlab/workhorse/internal/testhelper"
)

// counterValue returns the current float64 value of a prometheus.Counter.
func counterValue(t *testing.T, c prometheus.Counter) float64 {
	t.Helper()
	return testutil.ToFloat64(c)
}

// counterVecValue returns the current float64 value of a single label combination
// on a *prometheus.CounterVec.
func counterVecValue(t *testing.T, cv *prometheus.CounterVec, labels ...string) float64 {
	t.Helper()
	return testutil.ToFloat64(cv.WithLabelValues(labels...))
}

// newTestStreamManager returns a streamManager wrapping the given mock stream.
// The gRPC client is real but never dialed, since grpc.NewClient connects
// lazily, so that Close behaves like it does in production.
func newTestStreamManager(t *testing.T, wf workflowStream) *streamManager {
	t.Helper()

	client, err := NewClient(&api.DuoWorkflowServiceConfig{URI: "localhost:1"}, "test-agent", "")
	require.NoError(t, err)

	return &streamManager{
		wf:          wf,
		client:      client,
		originalReq: httptest.NewRequest(http.MethodGet, "/", nil),
	}
}

// testDuoWorkflowConfig builds a minimal *api.DuoWorkflow pointing at the given
// in-process test gRPC server (insecure, no auth headers needed).
func testDuoWorkflowConfig(server *testServer) *api.DuoWorkflow {
	return &api.DuoWorkflow{
		Service: &api.DuoWorkflowServiceConfig{
			URI:    server.Addr,
			Secure: false,
		},
	}
}

// newServerSideConn opens a loopback WebSocket pair and returns the server-side
// *websocket.Conn. It is useful when a test needs a real conn to pass into
// handler methods that call WriteMessage, without standing up a full handler.
func newServerSideConn(t *testing.T) *websocket.Conn {
	t.Helper()
	connCh := make(chan *websocket.Conn, 1)
	upgrader := websocket.Upgrader{}
	srv := httptest.NewServer(http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		c, err := upgrader.Upgrade(w, r, nil)
		assert.NoError(t, err)
		connCh <- c
	}))
	t.Cleanup(srv.Close)

	wsURL := "ws" + strings.TrimPrefix(srv.URL, "http") + "/"
	clientConn, resp, err := websocket.DefaultDialer.Dial(wsURL, nil)
	if resp != nil {
		_ = resp.Body.Close()
	}
	require.NoError(t, err)
	t.Cleanup(func() { _ = clientConn.Close() })

	serverConn := <-connCh
	t.Cleanup(func() { _ = serverConn.Close() })
	return serverConn
}

// dialTestHandler starts a full HTTP/WebSocket server backed by the given handler
// and returns an open WebSocket connection to it.
func dialTestHandler(t *testing.T, h http.Handler) *websocket.Conn {
	t.Helper()
	srv := httptest.NewServer(h)
	t.Cleanup(srv.Close)
	wsURL := "ws" + strings.TrimPrefix(srv.URL, "http") + "/"
	conn, resp, err := websocket.DefaultDialer.Dial(wsURL, nil)
	if resp != nil {
		_ = resp.Body.Close()
	}
	require.NoError(t, err)
	t.Cleanup(func() { _ = conn.Close() })
	return conn
}

// setupHandlerWithGRPC wires together the API server and the gRPC test server and
// returns a ready-to-use Handler.Build() http.Handler.
func setupHandlerWithGRPC(t *testing.T, grpcServer *testServer) http.Handler {
	t.Helper()
	responseBody := fmt.Sprintf(`{
		"DuoWorkflow": {
			"Service": {
				"URI": "%s",
				"Headers": {},
				"Secure": false
			}
		}
	}`, grpcServer.Addr)

	apiServer := httptest.NewServer(http.HandlerFunc(func(w http.ResponseWriter, _ *http.Request) {
		w.Header().Set("Content-Type", api.ResponseContentType)
		w.WriteHeader(http.StatusOK)
		_, err := w.Write([]byte(responseBody))
		assert.NoError(t, err)
	}))
	t.Cleanup(apiServer.Close)

	apiURL, err := url.Parse(apiServer.URL)
	require.NoError(t, err)
	apiClient := api.NewAPI(apiURL, "test-version", http.DefaultTransport)

	return NewHandler(apiClient, initRdb(t), http.HandlerFunc(func(_ http.ResponseWriter, _ *http.Request) {}), "").Build()
}

// TestConnectionsTotal verifies that connectionsTotal increments once per
// inbound request, before the WebSocket upgrade is attempted.
func TestConnectionsTotal(t *testing.T) {
	testhelper.ConfigureSecret()

	grpcServer := setupTestServer(t)
	handler := setupHandlerWithGRPC(t, grpcServer)

	before := counterVecValue(t, connectionsTotal, transportWebSocket)

	// The counter is incremented before Upgrade, so it is already bumped by the
	// time the WebSocket dial returns.
	_ = dialTestHandler(t, handler)

	require.InDelta(t, before+1, counterVecValue(t, connectionsTotal, transportWebSocket), 0,
		"connectionsTotal should increment by 1 per connection attempt")
}

func TestConnectionsOpen(t *testing.T) {
	testhelper.ConfigureSecret()

	grpcServer := setupTestServer(t)
	released := make(chan struct{})
	grpcServer.execWorkflowHandler = func(_ pb.DuoWorkflow_ExecuteWorkflowServer) error {
		<-released
		return nil
	}
	handler := setupHandlerWithGRPC(t, grpcServer)

	openWebSocketConns := func() float64 {
		return testutil.ToFloat64(connectionsOpen.WithLabelValues(transportWebSocket))
	}

	before := openWebSocketConns()

	conn := dialTestHandler(t, handler)

	require.Eventually(t, func() bool {
		return openWebSocketConns() == before+1
	}, 5*time.Second, time.Millisecond,
		"connectionsOpen should increment while a connection is open")

	close(released)
	require.NoError(t, conn.Close())

	require.Eventually(t, func() bool {
		return openWebSocketConns() == before
	}, 15*time.Second, time.Millisecond,
		"connectionsOpen should return to its previous value once the connection closes")
}

// TestConnectionErrorsTotal verifies that connectionErrorsTotal increments with
// the correct error_type label in handleExecutionError, and does not increment
// on a clean EOF.
func TestConnectionErrorsTotal(t *testing.T) {
	t.Run("increments with 'other' label on generic runner execution error", func(t *testing.T) {
		t.Skip("Pending fix: https://gitlab.com/gitlab-org/gitlab/-/work_items/595283")
		before := counterVecValue(t, connectionErrorsTotal, transportWebSocket, errorTypeOther)

		h := &Handler{}
		r := httptest.NewRequest(http.MethodGet, "/", nil)
		grpcErr := status.Error(codes.Internal, "boom")
		sm := newTestStreamManager(t, &mockWorkflowStream{recvError: grpcErr})
		runner := &runner{streamManager: sm, client: newWsManager(&mockWebSocketConn{}), mcpManager: &mockMcpManager{}}

		h.registerAndExecuteRunner(r, transportWebSocket, runner, func(error) {})

		require.InDelta(t, before+1, counterVecValue(t, connectionErrorsTotal, transportWebSocket, errorTypeOther), 0,
			"connectionErrorsTotal{error_type=other} should increment on generic runner execution error")
	})

	t.Run("increments with 'quota_exceeded' label on usage quota exceeded error", func(t *testing.T) {
		before := counterVecValue(t, connectionErrorsTotal, transportWebSocket, errorTypeQuotaExceeded)

		h := &Handler{}
		r := httptest.NewRequest(http.MethodGet, "/", nil)
		h.handleWebSocketExecutionError(r, newServerSideConn(t), errUsageQuotaExceededError)

		require.InDelta(t, before+1, counterVecValue(t, connectionErrorsTotal, transportWebSocket, errorTypeQuotaExceeded), 0,
			"connectionErrorsTotal{error_type=quota_exceeded} should increment on quota exceeded error")
	})

	t.Run("increments with 'locked' label on failed to acquire lock error", func(t *testing.T) {
		before := counterVecValue(t, connectionErrorsTotal, transportWebSocket, errorTypeLocked)

		h := &Handler{}
		r := httptest.NewRequest(http.MethodGet, "/", nil)
		h.handleWebSocketExecutionError(r, newServerSideConn(t), errFailedToAcquireLockError)

		require.InDelta(t, before+1, counterVecValue(t, connectionErrorsTotal, transportWebSocket, errorTypeLocked), 0,
			"connectionErrorsTotal{error_type=locked} should increment on lock acquisition failure")
	})

	t.Run("does not increment on clean EOF", func(t *testing.T) {
		seriesBefore := testutil.CollectAndCount(connectionErrorsTotal)

		h := &Handler{}
		r := httptest.NewRequest(http.MethodGet, "/", nil)
		// Block the WebSocket reader so the gRPC EOF side wins the race and
		// Execute returns nil — matching how the existing runner tests handle this.
		sm := newTestStreamManager(t, &mockWorkflowStream{recvError: io.EOF})
		runner := &runner{
			streamManager: sm,
			client:        newWsManager(&mockWebSocketConn{blockCh: make(chan bool)}),
			mcpManager:    &mockMcpManager{},
		}

		h.registerAndExecuteRunner(r, transportWebSocket, runner, func(error) {})

		require.Equal(t, seriesBefore, testutil.CollectAndCount(connectionErrorsTotal),
			"connectionErrorsTotal must not create new series for a clean EOF")
	})
}

// TestSessionsTotal verifies that sessionsTotal increments exactly once for each
// successful ExecuteWorkflow stream opened by newStreamManager.
func TestSessionsTotal(t *testing.T) {
	server := setupTestServer(t)

	before := counterValue(t, sessionsTotal)

	r := httptest.NewRequest(http.MethodGet, "/", nil)
	sm, err := newStreamManager(r, testDuoWorkflowConfig(server))
	require.NoError(t, err)
	defer sm.Close() //nolint:errcheck

	require.InDelta(t, before+1, counterValue(t, sessionsTotal), 0,
		"sessionsTotal should increment by 1 when ExecuteWorkflow succeeds")
}

// TestSessionErrorsTotal verifies that sessionErrorsTotal is labeled with the
// correct gRPC code for each kind of receive error, and is not incremented for
// the expected io.EOF.
func TestSessionErrorsTotal(t *testing.T) {
	tests := []struct {
		name         string
		recvError    error
		wantCode     string
		wantIncrease bool
	}{
		{
			name:         "Internal gRPC error",
			recvError:    status.Error(codes.Internal, "internal server error"),
			wantCode:     codes.Internal.String(),
			wantIncrease: true,
		},
		{
			name:         "Unavailable gRPC error",
			recvError:    status.Error(codes.Unavailable, "service unavailable"),
			wantCode:     codes.Unavailable.String(),
			wantIncrease: true,
		},
		{
			name:         "ResourceExhausted quota exceeded",
			recvError:    status.Error(codes.ResourceExhausted, "USAGE_QUOTA_EXCEEDED"),
			wantCode:     codes.ResourceExhausted.String(),
			wantIncrease: true,
		},
		{
			name:         "DeadlineExceeded gRPC error",
			recvError:    status.Error(codes.DeadlineExceeded, "deadline exceeded"),
			wantCode:     codes.DeadlineExceeded.String(),
			wantIncrease: true,
		},
		{
			name:         "plain Go error maps to Unknown",
			recvError:    io.ErrUnexpectedEOF,
			wantCode:     codes.Unknown.String(),
			wantIncrease: true,
		},
		{
			name:         "EOF does not increment",
			recvError:    io.EOF,
			wantIncrease: false,
		},
	}

	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			if tt.wantIncrease {
				beforeCode := counterVecValue(t, sessionErrorsTotal, tt.wantCode)

				sm := newTestStreamManager(t, &mockWorkflowStream{recvError: tt.recvError})
				_, _ = sm.Recv()

				require.InDelta(t, beforeCode+1,
					counterVecValue(t, sessionErrorsTotal, tt.wantCode), 0,
					"sessionErrorsTotal{grpc_code=%q} should increment by 1", tt.wantCode)
			} else {
				// io.EOF is a normal workflow termination — the total number of
				// reported time series must not grow. We use CollectAndCount to
				// avoid calling WithLabelValues, which would itself create a new
				// series as a side-effect.
				seriesBefore := testutil.CollectAndCount(sessionErrorsTotal)

				sm := newTestStreamManager(t, &mockWorkflowStream{recvError: tt.recvError})
				_, _ = sm.Recv()

				require.Equal(t, seriesBefore, testutil.CollectAndCount(sessionErrorsTotal),
					"sessionErrorsTotal must not create new series for EOF")
			}
		})
	}
}
