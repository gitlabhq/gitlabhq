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

	// Create a test file in the assets directory
	assetsDir := filepath.Join(dir, "assets")
	err := os.MkdirAll(assetsDir, 0755)
	require.NoError(t, err)

	fileContent := "STATIC ASSET"
	err = os.WriteFile(filepath.Join(assetsDir, "test.js"), []byte(fileContent), 0600)
	require.NoError(t, err)

	testCases := []struct {
		desc            string
		path            string
		method          string
		hasOriginHeader bool
		railsHeaders    map[string]string
		expectedHeaders map[string]string
	}{
		{
			desc:            "CORS headers returned for GET request on /assets/ with Origin header",
			path:            "/assets/test.js",
			method:          "GET",
			hasOriginHeader: true,
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
			desc:            "CORS headers returned for OPTIONS request on /assets/ with Origin header",
			path:            "/assets/test.js",
			method:          "OPTIONS",
			hasOriginHeader: true,
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
			desc:            "CORS headers returned for HEAD request on /assets/ with Origin header",
			path:            "/assets/test.js",
			method:          "HEAD",
			hasOriginHeader: true,
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
			desc:            "No CORS headers when Origin header is missing",
			path:            "/assets/test.js",
			method:          "GET",
			hasOriginHeader: false,
			railsHeaders: map[string]string{
				"Access-Control-Allow-Origin": "https://example.com",
			},
			expectedHeaders: map[string]string{},
		},
		{
			desc:            "No CORS headers for POST request (not in allowed methods)",
			path:            "/assets/test.js",
			method:          "POST",
			hasOriginHeader: true,
			railsHeaders: map[string]string{
				"Access-Control-Allow-Origin": "https://example.com",
			},
			expectedHeaders: map[string]string{},
		},
		{
			desc:            "No CORS headers for non-assets path",
			path:            "/other/test.js",
			method:          "GET",
			hasOriginHeader: true,
			railsHeaders: map[string]string{
				"Access-Control-Allow-Origin": "https://example.com",
			},
			expectedHeaders: map[string]string{},
		},
		{
			desc:            "Only allowed CORS headers are copied",
			path:            "/assets/test.js",
			method:          "GET",
			hasOriginHeader: true,
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

			if tc.hasOriginHeader {
				httpRequest.Header.Set("Origin", "https://example.com")
			}

			// Create static handler with API client
			w := httptest.NewRecorder()
			st := &Static{DocumentRoot: dir, API: apiClient}
			st.ServeExisting("/", CacheDisabled, nil).ServeHTTP(w, httpRequest)

			// For paths where the file exists, we get 200
			// For paths outside /assets or without origin, we get 200 but no CORS headers
			// For valid cases with CORS, we should get 200 with CORS headers
			if tc.path == "/assets/test.js" && (tc.method == "GET" || tc.method == "OPTIONS") {
				require.Equal(t, 200, w.Code, "Request should succeed when file exists")
			}

			// Verify CORS headers
			verifyCorsHeaders(t, w, tc.expectedHeaders)
		})
	}
}
