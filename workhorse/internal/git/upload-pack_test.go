package git

import (
	"fmt"
	"io/ioutil"
	"net"
	"net/http/httptest"
	"os"
	"path/filepath"
	"testing"
	"time"

	"github.com/stretchr/testify/require"
	"google.golang.org/grpc"

	"gitlab.com/gitlab-org/gitaly/v14/proto/go/gitalypb"

	"gitlab.com/gitlab-org/gitlab-workhorse/internal/api"
	"gitlab.com/gitlab-org/gitlab-workhorse/internal/gitaly"
)

var (
	originalUploadPackTimeout = uploadPackTimeout
)

type fakeReader struct {
	n   int
	err error
}

func (f *fakeReader) Read(b []byte) (int, error) {
	return f.n, f.err
}

type smartHTTPServiceServer struct {
	gitalypb.UnimplementedSmartHTTPServiceServer
	PostUploadPackFunc func(gitalypb.SmartHTTPService_PostUploadPackServer) error
}

func (srv *smartHTTPServiceServer) PostUploadPack(s gitalypb.SmartHTTPService_PostUploadPackServer) error {
	return srv.PostUploadPackFunc(s)
}

func TestUploadPackTimesOut(t *testing.T) {
	uploadPackTimeout = time.Millisecond
	defer func() { uploadPackTimeout = originalUploadPackTimeout }()

	addr, cleanUp := startSmartHTTPServer(t, &smartHTTPServiceServer{
		PostUploadPackFunc: func(stream gitalypb.SmartHTTPService_PostUploadPackServer) error {
			_, err := stream.Recv() // trigger a read on the client request body
			require.NoError(t, err)
			return nil
		},
	})
	defer cleanUp()

	body := &fakeReader{n: 0, err: nil}

	w := httptest.NewRecorder()
	r := httptest.NewRequest("GET", "/", body)
	a := &api.Response{GitalyServer: gitaly.Server{Address: addr}}

	err := handleUploadPack(NewHttpResponseWriter(w), r, a)
	require.EqualError(t, err, "smarthttp.UploadPack: busyReader: context deadline exceeded")
}

func startSmartHTTPServer(t testing.TB, s gitalypb.SmartHTTPServiceServer) (string, func()) {
	tmp, err := ioutil.TempDir("", "")
	require.NoError(t, err)

	socket := filepath.Join(tmp, "gitaly.sock")
	ln, err := net.Listen("unix", socket)
	require.NoError(t, err)

	srv := grpc.NewServer()
	gitalypb.RegisterSmartHTTPServiceServer(srv, s)
	go func() {
		require.NoError(t, srv.Serve(ln))
	}()

	return fmt.Sprintf("%s://%s", ln.Addr().Network(), ln.Addr().String()), func() {
		srv.GracefulStop()
		require.NoError(t, os.RemoveAll(tmp), "error removing temp dir %q", tmp)
	}
}
