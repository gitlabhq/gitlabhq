package staticpages

import (
	"bytes"
	"compress/gzip"
	"net/http"
	"net/http/httptest"
	"os"
	"path/filepath"
	"testing"

	"github.com/stretchr/testify/require"

	"gitlab.com/gitlab-org/gitlab/workhorse/internal/api"
	"gitlab.com/gitlab-org/gitlab/workhorse/internal/helper"
	"gitlab.com/gitlab-org/gitlab/workhorse/internal/testhelper"
	"gitlab.com/gitlab-org/gitlab/workhorse/internal/upstream/roundtripper"
)

const (
	nonExistingDir = "/path/to/non/existing/directory"
)

func TestServingNonExistingFile(t *testing.T) {
	httpRequest, _ := http.NewRequest("GET", "/file", nil)

	w := httptest.NewRecorder()
	st := &Static{DocumentRoot: nonExistingDir}
	st.ServeExisting("/", CacheDisabled, nil).ServeHTTP(w, httpRequest)
	require.Equal(t, 404, w.Code)
}

func TestServingDirectory(t *testing.T) {
	dir := t.TempDir()

	httpRequest, _ := http.NewRequest("GET", "/file", nil)
	w := httptest.NewRecorder()
	st := &Static{DocumentRoot: dir}
	st.ServeExisting("/", CacheDisabled, nil).ServeHTTP(w, httpRequest)
	require.Equal(t, 404, w.Code)
}

func TestServingMalformedUri(t *testing.T) {
	httpRequest, _ := http.NewRequest("GET", "/../../../static/file", nil)

	w := httptest.NewRecorder()
	st := &Static{DocumentRoot: nonExistingDir}
	st.ServeExisting("/", CacheDisabled, nil).ServeHTTP(w, httpRequest)
	require.Equal(t, 404, w.Code)
}

func TestExecutingHandlerWhenNoFileFound(t *testing.T) {
	httpRequest, _ := http.NewRequest("GET", "/file", nil)

	executed := false
	st := &Static{DocumentRoot: nonExistingDir}
	st.ServeExisting("/", CacheDisabled, http.HandlerFunc(func(_ http.ResponseWriter, r *http.Request) {
		executed = (r == httpRequest)
	})).ServeHTTP(nil, httpRequest)
	if !executed {
		t.Error("The handler should get executed")
	}
}

func TestServingTheActualFile(t *testing.T) {
	dir := t.TempDir()

	httpRequest, _ := http.NewRequest("GET", "/file", nil)

	fileContent := "STATIC"
	os.WriteFile(filepath.Join(dir, "file"), []byte(fileContent), 0600)

	w := httptest.NewRecorder()
	st := &Static{DocumentRoot: dir}
	st.ServeExisting("/", CacheDisabled, nil).ServeHTTP(w, httpRequest)
	testhelper.RequireResponseHeader(t, w, "X-Content-Type-Options", "nosniff")
	require.Equal(t, 200, w.Code)
	if w.Body.String() != fileContent {
		t.Error("We should serve the file: ", w.Body.String())
	}
}

func TestExcludedPaths(t *testing.T) {
	testCases := []struct {
		desc     string
		path     string
		found    bool
		contents string
	}{
		{"allowed file", "/file1", true, "contents1"},
		{"path traversal is allowed", "/uploads/../file1", true, "contents1"},
		{"files in /uploads/ are invisible", "/uploads/file2", false, ""},
		{"cannot use path traversal to get to /uploads/", "/foobar/../uploads/file2", false, ""},
		{"cannot use escaped path traversal to get to /uploads/", "/foobar%2f%2e%2e%2fuploads/file2", false, ""},
		{"cannot use double escaped path traversal to get to /uploads/", "/foobar%252f%252e%252e%252fuploads/file2", false, ""},
	}

	for _, tc := range testCases {
		t.Run(tc.desc, func(t *testing.T) {
			httpRequest, err := http.NewRequest("GET", tc.path, nil)
			require.NoError(t, err)

			w := httptest.NewRecorder()
			st := &Static{DocumentRoot: "testdata", Exclude: []string{"/uploads/"}}
			st.ServeExisting("/", CacheDisabled, nil).ServeHTTP(w, httpRequest)

			if tc.found {
				testhelper.RequireResponseHeader(t, w, "X-Content-Type-Options", "nosniff")
				require.Equal(t, 200, w.Code)
				require.Equal(t, tc.contents, w.Body.String())
			} else {
				require.Equal(t, 404, w.Code)
			}
		})
	}
}

