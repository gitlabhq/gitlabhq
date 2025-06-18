package duoworkflow

import (
	"net/http"
	"net/http/httptest"
	"strings"
	"testing"

	"github.com/gorilla/websocket"
	"github.com/stretchr/testify/mock"
	"github.com/stretchr/testify/require"
	"google.golang.org/grpc/codes"
	"google.golang.org/grpc/status"

	pb "gitlab.com/gitlab-org/modelops/applied-ml/code-suggestions/ai-assist/clients/gopb/contract"

	"gitlab.com/gitlab-org/gitlab/workhorse/internal/api"
	"gitlab.com/gitlab-org/gitlab/workhorse/internal/testhelper"
)

func TestHandler(t *testing.T) {
	testhelper.ConfigureSecret()

	t.Run("successful workflow execution", func(t *testing.T) {
		server := setupTestServer(t)

		mockAPI := &mockAPI{}
		mockAPI.On("PreAuthorizeHandler", mock.Anything, "").Return(http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
			mockAPI.apiHandlerFunc(w, r, &api.Response{
				DuoWorkflow: &api.DuoWorkflow{
					ServiceURI: server.Addr,
					Headers:    map[string]string{"Authorization": "Bearer test"},
					Secure:     false,
				},
			})
		}))

		httpServer := httptest.NewServer(Handler(mockAPI))
		defer httpServer.Close()

		wsURL := "ws" + strings.TrimPrefix(httpServer.URL, "http") + "/duo"

		wsDialer := websocket.Dialer{}
		wsConn, resp, err := wsDialer.Dial(wsURL, nil)
		if resp != nil {
			_ = resp.Body.Close()
		}
		require.NoError(t, err)
		defer wsConn.Close()

		testMessage := []byte(`{"startRequest": {"goal": "create workflow"}}`)
		err = wsConn.WriteMessage(websocket.BinaryMessage, testMessage)
		require.NoError(t, err)

		messageType, response, err := wsConn.ReadMessage()
		require.NoError(t, err)
		require.Equal(t, websocket.BinaryMessage, messageType)
		require.Contains(t, string(response), `"runCommand"`)
	})

	t.Run("unauthorized request", func(t *testing.T) {
		mockAPI := &mockAPI{}
		mockAPI.On("PreAuthorizeHandler", mock.Anything, "").Return(http.HandlerFunc(func(w http.ResponseWriter, _ *http.Request) {
			w.WriteHeader(http.StatusUnauthorized)
		}))

		server := httptest.NewServer(Handler(mockAPI))
		defer server.Close()

		wsURL := "ws" + strings.TrimPrefix(server.URL, "http") + "/duo"

		dialer := websocket.Dialer{}
		_, resp, err := dialer.Dial(wsURL, nil)
		if resp != nil {
			defer resp.Body.Close()
		}
		require.Error(t, err)
		require.Equal(t, http.StatusUnauthorized, resp.StatusCode)
	})

	t.Run("grpc server error", func(t *testing.T) {
		server := setupTestServer(t)

		server.execWorkflowHandler = func(_ pb.DuoWorkflow_ExecuteWorkflowServer) error {
			return status.Error(codes.Internal, "internal server error")
		}

		mockAPI := &mockAPI{}
		mockAPI.On("PreAuthorizeHandler", mock.Anything, "").Return(http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
			mockAPI.apiHandlerFunc(w, r, &api.Response{
				DuoWorkflow: &api.DuoWorkflow{
					ServiceURI: "localhost:8001",
					Headers:    map[string]string{},
					Secure:     false,
				},
			})
		}))

		httpServer := httptest.NewServer(Handler(mockAPI))
		defer httpServer.Close()

		wsURL := "ws" + strings.TrimPrefix(httpServer.URL, "http") + "/duo"

		wsDialer := websocket.Dialer{}
		wsConn, resp, err := wsDialer.Dial(wsURL, nil)
		if resp != nil {
			_ = resp.Body.Close()
		}
		require.NoError(t, err)
		defer wsConn.Close()

		testMessage := []byte(`{"startRequest": {"goal": "create workflow"}}`)
		err = wsConn.WriteMessage(websocket.BinaryMessage, testMessage)
		require.NoError(t, err)

		_, _, err = wsConn.ReadMessage()
		require.Error(t, err)
	})

	t.Run("invalid service URL", func(t *testing.T) {
		mockAPI := &mockAPI{}
		mockAPI.On("PreAuthorizeHandler", mock.Anything, "").Return(http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
			mockAPI.apiHandlerFunc(w, r, &api.Response{
				DuoWorkflow: &api.DuoWorkflow{
					ServiceURI: "invalid://url",
					Headers:    map[string]string{},
					Secure:     false,
				},
			})
		}))

		httpServer := httptest.NewServer(Handler(mockAPI))
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
	})
}

type mockAPI struct {
	mock.Mock
	apiHandlerFunc api.HandleFunc
}

func (m *mockAPI) PreAuthorizeHandler(handleFunc api.HandleFunc, _ string) http.Handler {
	m.apiHandlerFunc = handleFunc
	args := m.Called(handleFunc, "")
	return args.Get(0).(http.Handler)
}
