package git

import (
	"bytes"
	"encoding/json"
	"io"
	"net/http"
	"net/http/httptest"
	"testing"

	"github.com/stretchr/testify/require"
	"google.golang.org/grpc/codes"
	"google.golang.org/grpc/metadata"
	"google.golang.org/grpc/status"

	"gitlab.com/gitlab-org/gitlab/workhorse/internal/gitaly"

	"gitlab.com/gitlab-org/gitaly/v16/proto/go/gitalypb"

	"gitlab.com/gitlab-org/gitlab/workhorse/internal/api"
)

type capturedReceivePackRequest struct {
	metadata     map[string]string
	repository   *gitalypb.Repository
	glID         string
	glUsername   string
	glRepository string
}

type mockReceivePackServer struct {
	gitalypb.UnimplementedSmartHTTPServiceServer
	receivePackFunc func(gitalypb.SmartHTTPService_PostReceivePackServer) error
	captured        *capturedReceivePackRequest
}

func (s *mockReceivePackServer) PostReceivePack(stream gitalypb.SmartHTTPService_PostReceivePackServer) error {
	s.captured = &capturedReceivePackRequest{}

	md, _ := metadata.FromIncomingContext(stream.Context())
	clientContextMetadata := md.Get(gitaly.ClientContextMetadataKey)
	json.Unmarshal([]byte(clientContextMetadata[0]), &s.captured.metadata)

	req, _ := stream.Recv()
	s.captured.repository = req.Repository
	s.captured.glID = req.GlId
	s.captured.glUsername = req.GlUsername
	s.captured.glRepository = req.GlRepository

	return s.receivePackFunc(stream)
}

func apiResponseFixture(addr string) *api.Response {
	return &api.Response{
		GitalyServer: api.GitalyServer{
			Address: addr,
		},
		Repository: gitalypb.Repository{
			StorageName:  "default",
			RelativePath: "test-repo.git",
		},
		GL_ID:          "user-123",
		GL_USERNAME:    "testuser",
		GL_REPOSITORY:  "project-456",
		GlScopedUserID: "user-456",
	}
}

func TestHandleReceivePack_Success(t *testing.T) {
	requestData := "test request data"
	responseData := "test response data"

	mockServer := &mockReceivePackServer{
		receivePackFunc: func(stream gitalypb.SmartHTTPService_PostReceivePackServer) error {
			for {
				_, err := stream.Recv()
				if err == io.EOF {
					break
				}
			}
			return stream.Send(&gitalypb.PostReceivePackResponse{Data: []byte(responseData)})
		},
	}

	addr := startSmartHTTPServer(t, mockServer)

	w := httptest.NewRecorder()
	r := httptest.NewRequest(http.MethodPost, "/test-repo.git/git-receive-pack", bytes.NewBufferString(requestData))

	apiResponse := apiResponseFixture(addr)

	stats, err := handleReceivePack(NewHTTPResponseWriter(w), r, apiResponse)
	require.NoError(t, err)
	require.Nil(t, stats)

	require.Equal(t, http.StatusOK, w.Code)
	require.Contains(t, w.Header().Get("Content-Type"), "application/x-git-receive-pack-result")
	require.Equal(t, "no-cache", w.Header().Get("Cache-Control"))
	require.Equal(t, responseData, w.Body.String())

	// validate server metadata
	require.NotEmpty(t, mockServer.captured.metadata, "client context metadata should be present")
	require.Equal(t, "user-456", mockServer.captured.metadata["scoped-user-id"])
	require.Equal(t, "default", mockServer.captured.repository.StorageName)
	require.Equal(t, "test-repo.git", mockServer.captured.repository.RelativePath)
	require.Equal(t, "user-123", mockServer.captured.glID)
	require.Equal(t, "testuser", mockServer.captured.glUsername)
	require.Equal(t, "project-456", mockServer.captured.glRepository)
}

func TestHandleReceivePack_GitalyError(t *testing.T) {
	mockServer := &mockReceivePackServer{
		receivePackFunc: func(_ gitalypb.SmartHTTPService_PostReceivePackServer) error {
			return status.Error(codes.Internal, "gitaly internal error")
		},
	}

	addr := startSmartHTTPServer(t, mockServer)

	w := httptest.NewRecorder()
	r := httptest.NewRequest(http.MethodPost, "/test-repo.git/git-receive-pack", bytes.NewBufferString("test"))

	apiResponse := apiResponseFixture(addr)

	_, err := handleReceivePack(NewHTTPResponseWriter(w), r, apiResponse)
	require.Error(t, err)
	require.ErrorContains(t, err, "smarthttp.ReceivePack")
}
