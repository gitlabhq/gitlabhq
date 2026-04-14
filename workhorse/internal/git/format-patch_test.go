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

func TestPatchInject(t *testing.T) {
	runInjectTests(t, SendPatch, []injectTest{
		{
			name: "invalid sendData",
			sendData: func(_ *testing.T) string {
				return "git-format-patch:not-valid-base64!"
			},
			expectedCode: http.StatusInternalServerError,
		},
		{
			name: "invalid RawPatchRequest JSON",
			sendData: func(t *testing.T) string {
				return encodeSendData(t, "git-format-patch:", patchParams{
					GitalyServer:    api.GitalyServer{Address: "unix:///unused"},
					RawPatchRequest: "not valid protojson",
				})
			},
			expectedCode: http.StatusInternalServerError,
		},
		{
			name: "gitaly connection error",
			sendData: func(t *testing.T) string {
				rawPatchReq := &gitalypb.RawPatchRequest{
					Repository:    &gitalypb.Repository{StorageName: "default", RelativePath: "test.git"},
					LeftCommitId:  "abc123",
					RightCommitId: "def456",
				}
				rawPatchJSON, err := protojson.Marshal(rawPatchReq)
				require.NoError(t, err)

				return encodeSendData(t, "git-format-patch:", patchParams{
					GitalyServer:    api.GitalyServer{Address: "unix:///invalid/does/not/exist/gitaly.sock"},
					RawPatchRequest: string(rawPatchJSON),
				})
			},
			// gRPC connections are established lazily, so NewDiffClient succeeds.
			// The RPC error from SendRawPatch is only logged, not returned via fail.Request,
			// so the response code remains 200.
			expectedCode: http.StatusOK,
		},
		{
			name: "successful patch",
			sendData: func(t *testing.T) string {
				addr := startGRPCServer(t, func(srv *grpc.Server) {
					gitalypb.RegisterDiffServiceServer(srv, &mockDiffServiceServer{
						rawPatchFunc: func(_ *gitalypb.RawPatchRequest, stream gitalypb.DiffService_RawPatchServer) error {
							return stream.Send(&gitalypb.RawPatchResponse{
								Data: []byte("From abc123 Mon Sep 17 00:00:00 2001\n"),
							})
						},
					})
				})

				rawPatchReq := &gitalypb.RawPatchRequest{
					Repository:    &gitalypb.Repository{StorageName: "default", RelativePath: "test.git"},
					LeftCommitId:  "abc123",
					RightCommitId: "def456",
				}
				rawPatchJSON, err := protojson.Marshal(rawPatchReq)
				require.NoError(t, err)

				return encodeSendData(t, "git-format-patch:", patchParams{
					GitalyServer:    api.GitalyServer{Address: addr},
					RawPatchRequest: string(rawPatchJSON),
				})
			},
			expectedCode: http.StatusOK,
			expectedBody: "From abc123 Mon Sep 17 00:00:00 2001\n",
			expectedHeaders: map[string]string{
				"Content-Type": "text/plain; charset=utf-8",
			},
		},
	})
}
