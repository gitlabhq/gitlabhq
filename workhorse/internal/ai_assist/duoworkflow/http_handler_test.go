package duoworkflow

import (
	"bufio"
	"context"
	"fmt"
	"io"
	"net/http"
	"net/http/httptest"
	"net/url"
	"strings"
	"testing"
	"time"

	"github.com/stretchr/testify/assert"
	"github.com/stretchr/testify/require"
	"google.golang.org/grpc/codes"
	"google.golang.org/grpc/status"

	pb "gitlab.com/gitlab-org/modelops/applied-ml/code-suggestions/ai-assist/clients/gopb/contract"

	"gitlab.com/gitlab-org/gitlab/workhorse/internal/api"
	"gitlab.com/gitlab-org/gitlab/workhorse/internal/testhelper"
)

const testWorkflowID = "4711"

// setupExecuteHandler wires the server-side execution handler to a Rails
// pre-authorization stub that points at the given test gRPC server and
// authorizes testWorkflowID.
func setupExecuteHandler(t *testing.T, grpcServer *testServer) *httptest.Server {
	t.Helper()

	testhelper.ConfigureSecret()

	apiServer, apiClient := setupAPIServer(t, fmt.Sprintf(`{
		"DuoWorkflow": {
			"Service": {"URI": %q, "Headers": {}, "Secure": false},
			"WorkflowID": %q,
			"LockConcurrentFlow": true,
			"ServerCapabilities": ["job_trace_pagination"]
		}
	}`, grpcServer.Addr, testWorkflowID))
	t.Cleanup(apiServer.Close)

	backend := http.HandlerFunc(func(_ http.ResponseWriter, _ *http.Request) {})
	handler := NewHandler(apiClient, initRdb(t), backend, "").BuildHTTP()

	httpServer := httptest.NewServer(handler)
	t.Cleanup(httpServer.Close)

	return httpServer
}

// executeResponse is a fully consumed response from the endpoint.
type executeResponse struct {
	statusCode  int
	contentType string
	body        string
}

// postStartRequest starts a flow and reads the whole response, which is what
// every test here needs except the one that abandons the stream half way.
func postStartRequest(t *testing.T, server *httptest.Server, requestBody string) executeResponse {
	t.Helper()

	resp, err := server.Client().Post(server.URL+"/execute", "application/json", strings.NewReader(requestBody))
	require.NoError(t, err)

	defer func() { require.NoError(t, resp.Body.Close()) }()

	body, err := io.ReadAll(resp.Body)
	require.NoError(t, err)

	return executeResponse{
		statusCode:  resp.StatusCode,
		contentType: resp.Header.Get("Content-Type"),
		body:        string(body),
	}
}

// recvStartRequest reads the StartWorkflowRequest workhorse sent. It runs on
// the gRPC server's goroutine, so it reports a problem by returning an error to
// gRPC rather than by asserting; the test then sees it through the response.
func recvStartRequest(stream pb.DuoWorkflow_ExecuteWorkflowServer) (*pb.StartWorkflowRequest, error) {
	event, err := stream.Recv()
	if err != nil {
		return nil, err
	}

	startReq := event.GetStartRequest()
	if startReq == nil {
		return nil, fmt.Errorf("expected a start request, got %T", event.Response)
	}

	return startReq, nil
}

func TestBuildHTTP_StreamsCheckpointsToTheCaller(t *testing.T) {
	grpcServer := setupTestServer(t)
	grpcServer.execWorkflowHandler = func(stream pb.DuoWorkflow_ExecuteWorkflowServer) error {
		if _, err := recvStartRequest(stream); err != nil {
			return err
		}

		for _, id := range []string{"req-1", "req-2"} {
			if err := stream.Send(checkpointAction(id)); err != nil {
				return err
			}
		}

		// Returning ends the stream, which the caller sees as the end of the
		// response body.
		return nil
	}

	resp := postStartRequest(t, setupExecuteHandler(t, grpcServer), `{"goal": "fix the pipeline"}`)

	require.Equal(t, http.StatusOK, resp.statusCode)
	require.Equal(t, "application/x-ndjson", resp.contentType)

	actions := parseNdjsonActions(t, resp.body)
	require.Len(t, actions, 2)
	require.Equal(t, "req-1", actions[0].RequestID)
	require.Equal(t, "req-2", actions[1].RequestID)
}

