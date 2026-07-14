package git

import (
	"net/http"
	"net/http/httptest"
	"os"
	"testing"

	"google.golang.org/grpc"
	"google.golang.org/grpc/codes"
	"google.golang.org/grpc/status"
	"google.golang.org/protobuf/proto"

	"gitlab.com/gitlab-org/gitaly/v18/proto/go/gitalypb"

	"gitlab.com/gitlab-org/gitlab/workhorse/internal/api"
	"gitlab.com/gitlab-org/gitlab/workhorse/internal/testhelper"

	"github.com/stretchr/testify/require"
)

// archiveSendData builds a git-archive senddata payload targeting the given
// Gitaly address, with the on-disk cache disabled to keep tests filesystem-free.
func archiveSendData(t *testing.T, addr string) string {
	t.Helper()

	getArchiveReq := &gitalypb.GetArchiveRequest{
		Repository: &gitalypb.Repository{StorageName: "default", RelativePath: "test.git"},
		CommitId:   "deadbeef",
		Prefix:     "test-master",
		Format:     gitalypb.GetArchiveRequest_ZIP,
	}
	reqBytes, err := proto.Marshal(getArchiveReq)
	require.NoError(t, err)

	return encodeSendData(t, "git-archive:", archiveParams{
		ArchivePath:       "test-master.zip",
		GitalyServer:      api.GitalyServer{Address: addr},
		GetArchiveRequest: reqBytes,
		DisableCache:      true,
	})
}

func startArchiveServer(t *testing.T, fn func(*gitalypb.GetArchiveRequest, gitalypb.RepositoryService_GetArchiveServer) error) string {
	t.Helper()

	return startGRPCServer(t, func(srv *grpc.Server) {
		gitalypb.RegisterRepositoryServiceServer(srv, &mockRepositoryServer{getArchiveFunc: fn})
	})
}

func TestArchiveInject(t *testing.T) {
	tests := []struct {
		name string
		// setup optionally pre-sets headers on the recorder to mimic the caching
		// headers Rails sets upstream before handing off to Workhorse.
		setup           func(*httptest.ResponseRecorder)
		sendData        func(t *testing.T) string
		expectedCode    int
		expectedBody    string
		expectNoStore   bool // assert the failure cleared Rails' caching headers
		expectedHeaders map[string]string
	}{
		{
			name: "invalid sendData",
			sendData: func(_ *testing.T) string {
				return "git-archive:not-valid-base64!"
			},
			expectedCode: http.StatusInternalServerError,
		},
		{
			name: "gitaly connection error",
			sendData: func(t *testing.T) string {
				return archiveSendData(t, "unix:///invalid/does/not/exist/gitaly.sock")
			},
			// A failed dial surfaces from handleArchiveWithGitaly, where the gitaly
			// client's ArchiveReader wraps it with %v and discards the gRPC status
			// code, so archiveErrorStatus sees codes.Unknown and maps it to 500
			// (not 503). Either way it is a non-cacheable 5xx.
			expectedCode:  http.StatusInternalServerError,
			expectNoStore: true,
		},
		{
			// Regression test for https://gitlab.com/gitlab-org/gitlab/-/issues/604046:
			// an immediate "path doesn't exist" must surface as a non-cacheable 404,
			// not a well-formed but empty 200 (and not a 500).
			name: "missing path is a non-cacheable 404",
			setup: func(w *httptest.ResponseRecorder) {
				// Rails sets these before handing off; the failure must clear them.
				w.Header().Set("Cache-Control", "max-age=60, public, must-revalidate")
				w.Header().Set("ETag", `"abc123"`)
			},
			sendData: func(t *testing.T) string {
				addr := startArchiveServer(t, func(_ *gitalypb.GetArchiveRequest, _ gitalypb.RepositoryService_GetArchiveServer) error {
					return status.Error(codes.FailedPrecondition, "path doesn't exist")
				})
				return archiveSendData(t, addr)
			},
			expectedCode:  http.StatusNotFound,
			expectNoStore: true,
		},
		{
			// A successful RPC that streams zero bytes is a malformed archive
			// (a valid archive always has content); it must not be cached as a 200.
			name: "empty archive stream is a non-cacheable error",
			sendData: func(t *testing.T) string {
				addr := startArchiveServer(t, func(_ *gitalypb.GetArchiveRequest, _ gitalypb.RepositoryService_GetArchiveServer) error {
					return nil // closes the stream cleanly without sending any data
				})
				return archiveSendData(t, addr)
			},
			expectedCode:  http.StatusInternalServerError,
			expectNoStore: true,
		},
		{
			name: "unavailable backend is a non-cacheable 503",
			sendData: func(t *testing.T) string {
				addr := startArchiveServer(t, func(_ *gitalypb.GetArchiveRequest, _ gitalypb.RepositoryService_GetArchiveServer) error {
					return status.Error(codes.Unavailable, "backend down")
				})
				return archiveSendData(t, addr)
			},
			expectedCode:  http.StatusServiceUnavailable,
			expectNoStore: true,
		},
		{
			name: "successful archive",
			sendData: func(t *testing.T) string {
				addr := startArchiveServer(t, func(_ *gitalypb.GetArchiveRequest, stream gitalypb.RepositoryService_GetArchiveServer) error {
					return stream.Send(&gitalypb.GetArchiveResponse{Data: []byte("zip archive data")})
				})
				return archiveSendData(t, addr)
			},
			expectedCode: http.StatusOK,
			expectedBody: "zip archive data",
			expectedHeaders: map[string]string{
				"Content-Type": "application/zip",
			},
		},
	}

	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			w := httptest.NewRecorder()
			if tt.setup != nil {
				tt.setup(w)
			}
			r := httptest.NewRequest("GET", "/test-master.zip", nil)

			SendArchive.Inject(w, r, tt.sendData(t))

			require.Equal(t, tt.expectedCode, w.Code)
			if tt.expectedBody != "" {
				require.Equal(t, tt.expectedBody, w.Body.String())
			}
			if tt.expectNoStore {
				require.Equal(t, "no-store", w.Header().Get("Cache-Control"))
				require.Empty(t, w.Header().Get("ETag"), "ETag must be cleared on failure")
			}
			for k, v := range tt.expectedHeaders {
				require.Equal(t, v, w.Header().Get(k), "header %s", k)
			}
		})
	}
}

