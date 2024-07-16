package artifacts

import (
	"archive/zip"
	"encoding/base64"
	"fmt"
	"net/http"
	"net/http/httptest"
	"os"
	"path/filepath"
	"testing"

	"github.com/stretchr/testify/assert"
	"github.com/stretchr/testify/require"

	"gitlab.com/gitlab-org/gitlab/workhorse/internal/testhelper"
)

func testEntryServer(t *testing.T, archive string, entry string) *httptest.ResponseRecorder {
	mux := http.NewServeMux()
	mux.HandleFunc("/url/path", func(w http.ResponseWriter, r *http.Request) {
		assert.Equal(t, "GET", r.Method)

		encodedEntry := base64.StdEncoding.EncodeToString([]byte(entry))
		jsonParams := fmt.Sprintf(`{"Archive":"%s","Entry":"%s"}`, archive, encodedEntry)
		data := base64.URLEncoding.EncodeToString([]byte(jsonParams))

		SendEntry.Inject(w, r, data)
	})

	httpRequest, err := http.NewRequest("GET", "/url/path", nil)
	require.NoError(t, err)
	response := httptest.NewRecorder()
	mux.ServeHTTP(response, httpRequest)
	return response
}

func TestDownloadingFromValidArchive(t *testing.T) {
	tempFile, err := os.CreateTemp("", "uploads")
	require.NoError(t, err)
	defer tempFile.Close()
	defer os.Remove(tempFile.Name())

	archive := zip.NewWriter(tempFile)
	defer archive.Close()
	fileInArchive, err := archive.Create("test.txt")
	require.NoError(t, err)
	fmt.Fprint(fileInArchive, "testtest")
	archive.Close()

	response := testEntryServer(t, tempFile.Name(), "test.txt")

	require.Equal(t, 200, response.Code)

	testhelper.RequireResponseHeader(t, response,
		"Content-Type",
		"text/plain; charset=utf-8")
	testhelper.RequireResponseHeader(t, response,
		"Content-Disposition",
		"attachment; filename=\"test.txt\"")

	testhelper.RequireResponseBody(t, response, "testtest")
}

func TestDownloadingFromValidHTTPArchive(t *testing.T) {
	tempDir := t.TempDir()

	f, err := os.Create(filepath.Join(tempDir, "archive.zip"))
	require.NoError(t, err)
	defer f.Close()

	archive := zip.NewWriter(f)
	defer archive.Close()
	fileInArchive, err := archive.Create("test.txt")
	require.NoError(t, err)
	fmt.Fprint(fileInArchive, "testtest")
	archive.Close()
	f.Close()

	fileServer := httptest.NewServer(http.FileServer(http.Dir(tempDir)))
	defer fileServer.Close()

	response := testEntryServer(t, fileServer.URL+"/archive.zip", "test.txt")

	require.Equal(t, 200, response.Code)

	testhelper.RequireResponseHeader(t, response,
		"Content-Type",
		"text/plain; charset=utf-8")
	testhelper.RequireResponseHeader(t, response,
		"Content-Disposition",
		"attachment; filename=\"test.txt\"")

	testhelper.RequireResponseBody(t, response, "testtest")
}

func TestDownloadingNonExistingFile(t *testing.T) {
	tempFile, err := os.CreateTemp(t.TempDir(), "uploads")
	require.NoError(t, err)
	defer tempFile.Close()

	archive := zip.NewWriter(tempFile)
	defer archive.Close()
	archive.Close()

	response := testEntryServer(t, tempFile.Name(), "test")
	require.Equal(t, 404, response.Code)
}

func TestDownloadingFromInvalidArchive(t *testing.T) {
	response := testEntryServer(t, "path/to/non/existing/file", "test")
	require.Equal(t, 404, response.Code)
}

func TestIncompleteApiResponse(t *testing.T) {
	response := testEntryServer(t, "", "")
	require.Equal(t, 500, response.Code)
}

func TestDownloadingFromNonExistingHTTPArchive(t *testing.T) {
	tempDir := t.TempDir()

	fileServer := httptest.NewServer(http.FileServer(http.Dir(tempDir)))
	defer fileServer.Close()

	response := testEntryServer(t, fileServer.URL+"/not-existing-archive-file.zip", "test.txt")

	require.Equal(t, 404, response.Code)
}
