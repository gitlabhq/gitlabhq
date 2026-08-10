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
const entryServerExtraHeader1 = "X-Custom-Header1"
const entryServerExtraHeader1Value = "Header1"
const entryServerExtraHeader2 = "X-Custom-Header2"
const entryServerExtraHeader2Value = "Header2"

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

		// add metrics tracker
		r = testhelper.RequestWithMetrics(t, r)

		SendURL.Inject(w, r, data)

		testhelper.AssertMetrics(t, r)
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
		w.Header().Set(entryServerExtraHeader1, entryServerExtraHeader1Value)
		w.Header().Set(entryServerExtraHeader2, entryServerExtraHeader2Value)

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

		// add metrics tracker
		r = testhelper.RequestWithMetrics(t, r)

		SendURL.Inject(w, r, data)
		testhelper.AssertMetrics(t, r)
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

	// add metrics tracker
	request = testhelper.RequestWithMetrics(t, request)

	SendURL.Inject(response, request, data)

	require.Equal(t, http.StatusTeapot, response.Code)
	testhelper.AssertMetrics(t, request)
}

// ErrorResponseStatus and TimeoutResponseStatus only apply when the request
// itself fails, i.e. when http.Client.Do returns an error (see
// handleRequestError). A response that completed is proxied with its own status,
// so a real upstream 5xx or 429 reaches the client unchanged rather than being
// collapsed into the configured status. The npm packument and PyPI Simple-index
// forwards both set ErrorResponseStatus, so pin the distinction here.
func TestCompletedNonSuccessStatusIsNotReplacedByErrorResponseStatus(t *testing.T) {
	for _, status := range []int{
		http.StatusInternalServerError,
		http.StatusServiceUnavailable,
		http.StatusTooManyRequests,
	} {
		t.Run(http.StatusText(status), func(t *testing.T) {
			const upstreamBody = "upstream error page"

			upstream := httptest.NewServer(http.HandlerFunc(func(w http.ResponseWriter, _ *http.Request) {
				w.WriteHeader(status)
				_, _ = io.WriteString(w, upstreamBody)
			}))
			defer upstream.Close()

			sendData := map[string]interface{}{
				"URL":                   upstream.URL,
				"ErrorResponseStatus":   http.StatusBadGateway,
				"TimeoutResponseStatus": http.StatusBadGateway,
			}
			jsonParams, err := json.Marshal(sendData)
			require.NoError(t, err)
			data := base64.URLEncoding.EncodeToString(jsonParams)

			response := httptest.NewRecorder()
			request := testhelper.RequestWithMetrics(t, httptest.NewRequest("GET", "/target", nil))

			SendURL.Inject(response, request, data)
			testhelper.AssertMetrics(t, request)

			require.Equal(t, status, response.Code,
				"a completed upstream response must keep its own status, not ErrorResponseStatus")
			assert.Equal(t, upstreamBody, response.Body.String())
		})
	}
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
	require.Equal(t, http.StatusForbidden, response.Code)
	require.Equal(t, "Forbidden\n", response.Body.String())
}

func TestSSRFFilterWithAllowLocalhost(t *testing.T) {
	response := testEntryServer(t, "/get/request", nil, false, option{Key: "SSRFFilter", Value: true}, option{Key: "AllowLocalhost", Value: true})

	require.Equal(t, http.StatusOK, response.Code)
}

func TestRestrictForwardedResponseHeaders(t *testing.T) {
	restrictForwardedResponseHeadersParams := &map[string]interface{}{
		"Enabled":   true,
		"AllowList": []string{entryServerExtraHeader1},
	}

	response := testEntryServer(t, "/get/request", nil, false, option{Key: "RestrictForwardedResponseHeaders", Value: restrictForwardedResponseHeadersParams}, option{Key: "ResponseHeaders", Value: http.Header{"CustomHeader": {"Test"}}})

	require.Equal(t, http.StatusOK, response.Code)

	expectedHeaders := http.Header{
		"Content-Disposition":   []string{"attachment; filename=\"archive.txt\""},
		"Cache-Control":         []string{"no-cache"},
		"Expires":               []string{""},
		"Date":                  []string{"Wed, 21 Oct 2015 05:28:00 GMT"},
		"Pragma":                []string{"no-cache"},
		entryServerExtraHeader1: []string{entryServerExtraHeader1Value},
		"Customheader":          []string{"Test"},
	}

	require.Equal(t, expectedHeaders, response.Header())
}

