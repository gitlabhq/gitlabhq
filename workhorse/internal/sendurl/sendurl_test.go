package sendurl

import (
	"encoding/base64"
	"fmt"
	"io/ioutil"
	"net/http"
	"net/http/httptest"
	"os"
	"strconv"
	"testing"
	"time"

	"github.com/stretchr/testify/require"

	"gitlab.com/gitlab-org/gitlab/workhorse/internal/testhelper"
)

const testData = `123456789012345678901234567890`
const testDataEtag = `W/"myetag"`

func testEntryServer(t *testing.T, requestURL string, httpHeaders http.Header, allowRedirects bool) *httptest.ResponseRecorder {
	requestHandler := func(w http.ResponseWriter, r *http.Request) {
		require.Equal(t, "GET", r.Method)

		url := r.URL.String() + "/file"
		jsonParams := fmt.Sprintf(`{"URL":%q,"AllowRedirects":%s}`,
			url, strconv.FormatBool(allowRedirects))
		data := base64.URLEncoding.EncodeToString([]byte(jsonParams))

		// The server returns a Content-Disposition
		w.Header().Set("Content-Disposition", "attachment; filename=\"archive.txt\"")
		w.Header().Set("Cache-Control", "no-cache")
		w.Header().Set("Expires", "")
		w.Header().Set("Date", "Wed, 21 Oct 2015 05:28:00 GMT")
		w.Header().Set("Pragma", "no-cache")

		SendURL.Inject(w, r, data)
	}
	serveFile := func(w http.ResponseWriter, r *http.Request) {
		require.Equal(t, "GET", r.Method)

		tempFile, err := ioutil.TempFile("", "download_file")
		require.NoError(t, err)
		require.NoError(t, os.Remove(tempFile.Name()))
		defer tempFile.Close()
		_, err = tempFile.Write([]byte(testData))
		require.NoError(t, err)

		w.Header().Set("Etag", testDataEtag)
		w.Header().Set("Cache-Control", "public")
		w.Header().Set("Expires", "Wed, 21 Oct 2015 07:28:00 GMT")
		w.Header().Set("Date", "Wed, 21 Oct 2015 06:28:00 GMT")
		w.Header().Set("Pragma", "")

		http.ServeContent(w, r, "archive.txt", time.Now(), tempFile)
	}
	redirectFile := func(w http.ResponseWriter, r *http.Request) {
		require.Equal(t, "GET", r.Method)
		http.Redirect(w, r, r.URL.String()+"/download", http.StatusTemporaryRedirect)
	}

	mux := http.NewServeMux()
	mux.HandleFunc("/get/request", requestHandler)
	mux.HandleFunc("/get/request/file", serveFile)
	mux.HandleFunc("/get/redirect", requestHandler)
	mux.HandleFunc("/get/redirect/file", redirectFile)
	mux.HandleFunc("/get/redirect/file/download", serveFile)
	mux.HandleFunc("/get/file-not-existing", requestHandler)

	server := httptest.NewServer(mux)
	defer server.Close()

	httpRequest, err := http.NewRequest("GET", server.URL+requestURL, nil)
	require.NoError(t, err)
	if httpHeaders != nil {
		httpRequest.Header = httpHeaders
	}

	response := httptest.NewRecorder()
	mux.ServeHTTP(response, httpRequest)
	return response
}

func TestDownloadingUsingSendURL(t *testing.T) {
	response := testEntryServer(t, "/get/request", nil, false)
	require.Equal(t, http.StatusOK, response.Code)

	testhelper.RequireResponseHeader(t, response,
		"Content-Type",
		"text/plain; charset=utf-8")
	testhelper.RequireResponseHeader(t, response,
		"Content-Disposition",
		"attachment; filename=\"archive.txt\"")

	testhelper.RequireResponseBody(t, response, testData)
}

func TestDownloadingAChunkOfDataWithSendURL(t *testing.T) {
	httpHeaders := http.Header{
		"Range": []string{
			"bytes=1-2",
		},
	}

	response := testEntryServer(t, "/get/request", httpHeaders, false)
	require.Equal(t, http.StatusPartialContent, response.Code)

	testhelper.RequireResponseHeader(t, response,
		"Content-Type",
		"text/plain; charset=utf-8")
	testhelper.RequireResponseHeader(t, response,
		"Content-Disposition",
		"attachment; filename=\"archive.txt\"")
	testhelper.RequireResponseHeader(t, response,
		"Content-Range",
		"bytes 1-2/30")

	testhelper.RequireResponseBody(t, response, "23")
}

func TestAccessingAlreadyDownloadedFileWithSendURL(t *testing.T) {
	httpHeaders := http.Header{
		"If-None-Match": []string{testDataEtag},
	}

	response := testEntryServer(t, "/get/request", httpHeaders, false)
	require.Equal(t, http.StatusNotModified, response.Code)
}

func TestAccessingRedirectWithSendURL(t *testing.T) {
	response := testEntryServer(t, "/get/redirect", nil, false)
	require.Equal(t, http.StatusTemporaryRedirect, response.Code)
}

func TestAccessingAllowedRedirectWithSendURL(t *testing.T) {
	response := testEntryServer(t, "/get/redirect", nil, true)
	require.Equal(t, http.StatusOK, response.Code)

	testhelper.RequireResponseHeader(t, response,
		"Content-Type",
		"text/plain; charset=utf-8")
	testhelper.RequireResponseHeader(t, response,
		"Content-Disposition",
		"attachment; filename=\"archive.txt\"")
}

func TestAccessingAllowedRedirectWithChunkOfDataWithSendURL(t *testing.T) {
	httpHeaders := http.Header{
		"Range": []string{
			"bytes=1-2",
		},
	}

	response := testEntryServer(t, "/get/redirect", httpHeaders, true)
	require.Equal(t, http.StatusPartialContent, response.Code)

	testhelper.RequireResponseHeader(t, response,
		"Content-Type",
		"text/plain; charset=utf-8")
	testhelper.RequireResponseHeader(t, response,
		"Content-Disposition",
		"attachment; filename=\"archive.txt\"")
	testhelper.RequireResponseHeader(t, response,
		"Content-Range",
		"bytes 1-2/30")

	testhelper.RequireResponseBody(t, response, "23")
}

func TestOriginalCacheHeadersPreservedWithSendURL(t *testing.T) {
	response := testEntryServer(t, "/get/redirect", nil, true)
	require.Equal(t, http.StatusOK, response.Code)

	testhelper.RequireResponseHeader(t, response,
		"Cache-Control",
		"no-cache")
	testhelper.RequireResponseHeader(t, response,
		"Expires",
		"")
	testhelper.RequireResponseHeader(t, response,
		"Date",
		"Wed, 21 Oct 2015 05:28:00 GMT")
	testhelper.RequireResponseHeader(t, response,
		"Pragma",
		"no-cache")
}

func TestDownloadingNonExistingFileUsingSendURL(t *testing.T) {
	response := testEntryServer(t, "/invalid/path", nil, false)
	require.Equal(t, http.StatusNotFound, response.Code)
}

func TestDownloadingNonExistingRemoteFileWithSendURL(t *testing.T) {
	response := testEntryServer(t, "/get/file-not-existing", nil, false)
	require.Equal(t, http.StatusNotFound, response.Code)
}
