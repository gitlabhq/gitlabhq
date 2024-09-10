package sendurl

import (
	"encoding/base64"
	"encoding/json"
	"io"
	"net/http"
	"net/http/httptest"
	"os"
	"testing"
	"time"

	"github.com/stretchr/testify/assert"
	"github.com/stretchr/testify/require"

	"gitlab.com/gitlab-org/gitlab/workhorse/internal/testhelper"
)

const testData = `123456789012345678901234567890`
const testDataEtag = `W/"myetag"`

type option struct {
	Key   string
	Value interface{}
}

func testEntryServer(t *testing.T, requestURL string, httpHeaders http.Header, allowRedirects bool, options ...option) *httptest.ResponseRecorder {
	requestHandler := func(w http.ResponseWriter, r *http.Request) {
		assert.Equal(t, "GET", r.Method)

		sendData := map[string]interface{}{
			"URL":            r.URL.String() + "/file",
			"AllowRedirects": allowRedirects,
		}

		for _, o := range options {
			sendData[o.Key] = o.Value
		}

		jsonParams, err := json.Marshal(sendData)
		assert.NoError(t, err)
		data := base64.URLEncoding.EncodeToString(jsonParams)

		// The server returns a Content-Disposition
		w.Header().Set("Content-Disposition", "attachment; filename=\"archive.txt\"")
		w.Header().Set("Cache-Control", "no-cache")
		w.Header().Set("Expires", "")
		w.Header().Set("Date", "Wed, 21 Oct 2015 05:28:00 GMT")
		w.Header().Set("Pragma", "no-cache")

		SendURL.Inject(w, r, data)
	}
	serveFile := func(w http.ResponseWriter, r *http.Request) {
		assert.Equal(t, "GET", r.Method)

		tempFile, err := os.CreateTemp("", "download_file")
		assert.NoError(t, err)
		assert.NoError(t, os.Remove(tempFile.Name()))
		defer tempFile.Close()
		_, err = tempFile.Write([]byte(testData))
		assert.NoError(t, err)

		w.Header().Set("Etag", testDataEtag)
		w.Header().Set("Cache-Control", "public")
		w.Header().Set("Expires", "Wed, 21 Oct 2015 07:28:00 GMT")
		w.Header().Set("Date", "Wed, 21 Oct 2015 06:28:00 GMT")
		w.Header().Set("Pragma", "")

		http.ServeContent(w, r, "archive.txt", time.Now(), tempFile)
	}
	redirectFile := func(w http.ResponseWriter, r *http.Request) {
		assert.Equal(t, "GET", r.Method)
		http.Redirect(w, r, r.URL.String()+"/download", http.StatusTemporaryRedirect)
	}
	timeoutFile := func(_ http.ResponseWriter, _ *http.Request) {
		time.Sleep(20 * time.Millisecond)
	}

	mux := http.NewServeMux()
	mux.HandleFunc("/get/request", requestHandler)
	mux.HandleFunc("/get/request/file", serveFile)
	mux.HandleFunc("/get/redirect", requestHandler)
	mux.HandleFunc("/get/redirect/file", redirectFile)
	mux.HandleFunc("/get/redirect/file/download", serveFile)
	mux.HandleFunc("/get/file-not-existing", requestHandler)
	mux.HandleFunc("/get/timeout", requestHandler)
	mux.HandleFunc("/get/timeout/file", timeoutFile)

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

func TestPostRequest(t *testing.T) {
	body := "any string"
	header := map[string][]string{"Authorization": {"Bearer token"}}
	postRequestHandler := func(w http.ResponseWriter, r *http.Request) {
		assert.Equal(t, "POST", r.Method)

		url := r.URL.String() + "/external/url"

		sendData := map[string]interface{}{
			"URL":    url,
			"Body":   body,
			"Header": header,
			"Method": "POST",
		}
		jsonParams, err := json.Marshal(sendData)
		assert.NoError(t, err)

		data := base64.URLEncoding.EncodeToString(jsonParams)

		SendURL.Inject(w, r, data)
	}
	externalPostURLHandler := func(w http.ResponseWriter, r *http.Request) {
		assert.Equal(t, "POST", r.Method)

		b, err := io.ReadAll(r.Body)
		assert.NoError(t, err)
		assert.Equal(t, body, string(b))

		assert.Equal(t, []string{"Bearer token"}, r.Header["Authorization"])

		w.Write([]byte(testData))
	}

	mux := http.NewServeMux()
	mux.HandleFunc("/post/request/external/url", externalPostURLHandler)

	server := httptest.NewServer(mux)
	defer server.Close()

	httpRequest, err := http.NewRequest("POST", server.URL+"/post/request", nil)
	require.NoError(t, err)

	response := httptest.NewRecorder()
	postRequestHandler(response, httpRequest)

	require.Equal(t, http.StatusOK, response.Code)

	result, err := io.ReadAll(response.Body)
	require.NoError(t, err)
	require.Equal(t, testData, string(result))
}

func TestResponseHeaders(t *testing.T) {
	response := testEntryServer(t, "/get/request", http.Header{"CustomHeader": {"Upstream"}}, false, option{Key: "ResponseHeaders", Value: http.Header{"CustomHeader": {"Overridden"}}})
	testhelper.RequireResponseHeader(t, response, "CustomHeader", "Overridden")
}

func TestTimeout(t *testing.T) {
	response := testEntryServer(t, "/get/timeout", nil, false, option{Key: "ResponseHeaderTimeout", Value: "10ms"})
	require.Equal(t, http.StatusInternalServerError, response.Code)
}

func TestTimeoutWithCustomStatusCode(t *testing.T) {
	response := testEntryServer(t, "/get/timeout", nil, false, option{Key: "ResponseHeaderTimeout", Value: "10ms"}, option{Key: "TimeoutResponseStatus", Value: http.StatusTeapot})
	require.Equal(t, http.StatusTeapot, response.Code)
}

func TestErrorWithCustomStatusCode(t *testing.T) {
	sendData := map[string]interface{}{
		"URL":                 "url",
		"ErrorResponseStatus": http.StatusTeapot,
	}

	jsonParams, err := json.Marshal(sendData)
	require.NoError(t, err)
	data := base64.URLEncoding.EncodeToString(jsonParams)

	response := httptest.NewRecorder()
	request := httptest.NewRequest("GET", "/target", nil)

	SendURL.Inject(response, request, data)

	require.Equal(t, http.StatusTeapot, response.Code)
}

func TestHttpClientReuse(t *testing.T) {
	expectedKey := cacheKey{
		requestTimeout:  0,
		responseTimeout: 0,
		allowRedirects:  false,
	}
	httpClients.Delete(expectedKey)

	response := testEntryServer(t, "/get/request", nil, false)
	require.Equal(t, http.StatusOK, response.Code)
	_, found := httpClients.Load(expectedKey)
	require.True(t, found)

	storedClient := &http.Client{}
	httpClients.Store(expectedKey, storedClient)
	require.Equal(t, cachedClient(entryParams{}), storedClient)
	require.NotEqual(t, cachedClient(entryParams{AllowRedirects: true}), storedClient)
}

func TestSSRFFilter(t *testing.T) {
	response := testEntryServer(t, "/get/request", nil, false, option{Key: "SSRFFilter", Value: true})

	// Test uses loopback IP like 127.0.0.x and thus fails
	require.Equal(t, http.StatusInternalServerError, response.Code)
}

func TestSSRFFilterWithAllowLocalhost(t *testing.T) {
	response := testEntryServer(t, "/get/request", nil, false, option{Key: "SSRFFilter", Value: true}, option{Key: "AllowLocalhost", Value: true})

	require.Equal(t, http.StatusOK, response.Code)
}
