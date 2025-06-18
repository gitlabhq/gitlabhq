package duoworkflow

import (
	"context"
	"fmt"
	"net"
	"testing"

	"github.com/stretchr/testify/require"
	pb "gitlab.com/gitlab-org/modelops/applied-ml/code-suggestions/ai-assist/clients/gopb/contract"
	"google.golang.org/grpc"
	"google.golang.org/grpc/codes"
	"google.golang.org/grpc/status"
)

// bufSize is no longer used but kept for future reference
// const bufSize = 1024 * 1024

type testServer struct {
	Addr string
	pb.UnimplementedDuoWorkflowServer
	execWorkflowHandler func(server pb.DuoWorkflow_ExecuteWorkflowServer) error
}

func (s *testServer) ExecuteWorkflow(stream pb.DuoWorkflow_ExecuteWorkflowServer) error {
	if s.execWorkflowHandler != nil {
		return s.execWorkflowHandler(stream)
	}

	msg, err := stream.Recv()
	if err != nil {
		return err
	}

	req := msg.Response.(*pb.ClientEvent_StartRequest)
	if req.StartRequest.Goal != "create workflow" {
		return fmt.Errorf("invalid goal: %v", req.StartRequest.Goal)
	}

	testAction := &pb.Action{
		Action: &pb.Action_RunCommand{},
	}

	return stream.Send(testAction)
}

func setupTestServer(t *testing.T) *testServer {
	listener, err := net.Listen("tcp", ":0")
	require.NoError(t, err)

	s := grpc.NewServer()
	server := &testServer{Addr: listener.Addr().String()}
	pb.RegisterDuoWorkflowServer(s, server)

	go func() {
		_ = s.Serve(listener)
	}()

	t.Cleanup(func() {
		s.Stop()
		listener.Close()
	})

	return server
}

func TestExecuteWorkflow(t *testing.T) {
	server := setupTestServer(t)

	ctx := context.Background()

	t.Run("successful workflow execution", func(t *testing.T) {
		client := createTestClient(t, server)

		workflowStream, err := client.ExecuteWorkflow(ctx)
		require.NoError(t, err)

		err = workflowStream.Send([]byte(`{"startRequest": {"goal": "create workflow"}}`))
		require.NoError(t, err)

		response, err := workflowStream.Recv()
		require.NoError(t, err)

		responseJSON := string(response)
		require.Contains(t, responseJSON, `"runCommand":`)

		err = workflowStream.Close()
		require.NoError(t, err)
	})

	t.Run("server returns error", func(t *testing.T) {
		expectedErr := status.Error(codes.Internal, "internal error")
		server.execWorkflowHandler = func(_ pb.DuoWorkflow_ExecuteWorkflowServer) error {
			return expectedErr
		}

		client := createTestClient(t, server)

		workflowStream, err := client.ExecuteWorkflow(ctx)
		require.NoError(t, err)

		err = workflowStream.Send([]byte(`{"type":"test_event"}`))
		require.NoError(t, err)

		_, err = workflowStream.Recv()
		require.Error(t, err)
		require.Equal(t, codes.Internal, status.Code(err))
	})

	t.Run("client sends invalid JSON", func(t *testing.T) {
		client := createTestClient(t, server)

		workflowStream, err := client.ExecuteWorkflow(ctx)
		require.NoError(t, err)

		err = workflowStream.Send([]byte(`invalid json`))
		require.Error(t, err)
	})
}

func TestWorkflowStream(t *testing.T) {
	server := setupTestServer(t)

	ctx := context.Background()

	t.Run("successful stream operations", func(t *testing.T) {
		client := createTestClient(t, server)

		stream, err := client.ExecuteWorkflow(ctx)
		require.NoError(t, err)

		err = stream.Send([]byte(`{"startRequest": {"goal": "create workflow"}}`))
		require.NoError(t, err)

		response, err := stream.Recv()
		require.NoError(t, err)

		responseStr := string(response)
		require.Contains(t, responseStr, `"runCommand":`)
	})
}

func createTestClient(t *testing.T, server *testServer) *Client {
	client, err := NewClient(server.Addr, map[string]string{"test": "header"}, false)
	require.NoError(t, err)

	t.Cleanup(func() { _ = client.Close() })

	return client
}