func TestBuildHTTP_RejectsActionsTheCallerCannotExecute(t *testing.T) {
	responses := make(chan *pb.ActionResponse, 1)

	grpcServer := setupTestServer(t)
	grpcServer.execWorkflowHandler = func(stream pb.DuoWorkflow_ExecuteWorkflowServer) error {
		if _, err := recvStartRequest(stream); err != nil {
			return err
		}

		action := &pb.Action{
			RequestID: "req-run-command",
			Action:    &pb.Action_RunCommand{RunCommand: &pb.RunCommandAction{Program: "rm -rf /"}},
		}
		if err := stream.Send(action); err != nil {
			return err
		}

		event, err := stream.Recv()
		if err != nil {
			return err
		}
		responses <- event.GetActionResponse()

		return nil
	}

	resp := postStartRequest(t, setupExecuteHandler(t, grpcServer), `{"goal": "fix the pipeline"}`)
	require.Equal(t, http.StatusOK, resp.statusCode)
	require.Empty(t, parseNdjsonActions(t, resp.body), "an action the caller cannot execute must not be streamed to it")

	select {
	case response := <-responses:
		require.Equal(t, "req-run-command", response.RequestID)
		require.Contains(t, response.GetPlainTextResponse().Error, "cannot be executed by this client")
	case <-time.After(5 * time.Second):
		t.Fatal("timed out waiting for the action response")
	}
}

func TestBuildHTTP_StartRequest(t *testing.T) {
	tests := []struct {
		name         string
		body         string
		assertStart  func(*testing.T, *pb.StartWorkflowRequest)
		expectStatus int
	}{
		{
			name: "takes the workflow ID from Rails, not from the caller",
			body: `{"goal": "fix the pipeline"}`,
			assertStart: func(t *testing.T, startReq *pb.StartWorkflowRequest) {
				require.Equal(t, testWorkflowID, startReq.WorkflowID)
				require.Equal(t, "fix the pipeline", startReq.Goal)
			},
			expectStatus: http.StatusOK,
		},
		{
			name:         "accepts a matching workflow ID",
			body:         fmt.Sprintf(`{"workflowID": %q, "goal": "fix the pipeline"}`, testWorkflowID),
			expectStatus: http.StatusOK,
		},
		{
			name:         "rejects a workflow ID the caller was not authorized for",
			body:         `{"workflowID": "1", "goal": "fix the pipeline"}`,
			expectStatus: http.StatusBadRequest,
		},
		{
			name:         "rejects a body that is not a start request",
			body:         `not json`,
			expectStatus: http.StatusBadRequest,
		},
		{
			name: "drops the capabilities and tools the caller asked for",
			body: `{
				"goal": "fix the pipeline",
				"clientCapabilities": ["shell_command", "read_file_chunked"],
				"mcpTools": [{"name": "smuggled_tool"}],
				"preapprovedTools": ["smuggled_tool"]
			}`,
			assertStart: func(t *testing.T, startReq *pb.StartWorkflowRequest) {
				// Only the capabilities Rails reported survive, because
				// workhorse is not an executor and the caller does not get to
				// widen what the flow may do.
				require.Equal(t, []string{"job_trace_pagination"}, startReq.ClientCapabilities)
				require.Empty(t, startReq.McpTools)
				require.Empty(t, startReq.PreapprovedTools)
			},
			expectStatus: http.StatusOK,
		},
	}

	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			started := make(chan *pb.StartWorkflowRequest, 1)

			grpcServer := setupTestServer(t)
			grpcServer.execWorkflowHandler = func(stream pb.DuoWorkflow_ExecuteWorkflowServer) error {
				startReq, err := recvStartRequest(stream)
				if err != nil {
					return err
				}

				started <- startReq

				return nil
			}

			resp := postStartRequest(t, setupExecuteHandler(t, grpcServer), tt.body)

			require.Equal(t, tt.expectStatus, resp.statusCode)

			if tt.expectStatus != http.StatusOK {
				require.Empty(t, started, "a rejected request must not start a workflow")
				return
			}

			select {
			case startReq := <-started:
				require.NotNil(t, startReq)
				if tt.assertStart != nil {
					tt.assertStart(t, startReq)
				}
			case <-time.After(5 * time.Second):
				t.Fatal("timed out waiting for the start request")
			}
		})
	}
}