// TestArchiveInjectAbortsOnMidStreamFailure verifies that when Gitaly fails
// *after* the 200 and part of the body have been sent, the handler aborts the
// connection (rather than returning cleanly) so the truncated response is not
// cached. See https://gitlab.com/gitlab-org/gitlab/-/issues/604046.
func TestArchiveInjectAbortsOnMidStreamFailure(t *testing.T) {
	addr := startArchiveServer(t, func(_ *gitalypb.GetArchiveRequest, stream gitalypb.RepositoryService_GetArchiveServer) error {
		if err := stream.Send(&gitalypb.GetArchiveResponse{Data: []byte("PK\x03\x04 partial")}); err != nil {
			return err
		}
		return status.Error(codes.Internal, "boom mid-stream")
	})

	w := httptest.NewRecorder()
	r := httptest.NewRequest("GET", "/test-master.zip", nil)

	require.PanicsWithValue(t, http.ErrAbortHandler, func() {
		SendArchive.Inject(w, r, archiveSendData(t, addr))
	})

	// The 200 status was already committed before the stream failed mid-flight.
	require.Equal(t, http.StatusOK, w.Code)
}

func TestParseBasename(t *testing.T) {
	for _, testCase := range []struct {
		in  string
		out gitalypb.GetArchiveRequest_Format
	}{
		{"archive", gitalypb.GetArchiveRequest_TAR_GZ},
		{"master.tar.gz", gitalypb.GetArchiveRequest_TAR_GZ},
		{"foo-master.tgz", gitalypb.GetArchiveRequest_TAR_GZ},
		{"foo-v1.2.1.gz", gitalypb.GetArchiveRequest_TAR_GZ},
		{"foo.tar.bz2", gitalypb.GetArchiveRequest_TAR_BZ2},
		{"archive.tbz", gitalypb.GetArchiveRequest_TAR_BZ2},
		{"archive.tbz2", gitalypb.GetArchiveRequest_TAR_BZ2},
		{"archive.tb2", gitalypb.GetArchiveRequest_TAR_BZ2},
		{"archive.bz2", gitalypb.GetArchiveRequest_TAR_BZ2},
	} {
		basename := testCase.in
		out, ok := parseBasename(basename)
		if !ok {
			t.Fatalf("parseBasename did not recognize %q", basename)
		}

		if out != testCase.out {
			t.Fatalf("expected %q, got %q", testCase.out, out)
		}
	}
}

func TestFinalizeArchive(t *testing.T) {
	tempFile, err := os.CreateTemp("", "gitlab-workhorse-test")
	if err != nil {
		t.Fatal(err)
	}
	defer tempFile.Close()

	// Deliberately cause an EEXIST error: we know tempFile.Name() already exists
	err = finalizeCachedArchive(tempFile, tempFile.Name())
	if err != nil {
		t.Fatalf("expected nil from finalizeCachedArchive, received %v", err)
	}
}

func TestSetArchiveHeaders(t *testing.T) {
	for _, testCase := range []struct {
		in  gitalypb.GetArchiveRequest_Format
		out string
	}{
		{gitalypb.GetArchiveRequest_ZIP, "application/zip"},
		{gitalypb.GetArchiveRequest_TAR, "application/octet-stream"},
		{gitalypb.GetArchiveRequest_TAR_GZ, "application/octet-stream"},
		{gitalypb.GetArchiveRequest_TAR_BZ2, "application/octet-stream"},
	} {
		w := httptest.NewRecorder()

		// These should be replaced, not appended to
		w.Header().Set("Content-Type", "test")
		w.Header().Set("Content-Length", "test")
		w.Header().Set("Content-Disposition", "test")

		// This should be deleted
		w.Header().Set("Set-Cookie", "test")

		// This should be preserved
		w.Header().Set("Cache-Control", "public, max-age=3600")

		setArchiveHeaders(w, testCase.in, "filename")

		testhelper.RequireResponseHeader(t, w, "Content-Type", testCase.out)
		testhelper.RequireResponseHeader(t, w, "Content-Length")
		testhelper.RequireResponseHeader(t, w, "Content-Disposition", `attachment; filename="filename"`)
		testhelper.RequireResponseHeader(t, w, "Cache-Control", "public, max-age=3600")
		require.Empty(t, w.Header().Get("Set-Cookie"), "remove Set-Cookie")
	}
}
