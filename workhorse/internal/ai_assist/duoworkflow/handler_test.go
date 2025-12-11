package duoworkflow

import (
	"context"
	"net/http"
	"net/http/httptest"
	"net/url"
	"strings"
	"testing"
	"time"

	"github.com/gorilla/websocket"
	"github.com/stretchr/testify/assert"
	"github.com/stretchr/testify/require"
	"google.golang.org/grpc/codes"
	"google.golang.org/grpc/status"

	pb "gitlab.com/gitlab-org/modelops/applied-ml/code-suggestions/ai-assist/clients/gopb/contract"

	"gitlab.com/gitlab-org/gitlab/workhorse/internal/api"
	"gitlab.com/gitlab-org/gitlab/workhorse/internal/testhelper"
)

func setupAPIServer(t *testing.T, responseBody string) (*httptest.Server, *api.API) {
	t.Helper()

	apiServer := httptest.NewServer(http.HandlerFunc(func(w http.ResponseWriter, _ *http.Request) {
		w.Header().Set("Content-Type", api.ResponseContentType)
		w.WriteHeader(http.StatusOK)
		_, err := w.Write([]byte(responseBody))
		assert.NoError(t, err)
	}))

	apiURL, err := url.Parse(apiServer.URL)
	require.NoError(t, err)

	apiClient := api.NewAPI(apiURL, "test-version", http.DefaultTransport)
	return apiServer, apiClient
}

func TestHandler_SuccessfulWorkflowExecution(t *testing.T) {
	testhelper.ConfigureSecret()

	server := setupTestServer(t)

	apiServer, apiClient := setupAPIServer(t, `{
		"DuoWorkflow": {
			"ServiceURI": "`+server.Addr+`",
			"Headers": {"Authorization": "Bearer test"},
			"Secure": false
		}
	}`)
	defer apiServer.Close()

	httpServer := httptest.NewServer(NewHandler(apiClient, initRdb(t), http.HandlerFunc(func(_ http.ResponseWriter, _ *http.Request) {})).Build())
	defer httpServer.Close()

	wsURL := "ws" + strings.TrimPrefix(httpServer.URL, "http") + "/duo"

	wsDialer := websocket.Dialer{}
	wsConn, resp, err := wsDialer.Dial(wsURL, nil)
	if resp != nil {
		_ = resp.Body.Close()
	}
	require.NoError(t, err)
	defer wsConn.Close()

	testMessage := []byte(`{"startRequest": {"workflowID": "id-123", "goal": "create workflow"}}`)
	err = wsConn.WriteMessage(websocket.BinaryMessage, testMessage)
	require.NoError(t, err)

	messageType, response, err := wsConn.ReadMessage()
	require.NoError(t, err)
	require.Equal(t, websocket.BinaryMessage, messageType)
	require.Contains(t, string(response), `"runCommand"`)
}

func TestHandler_UnauthorizedRequest(t *testing.T) {
	testhelper.ConfigureSecret()

	apiServer := httptest.NewServer(http.HandlerFunc(func(w http.ResponseWriter, _ *http.Request) {
		w.WriteHeader(http.StatusUnauthorized)
	}))
	defer apiServer.Close()

	apiURL, err := url.Parse(apiServer.URL)
	require.NoError(t, err)

	apiClient := api.NewAPI(apiURL, "test-version", http.DefaultTransport)

	server := httptest.NewServer(NewHandler(apiClient, initRdb(t), http.HandlerFunc(func(_ http.ResponseWriter, _ *http.Request) {})).Build())
	defer server.Close()

	wsURL := "ws" + strings.TrimPrefix(server.URL, "http") + "/duo"

	dialer := websocket.Dialer{}
	_, resp, err := dialer.Dial(wsURL, nil)
	if resp != nil {
		defer resp.Body.Close()
	}
	require.Error(t, err)
	require.Equal(t, http.StatusUnauthorized, resp.StatusCode)
}

