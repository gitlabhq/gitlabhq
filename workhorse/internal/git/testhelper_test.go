package git

import (
	"encoding/base64"
	"encoding/json"
	"fmt"
	"net"
	"net/http/httptest"
	"os"
	"path/filepath"
	"testing"

	"github.com/sirupsen/logrus"
	"github.com/stretchr/testify/assert"
	"github.com/stretchr/testify/require"
	"google.golang.org/grpc"

	"gitlab.com/gitlab-org/gitaly/v18/proto/go/gitalypb"

	"gitlab.com/gitlab-org/gitlab/workhorse/internal/gitaly"
	"gitlab.com/gitlab-org/gitlab/workhorse/internal/senddata"
	"gitlab.com/gitlab-org/gitlab/workhorse/internal/testhelper"
)

func TestMain(m *testing.M) {
	gitaly.InitializeSidechannelRegistry(logrus.StandardLogger())
	os.Exit(m.Run())
}

// startGRPCServer starts a gRPC server on a Unix socket for testing.
// The registerFunc callback is used to register the desired gRPC services.
func startGRPCServer(t testing.TB, registerFunc func(*grpc.Server)) string {
	t.Helper()

	// Ideally, we'd just use t.TempDir(), which would then use either the value of
	// `$TMPDIR` or alternatively "/tmp". But given that macOS sets `$TMPDIR` to a user specific
	// temporary directory, resulting paths would be too long and thus cause issues galore. We
	// thus support our own specific variable instead which allows users to override it, with
	// our default being "/tmp".
	// This fixes errors like this on macOS:
	//
	// listen unix /var/folders/xx/xx/T/xx/001/gitaly.sock: bind: invalid argument
	tempDirLocation := os.Getenv("TEST_TMP_DIR")
	if tempDirLocation == "" {
		tempDirLocation = "/tmp"
	}

	tmp, err := os.MkdirTemp(tempDirLocation, "workhorse-")
	require.NoError(t, err)
	t.Cleanup(func() { assert.NoError(t, os.RemoveAll(tmp)) })

	socket := filepath.Join(tmp, "gitaly.sock")
	ln, err := net.Listen("unix", socket)
	require.NoError(t, err)

	srv := grpc.NewServer(testhelper.WithSidechannel())
	registerFunc(srv)
	errCh := make(chan error, 1)
	go func() {
		errCh <- srv.Serve(ln)
	}()
	t.Cleanup(func() {
		srv.GracefulStop()
		require.NoError(t, <-errCh)
	})

	return fmt.Sprintf("%s://%s", ln.Addr().Network(), ln.Addr().String())
}

// encodeSendData encodes params as JSON and prepends the given prefix for senddata injection.
func encodeSendData(t testing.TB, prefix string, params interface{}) string {
	t.Helper()
	jsonBytes, err := json.Marshal(params)
	require.NoError(t, err)
	return prefix + base64.URLEncoding.EncodeToString(jsonBytes)
}

// injectTest defines a single test case for testing a senddata.Injecter.
type injectTest struct {
	name            string
	sendData        func(t *testing.T) string
	setup           func(w *httptest.ResponseRecorder) // optional per-test recorder setup
	expectedCode    int
	expectedBody    string
	expectedHeaders map[string]string
	removedHeaders  []string
}

// runInjectTests runs table-driven tests against a senddata.Injecter.
func runInjectTests(t *testing.T, injector senddata.Injecter, tests []injectTest) {
	t.Helper()

	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			w := httptest.NewRecorder()
			if tt.setup != nil {
				tt.setup(w)
			}
			r := httptest.NewRequest("GET", "/", nil)

			injector.Inject(w, r, tt.sendData(t))

			require.Equal(t, tt.expectedCode, w.Code)

			if tt.expectedBody != "" {
				require.Equal(t, tt.expectedBody, w.Body.String())
			}

			for key, val := range tt.expectedHeaders {
				require.Equal(t, val, w.Header().Get(key), "header %s", key)
			}

			for _, key := range tt.removedHeaders {
				require.Empty(t, w.Header().Get(key), "header %s should be removed", key)
			}
		})
	}
}

// mockDiffServiceServer is a combined mock for both RawDiff and RawPatch RPCs
// on the Gitaly DiffService.
type mockDiffServiceServer struct {
	gitalypb.UnimplementedDiffServiceServer
	rawDiffFunc  func(*gitalypb.RawDiffRequest, gitalypb.DiffService_RawDiffServer) error
	rawPatchFunc func(*gitalypb.RawPatchRequest, gitalypb.DiffService_RawPatchServer) error
}

func (s *mockDiffServiceServer) RawDiff(req *gitalypb.RawDiffRequest, stream gitalypb.DiffService_RawDiffServer) error {
	return s.rawDiffFunc(req, stream)
}

func (s *mockDiffServiceServer) RawPatch(req *gitalypb.RawPatchRequest, stream gitalypb.DiffService_RawPatchServer) error {
	return s.rawPatchFunc(req, stream)
}