func TestSendURLWithJSONTransform(t *testing.T) {
	const (
		npmTarball    = "https://registry.npmjs.org/lodash/-/lodash-4.17.21.tgz"
		gitlabTarball = "https://gitlab.example.com/api/v4/projects/7/packages/npm/lodash/-/lodash-4.17.21.tgz"
	)
	transformConfig := map[string]interface{}{
		"Key":  "tarball",
		"From": "https://registry.npmjs.org/",
		"To":   "https://gitlab.example.com/api/v4/projects/7/packages/npm/",
	}
	body := `{"dist":{"tarball":"` + npmTarball + `"}}`

	tests := []struct {
		name            string
		status          int
		transform       map[string]interface{}
		wantContains    string
		wantNotContains string
	}{
		{
			name:            "rewrites the tarball on a 2xx JSON response",
			status:          http.StatusOK,
			transform:       transformConfig,
			wantContains:    gitlabTarball,
			wantNotContains: npmTarball,
		},
		{
			name:         "does not transform a non-2xx response",
			status:       http.StatusNotFound,
			transform:    transformConfig,
			wantContains: npmTarball,
		},
		{
			name:         "passes the body through unchanged without a transform config",
			status:       http.StatusOK,
			transform:    nil,
			wantContains: npmTarball,
		},
	}

	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			upstream := httptest.NewServer(http.HandlerFunc(func(w http.ResponseWriter, _ *http.Request) {
				w.Header().Set("Content-Type", "application/json")
				w.WriteHeader(tt.status)
				_, _ = io.WriteString(w, body)
			}))
			defer upstream.Close()

			sendData := map[string]interface{}{"URL": upstream.URL}
			if tt.transform != nil {
				sendData["TransformConfig"] = tt.transform
			}
			jsonParams, err := json.Marshal(sendData)
			require.NoError(t, err)
			data := base64.URLEncoding.EncodeToString(jsonParams)

			response := httptest.NewRecorder()
			request := httptest.NewRequest("GET", "/target", nil)
			request = testhelper.RequestWithMetrics(t, request)

			SendURL.Inject(response, request, data)
			testhelper.AssertMetrics(t, request)

			require.Equal(t, tt.status, response.Code)
			assert.Contains(t, response.Body.String(), tt.wantContains)
			if tt.wantNotContains != "" {
				assert.NotContains(t, response.Body.String(), tt.wantNotContains)
			}
		})
	}
}

func TestSendURLTransformMalformedUpstreamBody(t *testing.T) {
	transformConfig := map[string]interface{}{
		"Key":  "tarball",
		"From": "https://registry.npmjs.org/",
		"To":   "https://gdk.test:3443/api/v4/projects/7/packages/npm/",
	}

	// A 2xx upstream body that is not valid JSON. The 200 status is written
	// before streaming begins, so the transform's mid-stream parse error can't
	// be turned into an error status: the client receives 200 with a truncated
	// body, and the failure is logged server-side.
	upstream := httptest.NewServer(http.HandlerFunc(func(w http.ResponseWriter, _ *http.Request) {
		w.Header().Set("Content-Type", "application/json")
		w.WriteHeader(http.StatusOK)
		_, _ = io.WriteString(w, `{"dist":{"tarball":`)
	}))
	defer upstream.Close()

	sendData := map[string]interface{}{"URL": upstream.URL, "TransformConfig": transformConfig}
	jsonParams, err := json.Marshal(sendData)
	require.NoError(t, err)
	data := base64.URLEncoding.EncodeToString(jsonParams)

	response := httptest.NewRecorder()
	request := httptest.NewRequest("GET", "/target", nil)
	request = testhelper.RequestWithMetrics(t, request)

	SendURL.Inject(response, request, data)
	testhelper.AssertMetrics(t, request)

	require.Equal(t, http.StatusOK, response.Code)
	assert.NotContains(t, response.Body.String(), "gdk.test")
}

func TestSendURLWithHTMLTransform(t *testing.T) {
	const (
		pypiFile   = "https://files.pythonhosted.org/packages/aa/requests-2.31.0.tar.gz"
		gitlabFile = "https://gitlab.example.com/api/v4/projects/7/packages/pypi/forward/requests/packages/aa/requests-2.31.0.tar.gz"
	)
	body := `<a href="` + pypiFile + `#sha256=abc">requests-2.31.0.tar.gz</a>`

	upstream := httptest.NewServer(http.HandlerFunc(func(w http.ResponseWriter, _ *http.Request) {
		w.Header().Set("Content-Type", "text/html")
		w.WriteHeader(http.StatusOK)
		_, _ = io.WriteString(w, body)
	}))
	defer upstream.Close()

	sendData := map[string]interface{}{
		"URL": upstream.URL,
		"TransformConfig": map[string]interface{}{
			"Format": "html",
			"Key":    "href",
			"From":   "https://files.pythonhosted.org/",
			"To":     "https://gitlab.example.com/api/v4/projects/7/packages/pypi/forward/requests/",
		},
	}
	jsonParams, err := json.Marshal(sendData)
	require.NoError(t, err)
	data := base64.URLEncoding.EncodeToString(jsonParams)

	response := httptest.NewRecorder()
	request := httptest.NewRequest("GET", "/target", nil)
	request = testhelper.RequestWithMetrics(t, request)

	SendURL.Inject(response, request, data)
	testhelper.AssertMetrics(t, request)

	require.Equal(t, http.StatusOK, response.Code)
	assert.Contains(t, response.Body.String(), gitlabFile)
	assert.Contains(t, response.Body.String(), "#sha256=abc")
	assert.NotContains(t, response.Body.String(), "https://files.pythonhosted.org/")
}