func TestHandler_GrpcServerError(t *testing.T) {
	testhelper.ConfigureSecret()

	server := setupTestServer(t)
	server.execWorkflowHandler = func(_ pb.DuoWorkflow_ExecuteWorkflowServer) error {
		return status.Error(codes.Internal, "internal server error")
	}

	apiServer, apiClient := setupAPIServer(t, `{
		"DuoWorkflow": {
			"ServiceURI": "`+server.Addr+`",
			"Headers": {},
			"Secure": false
		}
	}`)
	defer apiServer.Close()

	httpServer := httptest.NewServer(NewHandler(apiClient, initRdb(t), http.HandlerFunc(func(_ http.ResponseWriter, _ *http.Request) {})).Build())
	defer httpServer.Close()

	wsURL := "ws" + strings.TrimPrefix(httpServer.URL, "http") + "/duo"

	wsDialer := websocket.Dialer{}
	wsConn, resp, err := wsDialer.Dial(wsURL, nil)
	if resp != nil {
		_ = resp.Body.Close()
	}
	require.NoError(t, err)
	defer wsConn.Close()

	testMessage := []byte(`{"startRequest": {"workflowID": "id-123", "goal": "create workflow"}}`)
	err = wsConn.WriteMessage(websocket.BinaryMessage, testMessage)
	require.NoError(t, err)

	_, _, err = wsConn.ReadMessage()
	require.Error(t, err)
}

func TestHandler_InvalidServiceURL(t *testing.T) {
	testhelper.ConfigureSecret()

	apiServer, apiClient := setupAPIServer(t, `{
		"DuoWorkflow": {
			"ServiceURI": "invalid://url",
			"Headers": {},
			"Secure": false
		}
	}`)
	defer apiServer.Close()

	httpServer := httptest.NewServer(NewHandler(apiClient, initRdb(t), http.HandlerFunc(func(_ http.ResponseWriter, _ *http.Request) {})).Build())
	defer httpServer.Close()

	wsURL := "ws" + strings.TrimPrefix(httpServer.URL, "http") + "/duo"

	dialer := websocket.Dialer{}
	wsConn, resp, err := dialer.Dial(wsURL, nil)
	if resp != nil {
		defer resp.Body.Close()
	}
	if err == nil {
		defer wsConn.Close()
		_, _, err = wsConn.ReadMessage()
		require.Error(t, err)
	} else {
		require.Equal(t, http.StatusInternalServerError, resp.StatusCode)
	}
}

func TestHandler_ShutdownWithNoActiveRunners(t *testing.T) {
	testhelper.ConfigureSecret()

	apiClient := api.NewAPI(nil, "test-version", http.DefaultTransport)
	handler := NewHandler(apiClient, initRdb(t), http.HandlerFunc(func(_ http.ResponseWriter, _ *http.Request) {}))

	ctx, cancel := context.WithTimeout(context.Background(), 1*time.Second)
	defer cancel()

	err := handler.Shutdown(ctx)
	require.NoError(t, err)
}

func TestHandler_ShutdownWithActiveRunners(t *testing.T) {
	testhelper.ConfigureSecret()

	server := setupTestServer(t)
	startReceived := make(chan bool, 1)
	stopReceived := make(chan bool, 1)
	server.execWorkflowHandler = func(stream pb.DuoWorkflow_ExecuteWorkflowServer) error {
		for {
			msg, err := stream.Recv()
			if err != nil {
				return err
			}
			if msg.GetStartRequest() != nil {
				startReceived <- true
			}
			if msg.GetStopWorkflow() != nil {
				stopReceived <- true
				return nil
			}
		}
	}

	apiServer, apiClient := setupAPIServer(t, `{
		"DuoWorkflow": {
			"ServiceURI": "`+server.Addr+`",
			"Headers": {},
			"Secure": false
		}
	}`)
	defer apiServer.Close()

	handler := NewHandler(apiClient, initRdb(t), http.HandlerFunc(func(_ http.ResponseWriter, _ *http.Request) {}))

	httpServer := httptest.NewServer(handler.Build())
	defer httpServer.Close()

	wsURL := "ws" + strings.TrimPrefix(httpServer.URL, "http") + "/duo"
	wsDialer := websocket.Dialer{}
	wsConn, resp, err := wsDialer.Dial(wsURL, nil)
	if resp != nil {
		_ = resp.Body.Close()
	}
	require.NoError(t, err)
	defer wsConn.Close()

	testMessage := []byte(`{"startRequest": {"workflowID": "id-123", "goal": "test"}}`)
	err = wsConn.WriteMessage(websocket.BinaryMessage, testMessage)
	require.NoError(t, err)

	waitDone(t, startReceived)
	ctx, cancel := context.WithTimeout(context.Background(), 500*time.Millisecond)
	defer cancel()

	err = handler.Shutdown(ctx)
	require.NoError(t, err)
	waitDone(t, stopReceived)
}

