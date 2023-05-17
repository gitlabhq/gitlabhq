package testhelper

import (
	"errors"
	"fmt"
	"io"
	"net/http"
	"net/http/httptest"
	"os"
	"path"
	"regexp"
	"runtime"
	"testing"
	"time"

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

func Retry(t testing.TB, timeout time.Duration, fn func() error) {
	t.Helper()
	start := time.Now()
	var err error
	for ; time.Since(start) < timeout; time.Sleep(time.Millisecond) {
		err = fn()
		if err == nil {
			return
		}
	}
	t.Fatalf("test timeout after %v; last error: %v", timeout, err)
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
