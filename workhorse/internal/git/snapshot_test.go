package git

import (
	"net/http"
	"net/http/httptest"
	"testing"

	"google.golang.org/grpc"
	"google.golang.org/protobuf/encoding/protojson"

	"github.com/stretchr/testify/require"

	"gitlab.com/gitlab-org/gitaly/v18/proto/go/gitalypb"

	"gitlab.com/gitlab-org/gitlab/workhorse/internal/api"
)

type mockRepositoryServer struct {
	gitalypb.UnimplementedRepositoryServiceServer
	getSnapshotFunc func(*gitalypb.GetSnapshotRequest, gitalypb.RepositoryService_GetSnapshotServer) error
}

func (s *mockRepositoryServer) GetSnapshot(req *gitalypb.GetSnapshotRequest, stream gitalypb.RepositoryService_GetSnapshotServer) error {
	return s.getSnapshotFunc(req, stream)
}

func TestSnapshotInject(t *testing.T) {
	runInjectTests(t, SendSnapshot, []injectTest{
		{
			name: "invalid sendData",
			sendData: func(_ *testing.T) string {
				return "git-snapshot:not-valid-base64!"
			},
			expectedCode: http.StatusInternalServerError,
		},
		{
			name: "invalid GetSnapshotRequest JSON",
			sendData: func(t *testing.T) string {
				return encodeSendData(t, "git-snapshot:", snapshotParams{
					GitalyServer:       api.GitalyServer{Address: "unix:///unused"},
					GetSnapshotRequest: "not valid protojson",
				})
			},
			expectedCode: http.StatusInternalServerError,
		},
		{
			name: "gitaly connection error",
			sendData: func(t *testing.T) string {
				snapshotReq := &gitalypb.GetSnapshotRequest{
					Repository: &gitalypb.Repository{StorageName: "default", RelativePath: "test.git"},
				}
				snapshotJSON, err := protojson.Marshal(snapshotReq)
				require.NoError(t, err)

				return encodeSendData(t, "git-snapshot:", snapshotParams{
					GitalyServer:       api.GitalyServer{Address: "unix:///invalid/does/not/exist/gitaly.sock"},
					GetSnapshotRequest: string(snapshotJSON),
				})
			},
			expectedCode: http.StatusInternalServerError,
		},
		{
			name: "successful snapshot",
			sendData: func(t *testing.T) string {
				addr := startGRPCServer(t, func(srv *grpc.Server) {
					gitalypb.RegisterRepositoryServiceServer(srv, &mockRepositoryServer{
						getSnapshotFunc: func(_ *gitalypb.GetSnapshotRequest, stream gitalypb.RepositoryService_GetSnapshotServer) error {
							return stream.Send(&gitalypb.GetSnapshotResponse{
								Data: []byte("tar archive data"),
							})
						},
					})
				})

				snapshotReq := &gitalypb.GetSnapshotRequest{
					Repository: &gitalypb.Repository{StorageName: "default", RelativePath: "test.git"},
				}
				snapshotJSON, err := protojson.Marshal(snapshotReq)
				require.NoError(t, err)

				return encodeSendData(t, "git-snapshot:", snapshotParams{
					GitalyServer:       api.GitalyServer{Address: addr},
					GetSnapshotRequest: string(snapshotJSON),
				})
			},
			setup: func(w *httptest.ResponseRecorder) {
				// Pre-set Content-Length to verify it's removed by the snapshot handler
				w.Header().Set("Content-Length", "12345")
			},
			expectedCode: http.StatusOK,
			expectedBody: "tar archive data",
			expectedHeaders: map[string]string{
				"Content-Disposition":       `attachment; filename="snapshot.tar"`,
				"Content-Type":              "application/x-tar",
				"Content-Transfer-Encoding": "binary",
				"Cache-Control":             "private",
			},
			removedHeaders: []string{"Content-Length"},
		},
	})
}