func TestHandler_FailedToAcquireLock(t *testing.T) {
	testhelper.ConfigureSecret()

	server := setupTestServer(t)

	apiServer, apiClient := setupAPIServer(t, `{
		"DuoWorkflow": {
			"ServiceURI": "`+server.Addr+`",
			"Headers": {"Authorization": "Bearer test"},
			"Secure": false,
			"LockConcurrentFlow": true
		}
	}`)
	defer apiServer.Close()

	rdb := initRdb(t)

	// Simulate the lock already being acquired
	rdb.Set(context.Background(), workflowLockPrefix+"id-123", "1", time.Minute)

	httpServer := httptest.NewServer(NewHandler(apiClient, rdb, http.HandlerFunc(func(_ http.ResponseWriter, _ *http.Request) {})).Build())
	defer httpServer.Close()

	wsURL := "ws" + strings.TrimPrefix(httpServer.URL, "http") + "/duo"

	wsDialer := websocket.Dialer{}
	wsConn, resp, err := wsDialer.Dial(wsURL, nil)
	if resp != nil {
		_ = resp.Body.Close()
	}
	require.NoError(t, err)
	defer wsConn.Close()

	testMessage := []byte(`{"startRequest": {"workflowID": "id-123", "goal": "create workflow"}}`)
	err = wsConn.WriteMessage(websocket.BinaryMessage, testMessage)
	require.NoError(t, err)

	_, _, err = wsConn.ReadMessage()
	require.Error(t, err)
	require.Equal(t, "websocket: close 1013: Failed to acquire lock on workflow", err.Error())
}

func TestHandler_IgnoresLockWhenLockConcurrentFlowDisabled(t *testing.T) {
	testhelper.ConfigureSecret()

	server := setupTestServer(t)

	apiServer, apiClient := setupAPIServer(t, `{
		"DuoWorkflow": {
			"ServiceURI": "`+server.Addr+`",
			"Headers": {"Authorization": "Bearer test"},
			"Secure": false,
			"LockConcurrentFlow": false
		}
	}`)
	defer apiServer.Close()

	rdb := initRdb(t)

	// Simulate the lock already being acquired
	rdb.Set(context.Background(), workflowLockPrefix+"id-123", "1", time.Minute)

	httpServer := httptest.NewServer(NewHandler(apiClient, rdb, http.HandlerFunc(func(_ http.ResponseWriter, _ *http.Request) {})).Build())
	defer httpServer.Close()

	wsURL := "ws" + strings.TrimPrefix(httpServer.URL, "http") + "/duo"

	wsDialer := websocket.Dialer{}
	wsConn, resp, err := wsDialer.Dial(wsURL, nil)
	if resp != nil {
		_ = resp.Body.Close()
	}
	require.NoError(t, err)
	defer wsConn.Close()

	testMessage := []byte(`{"startRequest": {"workflowID": "id-123", "goal": "create workflow"}}`)
	err = wsConn.WriteMessage(websocket.BinaryMessage, testMessage)
	require.NoError(t, err)

	_, _, err = wsConn.ReadMessage()
	require.NoError(t, err)
}

func TestHandler_UsageQuotaExceeded(t *testing.T) {
	testhelper.ConfigureSecret()

	server := setupTestServer(t)
	server.execWorkflowHandler = func(_ pb.DuoWorkflow_ExecuteWorkflowServer) error {
		return status.Error(codes.ResourceExhausted, "USAGE_QUOTA_EXCEEDED: Consumer does not have sufficient credits for this request")
	}

	apiServer, apiClient := setupAPIServer(t, `{
		"DuoWorkflow": {
			"ServiceURI": "`+server.Addr+`",
			"Headers": {"Authorization": "Bearer test"},
			"Secure": false
		}
	}`)
	defer apiServer.Close()

	httpServer := httptest.NewServer(NewHandler(apiClient, initRdb(t), http.HandlerFunc(func(_ http.ResponseWriter, _ *http.Request) {})).Build())
	defer httpServer.Close()

	wsURL := "ws" + strings.TrimPrefix(httpServer.URL, "http") + "/duo"

	wsDialer := websocket.Dialer{}
	wsConn, resp, err := wsDialer.Dial(wsURL, nil)
	if resp != nil {
		_ = resp.Body.Close()
	}
	require.NoError(t, err)
	defer wsConn.Close()

	testMessage := []byte(`{"startRequest": {"workflowID": "id-123", "goal": "create workflow"}}`)
	err = wsConn.WriteMessage(websocket.BinaryMessage, testMessage)
	require.NoError(t, err)

	_, _, err = wsConn.ReadMessage()
	require.Error(t, err)
	require.Equal(t, "websocket: close 1008 (policy violation): Insufficient credits: quota exceeded", err.Error())
}

func waitDone(t *testing.T, done chan bool) {
	t.Helper()
	select {
	case <-done:
		return
	case <-time.After(10 * time.Second):
		t.Fatal("time out waiting request to arrive")
	}
}