func testServingThePregzippedFile(t *testing.T, enableGzip bool) {
	dir := t.TempDir()

	httpRequest, _ := http.NewRequest("GET", "/file", nil)

	if enableGzip {
		httpRequest.Header.Set("Accept-Encoding", "gzip, deflate")
	}

	fileContent := "STATIC"

	var fileGzipContent bytes.Buffer
	fileGzip := gzip.NewWriter(&fileGzipContent)
	fileGzip.Write([]byte(fileContent))
	fileGzip.Close()

	os.WriteFile(filepath.Join(dir, "file.gz"), fileGzipContent.Bytes(), 0600)
	os.WriteFile(filepath.Join(dir, "file"), []byte(fileContent), 0600)

	w := httptest.NewRecorder()
	st := &Static{DocumentRoot: dir}
	st.ServeExisting("/", CacheDisabled, nil).ServeHTTP(w, httpRequest)
	testhelper.RequireResponseHeader(t, w, "X-Content-Type-Options", "nosniff")
	require.Equal(t, 200, w.Code)
	if enableGzip {
		testhelper.RequireResponseHeader(t, w, "Content-Encoding", "gzip")
		if !bytes.Equal(w.Body.Bytes(), fileGzipContent.Bytes()) {
			t.Error("We should serve the pregzipped file")
		}
	} else {
		require.Equal(t, 200, w.Code)
		testhelper.RequireResponseHeader(t, w, "Content-Encoding")
		if w.Body.String() != fileContent {
			t.Error("We should serve the file: ", w.Body.String())
		}
	}
}

func TestServingThePregzippedFile(t *testing.T) {
	testServingThePregzippedFile(t, true)
}

func TestServingThePregzippedFileWithoutEncoding(t *testing.T) {
	testServingThePregzippedFile(t, false)
}

// testRailsServer creates a mock Rails server that returns the specified headers
func testRailsServer(t *testing.T, headers map[string]string) *httptest.Server {
	t.Helper()
	return httptest.NewServer(http.HandlerFunc(func(w http.ResponseWriter, _ *http.Request) {
		// Set the headers that Rails would return
		for k, v := range headers {
			w.Header().Set(k, v)
		}
		w.WriteHeader(http.StatusOK)
	}))
}

// verifyCorsHeaders verifies that the expected CORS headers are present and no unexpected CORS headers are set
func verifyCorsHeaders(t *testing.T, w *httptest.ResponseRecorder, expectedHeaders map[string]string) {
	t.Helper()

	// Verify expected CORS headers are present with correct values
	for expectedKey, expectedValue := range expectedHeaders {
		require.Equal(t, expectedValue, w.Header().Get(expectedKey),
			"Expected CORS header %s to be %s", expectedKey, expectedValue)
	}

	// Verify that headers NOT in expectedHeaders are NOT set
	allCorsHeaders := []string{
		"Access-Control-Allow-Origin",
		"Access-Control-Allow-Methods",
		"Access-Control-Allow-Headers",
		"Access-Control-Allow-Credentials",
		"Cross-Origin-Opener-Policy",
		"Content-Security-Policy",
		"Cross-Origin-Resource-Policy",
		"Vary",
	}
	for _, header := range allCorsHeaders {
		if _, expected := expectedHeaders[header]; !expected {
			require.Empty(t, w.Header().Get(header),
				"Header %s should not be set", header)
		}
	}
}

