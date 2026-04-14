package git

import (
	"net/http"
	"testing"

	"google.golang.org/grpc"
	"google.golang.org/protobuf/encoding/protojson"

	"github.com/stretchr/testify/require"

	"gitlab.com/gitlab-org/gitaly/v18/proto/go/gitalypb"

	"gitlab.com/gitlab-org/gitlab/workhorse/internal/api"
)

func TestDiffInject(t *testing.T) {
	runInjectTests(t, SendDiff, []injectTest{
		{
			name: "invalid sendData",
			sendData: func(_ *testing.T) string {
				return "git-diff:not-valid-base64!"
			},
			expectedCode: http.StatusInternalServerError,
		},
		{
			name: "invalid RawDiffRequest JSON",
			sendData: func(t *testing.T) string {
				return encodeSendData(t, "git-diff:", diffParams{
					GitalyServer:   api.GitalyServer{Address: "unix:///unused"},
					RawDiffRequest: "not valid protojson",
				})
			},
			expectedCode: http.StatusInternalServerError,
		},
		{
			name: "gitaly connection error",
			sendData: func(t *testing.T) string {
				rawDiffReq := &gitalypb.RawDiffRequest{
					Repository:    &gitalypb.Repository{StorageName: "default", RelativePath: "test.git"},
					LeftCommitId:  "abc123",
					RightCommitId: "def456",
				}
				rawDiffJSON, err := protojson.Marshal(rawDiffReq)
				require.NoError(t, err)

				return encodeSendData(t, "git-diff:", diffParams{
					GitalyServer:   api.GitalyServer{Address: "unix:///invalid/does/not/exist/gitaly.sock"},
					RawDiffRequest: string(rawDiffJSON),
				})
			},
			// gRPC connections are established lazily, so NewDiffClient succeeds.
			// The RPC error from SendRawDiff is only logged, not returned via fail.Request,
			// so the response code remains 200.
			expectedCode: http.StatusOK,
		},
		{
			name: "successful diff",
			sendData: func(t *testing.T) string {
				addr := startGRPCServer(t, func(srv *grpc.Server) {
					gitalypb.RegisterDiffServiceServer(srv, &mockDiffServiceServer{
						rawDiffFunc: func(_ *gitalypb.RawDiffRequest, stream gitalypb.DiffService_RawDiffServer) error {
							return stream.Send(&gitalypb.RawDiffResponse{
								Data: []byte("diff --git a/file b/file\n"),
							})
						},
					})
				})

				rawDiffReq := &gitalypb.RawDiffRequest{
					Repository:    &gitalypb.Repository{StorageName: "default", RelativePath: "test.git"},
					LeftCommitId:  "abc123",
					RightCommitId: "def456",
				}
				rawDiffJSON, err := protojson.Marshal(rawDiffReq)
				require.NoError(t, err)

				return encodeSendData(t, "git-diff:", diffParams{
					GitalyServer:   api.GitalyServer{Address: addr},
					RawDiffRequest: string(rawDiffJSON),
				})
			},
			expectedCode: http.StatusOK,
			expectedBody: "diff --git a/file b/file\n",
			expectedHeaders: map[string]string{
				"Content-Type": "text/plain; charset=utf-8",
			},
		},
	})
}
