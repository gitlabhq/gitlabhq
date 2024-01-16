package testhelper

import (
	"bytes"
	"errors"
	"fmt"
	"io"
	"net/http"
	"net/http/httptest"
	"os"
	"path"
	"path/filepath"
	"regexp"
	"runtime"
	"syscall"
	"testing"

	"github.com/golang-jwt/jwt/v5"
	"github.com/stretchr/testify/require"

	"gitlab.com/gitlab-org/labkit/log"

	"gitlab.com/gitlab-org/gitlab/workhorse/internal/secret"
)

const (
	geoProxyEndpointPath = "/api/v4/geo/proxy"
)

func ConfigureSecret() {
	secret.SetPath(path.Join(RootDir(), "testdata/test-secret"))
}

func RequireResponseBody(t *testing.T, response *httptest.ResponseRecorder, expectedBody string) {
	t.Helper()
	require.Equal(t, expectedBody, response.Body.String(), "response body")
}

func RequireResponseHeader(t *testing.T, w interface{}, header string, expected ...string) {
	t.Helper()
	var actual []string

	header = http.CanonicalHeaderKey(header)
	type headerer interface{ Header() http.Header }

	switch resp := w.(type) {
	case *http.Response:
		actual = resp.Header[header]
	case headerer:
		actual = resp.Header()[header]
	default:
		t.Fatal("invalid type of w passed RequireResponseHeader")
	}

	require.Equal(t, expected, actual, "values for HTTP header %s", header)
}

// TestServerWithHandler skips Geo API polling for a proxy URL by default,
// use TestServerWithHandlerWithGeoPolling if you need to explicitly
// handle Geo API polling request as well.
func TestServerWithHandler(url *regexp.Regexp, handler http.HandlerFunc) *httptest.Server {
	return TestServerWithHandlerWithGeoPolling(url, http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		if r.URL.Path == geoProxyEndpointPath {
			return
		}

		handler(w, r)
	}))
}

func TestServerWithHandlerWithGeoPolling(url *regexp.Regexp, handler http.HandlerFunc) *httptest.Server {
	return httptest.NewServer(http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		logEntry := log.WithFields(log.Fields{
			"method": r.Method,
			"url":    r.URL,
			"action": "DENY",
		})

		if url != nil && !url.MatchString(r.URL.Path) {
			logEntry.Info("UPSTREAM")
			w.WriteHeader(404)
			return
		}

		if version := r.Header.Get("Gitlab-Workhorse"); version == "" {
			logEntry.Info("UPSTREAM")
			w.WriteHeader(403)
			return
		}

		handler(w, r)
	}))
}

var workhorseExecutables = []string{"gitlab-workhorse", "gitlab-zip-cat", "gitlab-zip-metadata", "gitlab-resize-image"}

func BuildExecutables() error {
	rootDir := RootDir()

	for _, exe := range workhorseExecutables {
		if _, err := os.Stat(path.Join(rootDir, exe)); os.IsNotExist(err) {
			return fmt.Errorf("cannot find executable %s. Please run 'make prepare-tests'", exe)
		}
	}

	oldPath := os.Getenv("PATH")
	testPath := fmt.Sprintf("%s:%s", rootDir, oldPath)
	if err := os.Setenv("PATH", testPath); err != nil {
		return fmt.Errorf("failed to set PATH to %v", testPath)
	}

	return nil
}

func RootDir() string {
	_, currentFile, _, ok := runtime.Caller(0)
	if !ok {
		panic(errors.New("RootDir: calling runtime.Caller failed"))
	}
	return path.Join(path.Dir(currentFile), "../..")
}

func LoadFile(t *testing.T, filePath string) string {
	t.Helper()
	content, err := os.ReadFile(path.Join(RootDir(), filePath))
	require.NoError(t, err)
	return string(content)
}

func ReadAll(t *testing.T, r io.Reader) []byte {
	t.Helper()

	b, err := io.ReadAll(r)
	require.NoError(t, err)
	return b
}