func TestResolveCorsHeaders(t *testing.T) {
	dir := t.TempDir()

	// Create test files in the assets directory for different paths
	fileContent := "STATIC ASSET"

	// Create webpack/gitlab-web-ide-vscode-workbench path
	vscodeDir := filepath.Join(dir, "assets", "webpack", "gitlab-web-ide-vscode-workbench")
	err := os.MkdirAll(vscodeDir, 0755)
	require.NoError(t, err)
	err = os.WriteFile(filepath.Join(vscodeDir, "test.js"), []byte(fileContent), 0600)
	require.NoError(t, err)

	// Create gitlab-mono path
	gitlabMonoDir := filepath.Join(dir, "assets", "gitlab-mono")
	err = os.MkdirAll(gitlabMonoDir, 0755)
	require.NoError(t, err)
	err = os.WriteFile(filepath.Join(gitlabMonoDir, "test.woff2"), []byte(fileContent), 0600)
	require.NoError(t, err)

	// Create other assets path (should not get CORS headers)
	otherDir := filepath.Join(dir, "assets", "other")
	err = os.MkdirAll(otherDir, 0755)
	require.NoError(t, err)
	err = os.WriteFile(filepath.Join(otherDir, "test.js"), []byte(fileContent), 0600)
	require.NoError(t, err)

	testCases := []struct {
		desc            string
		path            string
		method          string
		railsHeaders    map[string]string
		expectedHeaders map[string]string
	}{
		{
			desc:   "CORS headers returned for GET request on /assets/webpack/gitlab-web-ide-vscode-workbench path",
			path:   "/assets/webpack/gitlab-web-ide-vscode-workbench/test.js",
			method: "GET",
			railsHeaders: map[string]string{
				"Access-Control-Allow-Origin":      "https://example.com",
				"Access-Control-Allow-Methods":     "GET, HEAD, OPTIONS",
				"Access-Control-Allow-Headers":     "Content-Type",
				"Access-Control-Allow-Credentials": "true",
				"Vary":                             "Origin",
			},
			expectedHeaders: map[string]string{
				"Access-Control-Allow-Origin":      "https://example.com",
				"Access-Control-Allow-Methods":     "GET, HEAD, OPTIONS",
				"Access-Control-Allow-Headers":     "Content-Type",
				"Access-Control-Allow-Credentials": "true",
				"Vary":                             "Origin",
			},
		},
		{
			desc:   "CORS headers returned for OPTIONS request on /assets/gitlab-mono path",
			path:   "/assets/gitlab-mono/test.woff2",
			method: "OPTIONS",
			railsHeaders: map[string]string{
				"Access-Control-Allow-Origin":  "https://example.com",
				"Access-Control-Allow-Methods": "GET, HEAD, OPTIONS",
			},
			expectedHeaders: map[string]string{
				"Access-Control-Allow-Origin":  "https://example.com",
				"Access-Control-Allow-Methods": "GET, HEAD, OPTIONS",
			},
		},
		{
			desc:   "CORS headers returned for HEAD request on /assets/webpack/gitlab-web-ide-vscode-workbench path",
			path:   "/assets/webpack/gitlab-web-ide-vscode-workbench/test.js",
			method: "HEAD",
			railsHeaders: map[string]string{
				"Access-Control-Allow-Origin":  "https://example.com",
				"Access-Control-Allow-Methods": "GET, HEAD, OPTIONS",
			},
			expectedHeaders: map[string]string{
				"Access-Control-Allow-Origin":  "https://example.com",
				"Access-Control-Allow-Methods": "GET, HEAD, OPTIONS",
			},
		},
		{
			desc:   "New security headers are returned for /assets/webpack/gitlab-web-ide-vscode-workbench path",
			path:   "/assets/webpack/gitlab-web-ide-vscode-workbench/test.js",
			method: "GET",
			railsHeaders: map[string]string{
				"Access-Control-Allow-Origin":  "https://example.com",
				"Cross-Origin-Opener-Policy":   "same-origin",
				"Content-Security-Policy":      "default-src 'self'",
				"Cross-Origin-Resource-Policy": "cross-origin",
			},
			expectedHeaders: map[string]string{
				"Access-Control-Allow-Origin":  "https://example.com",
				"Cross-Origin-Opener-Policy":   "same-origin",
				"Content-Security-Policy":      "default-src 'self'",
				"Cross-Origin-Resource-Policy": "cross-origin",
			},
		},
		{
			desc:   "No CORS headers for POST request (not in allowed methods)",
			path:   "/assets/webpack/gitlab-web-ide-vscode-workbench/test.js",
			method: "POST",
			railsHeaders: map[string]string{
				"Access-Control-Allow-Origin": "https://example.com",
			},
			expectedHeaders: map[string]string{},
		},
		{
			desc:   "No CORS headers for non-target assets path (not webpack/gitlab-web-ide-vscode-workbench or gitlab-mono)",
			path:   "/assets/other/test.js",
			method: "GET",
			railsHeaders: map[string]string{
				"Access-Control-Allow-Origin": "https://example.com",
			},
			expectedHeaders: map[string]string{},
		},
		{
			desc:   "No CORS headers for non-assets path",
			path:   "/other/test.js",
			method: "GET",
			railsHeaders: map[string]string{
				"Access-Control-Allow-Origin": "https://example.com",
			},
			expectedHeaders: map[string]string{},
		},
		{
			desc:   "Only allowed CORS headers are copied",
			path:   "/assets/gitlab-mono/test.woff2",
			method: "GET",
			railsHeaders: map[string]string{
				"Access-Control-Allow-Origin": "https://example.com",
				"X-Custom-Header":             "should-not-be-copied",
				"Content-Type":                "application/json",
			},
			expectedHeaders: map[string]string{
				"Access-Control-Allow-Origin": "https://example.com",
			},
		},
	}

	for _, tc := range testCases {
		t.Run(tc.desc, func(t *testing.T) {
			testhelper.ConfigureSecret()

			// Create a mock Rails server that returns the specified CORS headers
			ts := testRailsServer(t, tc.railsHeaders)
			defer ts.Close()

			// Create API client
			backend := helper.URLMustParse(ts.URL)
			rt := roundtripper.NewTestBackendRoundTripper(backend)
			apiClient := api.NewAPI(backend, "123", rt)

			// Create request
			httpRequest, err := http.NewRequest(tc.method, tc.path, nil)
			require.NoError(t, err)

			// Create static handler with API client
			w := httptest.NewRecorder()
			st := &Static{DocumentRoot: dir, API: apiClient}
			st.ServeExisting("/", CacheDisabled, nil).ServeHTTP(w, httpRequest)

			// For paths where the file exists and method is allowed, we should get 200
			if tc.method == "GET" || tc.method == "HEAD" || tc.method == "OPTIONS" {
				// Check if the path should return 200 or 404
				if tc.path != "/other/test.js" {
					require.Equal(t, 200, w.Code, "Request should succeed when file exists")
				}
			}

			// Verify CORS headers
			verifyCorsHeaders(t, w, tc.expectedHeaders)
		})
	}
}
