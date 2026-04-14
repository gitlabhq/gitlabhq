package git

import (
	"net/http"
	"net/http/httptest"
	"testing"

	"github.com/stretchr/testify/require"
	"google.golang.org/grpc"

	"gitlab.com/gitlab-org/gitaly/v18/proto/go/gitalypb"

	"gitlab.com/gitlab-org/gitlab/workhorse/internal/api"
)

func TestSetBlobHeaders(t *testing.T) {
	w := httptest.NewRecorder()
	w.Header().Set("Set-Cookie", "gitlab_cookie=123456")

	setBlobHeaders(w)

	require.Empty(t, w.Header().Get("Set-Cookie"), "remove Set-Cookie")
}

type mockBlobServer struct {
	gitalypb.UnimplementedBlobServiceServer
	getBlobFunc func(*gitalypb.GetBlobRequest, gitalypb.BlobService_GetBlobServer) error
}

func (s *mockBlobServer) GetBlob(req *gitalypb.GetBlobRequest, stream gitalypb.BlobService_GetBlobServer) error {
	return s.getBlobFunc(req, stream)
}

func TestBlobInject(t *testing.T) {
	runInjectTests(t, SendBlob, []injectTest{
		{
			name: "invalid sendData",
			sendData: func(_ *testing.T) string {
				return "git-blob:not-valid-base64!"
			},
			expectedCode: http.StatusInternalServerError,
		},
		{
			name: "gitaly connection error",
			sendData: func(t *testing.T) string {
				return encodeSendData(t, "git-blob:", blobParams{
					GitalyServer: api.GitalyServer{Address: "unix:///invalid/does/not/exist/gitaly.sock"},
					GetBlobRequest: gitalypb.GetBlobRequest{
						Repository: &gitalypb.Repository{StorageName: "default", RelativePath: "test.git"},
						Oid:        "abc123",
					},
				})
			},
			expectedCode: http.StatusInternalServerError,
		},
		{
			name: "successful blob",
			sendData: func(t *testing.T) string {
				addr := startGRPCServer(t, func(srv *grpc.Server) {
					gitalypb.RegisterBlobServiceServer(srv, &mockBlobServer{
						getBlobFunc: func(req *gitalypb.GetBlobRequest, stream gitalypb.BlobService_GetBlobServer) error {
							data := []byte("test blob content")
							return stream.Send(&gitalypb.GetBlobResponse{
								Oid:  req.GetOid(),
								Size: int64(len(data)),
								Data: data,
							})
						},
					})
				})
				return encodeSendData(t, "git-blob:", blobParams{
					GitalyServer: api.GitalyServer{Address: addr},
					GetBlobRequest: gitalypb.GetBlobRequest{
						Repository: &gitalypb.Repository{StorageName: "default", RelativePath: "test.git"},
						Oid:        "abc123",
					},
				})
			},
			setup: func(w *httptest.ResponseRecorder) {
				w.Header().Set("Set-Cookie", "test-cookie=value")
			},
			expectedCode: http.StatusOK,
			expectedBody: "test blob content",
			expectedHeaders: map[string]string{
				"Content-Length": "17",
			},
			removedHeaders: []string{"Set-Cookie"},
		},
	})
}
