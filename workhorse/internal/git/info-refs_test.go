package git

import (
	"net/http/httptest"
	"testing"

	"github.com/stretchr/testify/require"
	grpccodes "google.golang.org/grpc/codes"
	grpcstatus "google.golang.org/grpc/status"

	"gitlab.com/gitlab-org/gitaly/v16/proto/go/gitalypb"

	"gitlab.com/gitlab-org/gitlab/workhorse/internal/api"
)

type smartHTTPServiceServerWithInfoRefs struct {
	gitalypb.UnimplementedSmartHTTPServiceServer
	InfoRefsUploadPackFunc func(*gitalypb.InfoRefsRequest, gitalypb.SmartHTTPService_InfoRefsUploadPackServer) error
}

func (srv *smartHTTPServiceServerWithInfoRefs) InfoRefsUploadPack(r *gitalypb.InfoRefsRequest, s gitalypb.SmartHTTPService_InfoRefsUploadPackServer) error {
	return srv.InfoRefsUploadPackFunc(r, s)
}

func TestGetInfoRefsHandler(t *testing.T) {
	addr := startSmartHTTPServer(t, &smartHTTPServiceServerWithInfoRefs{
		InfoRefsUploadPackFunc: func(_ *gitalypb.InfoRefsRequest, _ gitalypb.SmartHTTPService_InfoRefsUploadPackServer) error {
			return grpcstatus.Error(grpccodes.Unavailable, "error")
		},
	})

	w := httptest.NewRecorder()
	r := httptest.NewRequest("GET", "/?service=git-upload-pack", nil)
	a := &api.Response{GitalyServer: api.GitalyServer{Address: addr}}

	handleGetInfoRefs(NewHTTPResponseWriter(w), r, a)
	require.Equal(t, 503, w.Code)

	msg := "The git server, Gitaly, is not available at this time. Please contact your administrator.\n"
	require.Equal(t, msg, w.Body.String())
}