func TestBuildHTTP_RejectsAnOversizedBody(t *testing.T) {
	grpcServer := setupTestServer(t)
	grpcServer.execWorkflowHandler = func(_ pb.DuoWorkflow_ExecuteWorkflowServer) error {
		assert.Fail(t, "an oversized body must not start a workflow")
		return nil
	}

	body := fmt.Sprintf(`{"goal": %q}`, strings.Repeat("a", startRequestBodyLimit))

	resp := postStartRequest(t, setupExecuteHandler(t, grpcServer), body)

	require.Equal(t, http.StatusBadRequest, resp.statusCode)
}

func TestBuildHTTP_FailuresBeforeTheFirstAction(t *testing.T) {
	tests := []struct {
		name         string
		recvErr      error
		expectStatus int
	}{
		{
			name:         "quota exceeded",
			recvErr:      status.Error(codes.ResourceExhausted, "USAGE_QUOTA_EXCEEDED: out of credits"),
			expectStatus: http.StatusForbidden,
		},
		{
			name:         "request rejected by Duo Workflow Service",
			recvErr:      status.Error(codes.InvalidArgument, "goal is empty"),
			expectStatus: http.StatusBadRequest,
		},
		{
			name:         "internal Duo Workflow Service error",
			recvErr:      status.Error(codes.Internal, "boom"),
			expectStatus: http.StatusInternalServerError,
		},
	}

	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			grpcServer := setupTestServer(t)
			grpcServer.execWorkflowHandler = func(stream pb.DuoWorkflow_ExecuteWorkflowServer) error {
				if _, err := recvStartRequest(stream); err != nil {
					return err
				}

				return tt.recvErr
			}

			resp := postStartRequest(t, setupExecuteHandler(t, grpcServer), `{"goal": "fix the pipeline"}`)

			// Nothing has been streamed yet, so the failure is still reportable
			// as a status code rather than as a silently truncated stream.
			require.Equal(t, tt.expectStatus, resp.statusCode)
		})
	}
}

func TestBuildHTTP_RejectsAConcurrentRunOfTheSameWorkflow(t *testing.T) {
	// Buffered: the losing request also opens a stream to DWS before it finds
	// out that the lock is held, so this handler runs more than once.
	firstStarted := make(chan struct{}, 1)
	releaseFirst := make(chan struct{})

	grpcServer := setupTestServer(t)
	grpcServer.execWorkflowHandler = func(stream pb.DuoWorkflow_ExecuteWorkflowServer) error {
		// The losing request never sends a start request, so this errors for it.
		if event, err := stream.Recv(); err != nil || event.GetStartRequest() == nil {
			return nil
		}

		firstStarted <- struct{}{}
		<-releaseFirst

		return nil
	}

	server := setupExecuteHandler(t, grpcServer)

	go func() {
		resp, err := server.Client().Post(server.URL+"/execute", "application/json", strings.NewReader(`{"goal": "fix the pipeline"}`))
		if assert.NoError(t, err) {
			_, _ = io.Copy(io.Discard, resp.Body)
			_ = resp.Body.Close()
		}
	}()

	select {
	case <-firstStarted:
	case <-time.After(5 * time.Second):
		t.Fatal("timed out waiting for the first run to start")
	}
	defer close(releaseFirst)

	resp := postStartRequest(t, server, `{"goal": "fix the pipeline"}`)

	require.Equal(t, http.StatusConflict, resp.statusCode,
		"a workflow already running elsewhere must not be started again")
}

