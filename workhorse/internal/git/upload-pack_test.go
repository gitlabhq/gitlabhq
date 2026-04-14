package git

import (
	"context"
	"io"
	"net/http/httptest"
	"testing"
	"time"

	"github.com/stretchr/testify/require"
	"google.golang.org/grpc"

	"gitlab.com/gitlab-org/gitaly/v18/client"
	"gitlab.com/gitlab-org/gitaly/v18/proto/go/gitalypb"

	"gitlab.com/gitlab-org/gitlab/workhorse/internal/api"
)

var (
	originalUploadPackTimeout = uploadPackTimeout
)

type waitReader struct {
	t time.Duration
}

func (f *waitReader) Read(_ []byte) (int, error) {
	time.Sleep(f.t)
	return 0, io.EOF
}

type smartHTTPServiceServer struct {
	gitalypb.UnimplementedSmartHTTPServiceServer
	handler func(context.Context, *gitalypb.PostUploadPackWithSidechannelRequest) (*gitalypb.PostUploadPackWithSidechannelResponse, error)
}

func (srv *smartHTTPServiceServer) PostUploadPackWithSidechannel(ctx context.Context, req *gitalypb.PostUploadPackWithSidechannelRequest) (*gitalypb.PostUploadPackWithSidechannelResponse, error) {
	return srv.handler(ctx, req)
}

func TestUploadPackTimesOut(t *testing.T) {
	uploadPackTimeout = time.Millisecond
	defer func() { uploadPackTimeout = originalUploadPackTimeout }()

	addr := startSmartHTTPServer(t, &smartHTTPServiceServer{
		handler: func(ctx context.Context, _ *gitalypb.PostUploadPackWithSidechannelRequest) (*gitalypb.PostUploadPackWithSidechannelResponse, error) {
			conn, err := client.OpenServerSidechannel(ctx)
			if err != nil {
				return nil, err
			}
			defer conn.Close()

			_, _ = io.Copy(io.Discard, conn)
			return &gitalypb.PostUploadPackWithSidechannelResponse{}, nil
		},
	})

	body := &waitReader{t: 10 * time.Millisecond}

	w := httptest.NewRecorder()
	r := httptest.NewRequest("GET", "/", body)
	a := &api.Response{GitalyServer: api.GitalyServer{Address: addr}}

	_, err := handleUploadPack(NewHTTPResponseWriter(w), r, a)
	require.ErrorIs(t, err, context.DeadlineExceeded)
}

// startSmartHTTPServer is a convenience wrapper around startGRPCServer
// that registers a SmartHTTPService.
func startSmartHTTPServer(t testing.TB, s gitalypb.SmartHTTPServiceServer) string {
	t.Helper()

	return startGRPCServer(t, func(srv *grpc.Server) {
		gitalypb.RegisterSmartHTTPServiceServer(srv, s)
	})
}