// A transform rewrites the document as a whole, so the upstream request must
// ask for all of it. Forwarding the client's Range would yield a 206 whose
// partial body reaches the parser as if it were complete.
func TestRangeHeadersAreDroppedWhenTransforming(t *testing.T) {
	const body = `{"dist":{"tarball":"https://registry.npmjs.org/a/-/a-1.0.0.tgz"}}`

	for _, tt := range []struct {
		name          string
		transform     map[string]interface{}
		wantUpstream  string
		wantStatus    int
		wantRewritten bool
	}{
		{
			name: "with a transform the range is not forwarded",
			transform: map[string]interface{}{
				"Key": "tarball", "From": "https://registry.npmjs.org/", "To": "https://gitlab.example.com/npm/",
			},
			wantUpstream: "", wantStatus: http.StatusOK, wantRewritten: true,
		},
		{
			name:      "without a transform the range is forwarded as before",
			transform: nil, wantUpstream: "bytes=0-9", wantStatus: http.StatusPartialContent,
		},
	} {
		t.Run(tt.name, func(t *testing.T) {
			var gotRange string
			upstream := httptest.NewServer(http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
				gotRange = r.Header.Get("Range")
				if gotRange != "" {
					w.Header().Set("Content-Range", "bytes 0-9/64")
					w.WriteHeader(http.StatusPartialContent)
					_, _ = io.WriteString(w, body[:10])
					return
				}
				w.WriteHeader(http.StatusOK)
				_, _ = io.WriteString(w, body)
			}))
			defer upstream.Close()

			sendData := map[string]interface{}{"URL": upstream.URL}
			if tt.transform != nil {
				sendData["TransformConfig"] = tt.transform
			}
			jsonParams, err := json.Marshal(sendData)
			require.NoError(t, err)

			response := httptest.NewRecorder()
			request := httptest.NewRequest("GET", "/target", nil)
			request.Header.Set("Range", "bytes=0-9")
			request = testhelper.RequestWithMetrics(t, request)

			SendURL.Inject(response, request, base64.URLEncoding.EncodeToString(jsonParams))
			testhelper.AssertMetrics(t, request)

			assert.Equal(t, tt.wantUpstream, gotRange, "Range seen by upstream")
			require.Equal(t, tt.wantStatus, response.Code)
			if tt.wantRewritten {
				assert.Contains(t, response.Body.String(), "https://gitlab.example.com/npm/a/-/a-1.0.0.tgz")
			}
		})
	}
}

// An https From also matches its http spelling, so an upstream entry served over
// http cannot slip past the rewrite and be fetched directly. Derived from From
// rather than hardcoded, so it stays scoped to each caller's own prefix.
func TestTransformAlsoMatchesInsecureScheme(t *testing.T) {
	const (
		valueKey   = "url"
		cfgField   = "TransformConfig"
		npmFrom    = "https://registry.npmjs.org/"
		npmTo      = "https://gitlab.example.com/npm/"
		pypiFrom   = "https://"
		pypiTo     = "https://gitlab.example.com/pypi/forward/pkg/"
		unrelated  = "http://evil.example.com/a-1.0.0.tgz"
		npmTarball = "a/-/a-1.0.0.tgz"
	)

	for _, tt := range []struct {
		name     string
		from     string
		to       string
		body     string
		want     string
		unwanted string
	}{
		{
			name: "pypi matches on scheme alone",
			from: pypiFrom, to: pypiTo,
			body: `{"url":"http://files.pythonhosted.org/p/pkg-1.0.tar.gz"}`,
			want: pypiTo + "files.pythonhosted.org/p/pkg-1.0.tar.gz",
		},
		{
			name: "npm keeps its host scoping",
			from: npmFrom, to: npmTo,
			body: `{"url":"http://registry.npmjs.org/` + npmTarball + `"}`,
			want: npmTo + npmTarball,
		},
		{
			name: "npm does not capture an unrelated http host",
			from: npmFrom, to: npmTo,
			body:     `{"url":"` + unrelated + `"}`,
			want:     unrelated,
			unwanted: npmTo + "a-1.0.0.tgz",
		},
	} {
		t.Run(tt.name, func(t *testing.T) {
			upstream := httptest.NewServer(http.HandlerFunc(func(w http.ResponseWriter, _ *http.Request) {
				w.Header().Set("Content-Type", "application/json")
				_, _ = io.WriteString(w, tt.body)
			}))
			defer upstream.Close()

			sendData := map[string]interface{}{
				"URL":    upstream.URL,
				cfgField: map[string]interface{}{"Key": valueKey, "From": tt.from, "To": tt.to},
			}
			jsonParams, err := json.Marshal(sendData)
			require.NoError(t, err)

			response := httptest.NewRecorder()
			request := testhelper.RequestWithMetrics(t, httptest.NewRequest("GET", "/target", nil))
			SendURL.Inject(response, request, base64.URLEncoding.EncodeToString(jsonParams))
			testhelper.AssertMetrics(t, request)

			assert.Contains(t, response.Body.String(), tt.want)
			if tt.unwanted != "" {
				assert.NotContains(t, response.Body.String(), tt.unwanted)
			}
		})
	}
}