func ParseJWT(token *jwt.Token) (interface{}, error) {
	// Don't forget to validate the alg is what you expect:
	if _, ok := token.Method.(*jwt.SigningMethodHMAC); !ok {
		return nil, fmt.Errorf("unexpected signing method: %v", token.Header["alg"])
	}

	ConfigureSecret()
	secretBytes, err := secret.Bytes()
	if err != nil {
		return nil, fmt.Errorf("read secret from file: %v", err)
	}

	return secretBytes, nil
}

// UploadClaims represents the JWT claim for upload parameters
type UploadClaims struct {
	Upload map[string]string `json:"upload"`
	jwt.RegisteredClaims
}

func SetupStaticFileHelper(t *testing.T, fpath, content, directory string) string {
	cwd, err := os.Getwd()
	require.NoError(t, err, "get working directory")

	absDocumentRoot := path.Join(cwd, directory)
	require.NoError(t, os.MkdirAll(path.Join(absDocumentRoot, path.Dir(fpath)), 0755), "create document root")

	staticFile := path.Join(absDocumentRoot, fpath)
	require.NoError(t, os.WriteFile(staticFile, []byte(content), 0666), "write file content")

	return absDocumentRoot
}

// TempDir is a wrapper around os.MkdirTemp that provides a cleanup function.
func TempDir(tb testing.TB) string {
	tmpDir, err := os.MkdirTemp("", "workhorse-tmp-*")
	require.NoError(tb, err)
	tb.Cleanup(func() {
		require.NoError(tb, os.RemoveAll(tmpDir))
	})

	return tmpDir
}

// MustClose calls Close() on the Closer and fails the test in case it returns
// an error. This function is useful when closing via `defer`, as a simple
// `defer require.NoError(t, closer.Close())` would cause `closer.Close()` to
// be executed early already.
func MustClose(tb testing.TB, closer io.Closer) {
	require.NoError(tb, closer.Close())
}

// WriteExecutable ensures that the parent directory exists, and writes an executable with provided
// content. The executable must not exist previous to writing it. Returns the path of the written
// executable.
func WriteExecutable(tb testing.TB, path string, content []byte) string {
	dir := filepath.Dir(path)
	require.NoError(tb, os.MkdirAll(dir, 0o755))
	tb.Cleanup(func() {
		require.NoError(tb, os.RemoveAll(dir))
	})

	// Open the file descriptor and write the script into it. It may happen that any other
	// Goroutine forks while we hold this writeable file descriptor, and as a consequence we
	// leak it into the other process. Subsequently, even if we close the file descriptor
	// ourselves this other process may still hold on to the writeable file descriptor. The
	// result is that calls to execve(3P) on our just-written file will fail with ETXTBSY,
	// which is raised when trying to execute a file which is still open to be written to.
	//
	// We thus need to perform file locking to ensure that all writeable references to this
	// file have been closed before returning.
	executable, err := os.OpenFile(path, os.O_CREATE|os.O_EXCL|os.O_WRONLY, 0o700)
	require.NoError(tb, err)
	_, err = io.Copy(executable, bytes.NewReader(content))
	require.NoError(tb, err)

	// We now lock the file descriptor for exclusive access. If there was a forked process
	// holding the writeable file descriptor at this point in time, then it would refer to the
	// same file descriptor and thus be locked for exclusive access, as well. If we fork after
	// creating the lock and before closing the writeable file descriptor, then the dup'd file
	// descriptor would automatically inherit the lock.
	//
	// No matter what, after this step any file descriptors referring to this writeable file
	// descriptor will be exclusively locked.
	require.NoError(tb, syscall.Flock(int(executable.Fd()), syscall.LOCK_EX))

	// We now close this file. The file will be automatically unlocked as soon as all
	// references to this file descriptor are closed.
	MustClose(tb, executable)

	// We now open the file again, but this time only for reading.
	executable, err = os.Open(path)
	require.NoError(tb, err)

	// And this time, we try to acquire a shared lock on this file. This call will block until
	// the exclusive file lock on the above writeable file descriptor has been dropped. So as
	// soon as we're able to acquire the lock we know that there cannot be any open writeable
	// file descriptors for this file anymore, and thus we won't get ETXTBSY anymore.
	require.NoError(tb, syscall.Flock(int(executable.Fd()), syscall.LOCK_SH))
	MustClose(tb, executable)

	return path
}
