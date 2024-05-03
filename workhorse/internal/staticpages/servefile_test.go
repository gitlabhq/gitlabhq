package staticpages

import (
	"bytes"
	"compress/gzip"
	"net/http"
	"net/http/httptest"
	"os"
	"path/filepath"
	"testing"

	"gitlab.com/gitlab-org/gitlab/workhorse/internal/testhelper"

	"github.com/stretchr/testify/require"
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