func TestBuildHTTP_TearsDownTheDwsStreamWhenTheCallerGoesAway(t *testing.T) {
	streamErrs := make(chan error, 1)

	grpcServer := setupTestServer(t)
	grpcServer.execWorkflowHandler = func(stream pb.DuoWorkflow_ExecuteWorkflowServer) error {
		if _, err := recvStartRequest(stream); err != nil {
			return err
		}

		// Commit the response so the caller can start reading and then hang up.
		if err := stream.Send(checkpointAction("req-1")); err != nil {
			return err
		}

		_, err := stream.Recv()
		streamErrs <- err

		return nil
	}

	server := setupExecuteHandler(t, grpcServer)

	ctx, cancel := context.WithCancel(context.Background())
	req, err := http.NewRequestWithContext(ctx, http.MethodPost, server.URL+"/execute", strings.NewReader(`{"goal": "fix the pipeline"}`))
	require.NoError(t, err)

	resp, err := server.Client().Do(req)
	require.NoError(t, err)

	// Read the first action so the response is definitely open, then abandon it.
	line, err := bufio.NewReader(resp.Body).ReadString('\n')
	require.NoError(t, err)
	require.Contains(t, line, "req-1")

	cancel()
	_ = resp.Body.Close()

	// The stream to Duo Workflow Service is derived from the request context, so
	// a caller that hangs up takes it down. That is what tells Duo Workflow
	// Service the run was abandoned; it cannot be told with a stop request,
	// because the stream carrying it is already gone.
	select {
	case err := <-streamErrs:
		require.Error(t, err, "DWS must observe that the run was abandoned")
		require.Equal(t, codes.Canceled, status.Code(err))
	case <-time.After(5 * time.Second):
		t.Fatal("timed out waiting for the stream to be torn down")
	}
}

func TestBuildHTTP_MisconfiguredPreAuthorization(t *testing.T) {
	tests := []struct {
		name         string
		response     string
		expectStatus int
	}{
		{
			name:         "no workflow ID authorized",
			response:     `{"DuoWorkflow": {"Service": {"URI": "localhost:1", "Secure": false}}}`,
			expectStatus: http.StatusInternalServerError,
		},
		{
			name:         "no service configuration",
			response:     `{"DuoWorkflow": {"WorkflowID": "1"}}`,
			expectStatus: http.StatusInternalServerError,
		},
		{
			name:         "no Duo Workflow configuration at all",
			response:     `{}`,
			expectStatus: http.StatusInternalServerError,
		},
	}

	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			testhelper.ConfigureSecret()

			apiServer, apiClient := setupAPIServer(t, tt.response)
			defer apiServer.Close()

			backend := http.HandlerFunc(func(_ http.ResponseWriter, _ *http.Request) {})
			server := httptest.NewServer(NewHandler(apiClient, initRdb(t), backend, "").BuildHTTP())
			defer server.Close()

			resp := postStartRequest(t, server, `{"goal": "fix the pipeline"}`)
			require.Equal(t, tt.expectStatus, resp.statusCode)
		})
	}
}

func TestBuildHTTP_PropagatesPreAuthorizationFailure(t *testing.T) {
	testhelper.ConfigureSecret()

	apiServer := httptest.NewServer(http.HandlerFunc(func(w http.ResponseWriter, _ *http.Request) {
		w.WriteHeader(http.StatusForbidden)
	}))
	defer apiServer.Close()

	apiURL, err := url.Parse(apiServer.URL)
	require.NoError(t, err)

	apiClient := api.NewAPI(apiURL, "test-version", http.DefaultTransport)
	backend := http.HandlerFunc(func(_ http.ResponseWriter, _ *http.Request) {})

	server := httptest.NewServer(NewHandler(apiClient, initRdb(t), backend, "").BuildHTTP())
	defer server.Close()

	resp := postStartRequest(t, server, `{"goal": "fix the pipeline"}`)

	require.Equal(t, http.StatusForbidden, resp.statusCode)
}
