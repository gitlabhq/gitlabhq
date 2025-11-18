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
	req := msg.GetStartRequest()
	if req == nil {
		return fmt.Errorf("request is missing")
	}

	if req.Goal != "create workflow" {
		return fmt.Errorf("invalid goal: %v", req.Goal)
	}
	testAction := &pb.Action{
		Action: &pb.Action_RunCommand{
			RunCommand: &pb.RunCommandAction{Program: "ls"},
		},
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

		startEvent := &pb.ClientEvent{
			Response: &pb.ClientEvent_StartRequest{
				StartRequest: &pb.StartWorkflowRequest{
					Goal: "create workflow",
				},
			},
		}

		err = workflowStream.Send(startEvent)
		require.NoError(t, err)

		response, err := workflowStream.Recv()
		require.NoError(t, err)

		require.NotNil(t, response.GetRunCommand())

		err = workflowStream.CloseSend()
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
		_, err = workflowStream.Recv()
		require.Error(t, err)
		require.Equal(t, codes.Internal, status.Code(err))
	})

	// t.Run("client sends invalid request", func(t *testing.T) {
	// 	client := createTestClient(t, server)
	// 	workflowStream, err := client.ExecuteWorkflow(ctx)
	// 	require.NoError(t, err)

	// 	invalidEvent := &pb.ClientEvent{}

	// 	err = workflowStream.Send(invalidEvent)
	// 	require.NoError(t, err)

	// 	_, err = workflowStream.Recv()
	// 	require.Error(t, err)
	// })
}

func createTestClient(t *testing.T, server *testServer) *Client {
	client, err := NewClient(server.Addr, map[string]string{"test": "header"}, false, "visual-studio-code/0.0.1")
	require.NoError(t, err)
	t.Cleanup(func() { _ = client.Close() })
	return client
}
