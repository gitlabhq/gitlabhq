package main

import (
	"bytes"
	"compress/gzip"
	"encoding/base64"
	"encoding/json"
	"fmt"
	"image/png"
	"io"
	"io/ioutil"
	"net/http"
	"net/http/httptest"
	"net/url"
	"os"
	"os/exec"
	"path"
	"regexp"
	"strconv"
	"strings"
	"testing"
	"time"

	"github.com/sirupsen/logrus"
	"github.com/stretchr/testify/require"
	"gitlab.com/gitlab-org/gitaly/v14/proto/go/gitalypb"
	"gitlab.com/gitlab-org/labkit/log"

	"gitlab.com/gitlab-org/gitlab-workhorse/internal/api"
	"gitlab.com/gitlab-org/gitlab-workhorse/internal/config"
	"gitlab.com/gitlab-org/gitlab-workhorse/internal/gitaly"
	"gitlab.com/gitlab-org/gitlab-workhorse/internal/helper"
	"gitlab.com/gitlab-org/gitlab-workhorse/internal/secret"
	"gitlab.com/gitlab-org/gitlab-workhorse/internal/testhelper"
	"gitlab.com/gitlab-org/gitlab-workhorse/internal/upstream"
)

const scratchDir = "testdata/scratch"
const testRepoRoot = "testdata/data"
const testDocumentRoot = "testdata/public"
const testAltDocumentRoot = "testdata/alt-public"

var absDocumentRoot string

const testRepo = "group/test.git"
const testProject = "group/test"

var checkoutDir = path.Join(scratchDir, "test")
var cacheDir = path.Join(scratchDir, "cache")

func TestMain(m *testing.M) {
	if _, err := os.Stat(path.Join(testRepoRoot, testRepo)); os.IsNotExist(err) {
		log.WithError(err).Fatal("cannot find test repository. Please run 'make prepare-tests'")
	}

	if err := testhelper.BuildExecutables(); err != nil {
		log.WithError(err).Fatal()
	}

	defer gitaly.CloseConnections()

	os.Exit(m.Run())
}

func TestDeniedClone(t *testing.T) {
	// Prepare clone directory
	require.NoError(t, os.RemoveAll(scratchDir))

	// Prepare test server and backend
	ts := testAuthServer(t, nil, nil, 403, "Access denied")
	defer ts.Close()
	ws := startWorkhorseServer(ts.URL)
	defer ws.Close()

	// Do the git clone
	cloneCmd := exec.Command("git", "clone", fmt.Sprintf("%s/%s", ws.URL, testRepo), checkoutDir)
	out, err := cloneCmd.CombinedOutput()
	t.Log(string(out))
	require.Error(t, err, "git clone should have failed")
}

func TestDeniedPush(t *testing.T) {
	// Prepare the test server and backend
	ts := testAuthServer(t, nil, nil, 403, "Access denied")
	defer ts.Close()
	ws := startWorkhorseServer(ts.URL)
	defer ws.Close()

	// Perform the git push
	pushCmd := exec.Command("git", "push", "-v", fmt.Sprintf("%s/%s", ws.URL, testRepo), fmt.Sprintf("master:%s", newBranch()))
	pushCmd.Dir = checkoutDir
	out, err := pushCmd.CombinedOutput()
	t.Log(string(out))
	require.Error(t, err, "git push should have failed")
}

func TestRegularProjectsAPI(t *testing.T) {
	apiResponse := "API RESPONSE"

	ts := testhelper.TestServerWithHandler(regexp.MustCompile(`.`), func(w http.ResponseWriter, _ *http.Request) {
		_, err := w.Write([]byte(apiResponse))
		require.NoError(t, err)
	})
	defer ts.Close()

	ws := startWorkhorseServer(ts.URL)
	defer ws.Close()

	for _, resource := range []string{
		"/api/v3/projects/123/repository/not/special",
		"/api/v3/projects/foo%2Fbar/repository/not/special",
		"/api/v3/projects/123/not/special",
		"/api/v3/projects/foo%2Fbar/not/special",
		"/api/v3/projects/foo%2Fbar%2Fbaz/repository/not/special",
		"/api/v3/projects/foo%2Fbar%2Fbaz%2Fqux/repository/not/special",
	} {
		resp, body := httpGet(t, ws.URL+resource, nil)

		require.Equal(t, 200, resp.StatusCode, "GET %q: status code", resource)
		require.Equal(t, apiResponse, body, "GET %q: response body", resource)
		requireNginxResponseBuffering(t, "", resp, "GET %q: nginx response buffering", resource)
	}
}

func TestAllowedXSendfileDownload(t *testing.T) {
	contentFilename := "my-content"
	prepareDownloadDir(t)

	allowedXSendfileDownload(t, contentFilename, "foo/uploads/bar")
}

func TestDeniedXSendfileDownload(t *testing.T) {
	contentFilename := "my-content"
	prepareDownloadDir(t)

	deniedXSendfileDownload(t, contentFilename, "foo/uploads/bar")
}

func TestAllowedStaticFile(t *testing.T) {
	content := "PUBLIC"
	require.NoError(t, setupStaticFile("static file.txt", content))

	proxied := false
	ts := testhelper.TestServerWithHandler(regexp.MustCompile(`.`), func(w http.ResponseWriter, r *http.Request) {
		proxied = true
		w.WriteHeader(404)
	})
	defer ts.Close()
	ws := startWorkhorseServer(ts.URL)
	defer ws.Close()

	for _, resource := range []string{
		"/static%20file.txt",
		"/static file.txt",
	} {
		resp, body := httpGet(t, ws.URL+resource, nil)

		require.Equal(t, 200, resp.StatusCode, "GET %q: status code", resource)
		require.Equal(t, content, body, "GET %q: response body", resource)
		requireNginxResponseBuffering(t, "no", resp, "GET %q: nginx response buffering", resource)
		require.False(t, proxied, "GET %q: should not have made it to backend", resource)
	}
}

func TestStaticFileRelativeURL(t *testing.T) {
	content := "PUBLIC"
	require.NoError(t, setupStaticFile("static.txt", content), "create public/static.txt")

	ts := testhelper.TestServerWithHandler(regexp.MustCompile(`.`), http.HandlerFunc(http.NotFound))
	defer ts.Close()
	backendURLString := ts.URL + "/my-relative-url"
	log.Info(backendURLString)
	ws := startWorkhorseServer(backendURLString)
	defer ws.Close()

	resource := "/my-relative-url/static.txt"
	resp, body := httpGet(t, ws.URL+resource, nil)

	require.Equal(t, 200, resp.StatusCode, "GET %q: status code", resource)
	require.Equal(t, content, body, "GET %q: response body", resource)
}

func TestAllowedPublicUploadsFile(t *testing.T) {
	content := "PRIVATE but allowed"
	require.NoError(t, setupStaticFile("uploads/static file.txt", content), "create public/uploads/static file.txt")

	proxied := false
	ts := testhelper.TestServerWithHandler(regexp.MustCompile(`.`), func(w http.ResponseWriter, r *http.Request) {
		proxied = true
		w.Header().Add("X-Sendfile", absDocumentRoot+r.URL.Path)
		w.WriteHeader(200)
	})
	defer ts.Close()
	ws := startWorkhorseServer(ts.URL)
	defer ws.Close()

	for _, resource := range []string{
		"/uploads/static%20file.txt",
		"/uploads/static file.txt",
	} {
		resp, body := httpGet(t, ws.URL+resource, nil)

		require.Equal(t, 200, resp.StatusCode, "GET %q: status code", resource)
		require.Equal(t, content, body, "GET %q: response body", resource)
		require.True(t, proxied, "GET %q: never made it to backend", resource)
	}
}

func TestDeniedPublicUploadsFile(t *testing.T) {
	content := "PRIVATE"
	require.NoError(t, setupStaticFile("uploads/static.txt", content), "create public/uploads/static.txt")

	proxied := false
	ts := testhelper.TestServerWithHandler(regexp.MustCompile(`.`), func(w http.ResponseWriter, _ *http.Request) {
		proxied = true
		w.WriteHeader(404)
	})
	defer ts.Close()
	ws := startWorkhorseServer(ts.URL)
	defer ws.Close()

	for _, resource := range []string{
		"/uploads/static.txt",
		"/uploads%2Fstatic.txt",
		"/foobar%2F%2E%2E%2Fuploads/static.txt",
	} {
		t.Run(resource, func(t *testing.T) {
			resp, body := httpGet(t, ws.URL+resource, nil)

			require.Equal(t, 404, resp.StatusCode, "GET %q: status code", resource)
			require.Equal(t, "", body, "GET %q: response body", resource)
			require.True(t, proxied, "GET %q: never made it to backend", resource)
		})
	}
}

func TestStaticErrorPage(t *testing.T) {
	errorPageBody := `<html>
<body>
This is a static error page for code 499
</body>
</html>
`
	require.NoError(t, setupStaticFile("499.html", errorPageBody))
	ts := testhelper.TestServerWithHandler(nil, func(w http.ResponseWriter, _ *http.Request) {
		upstreamError := "499"
		// This is the point of the test: the size of the upstream response body
		// should be overridden.
		require.NotEqual(t, len(upstreamError), len(errorPageBody))
		w.WriteHeader(499)
		_, err := w.Write([]byte(upstreamError))
		require.NoError(t, err)
	})
	defer ts.Close()

	ws := startWorkhorseServer(ts.URL)
	defer ws.Close()

	resourcePath := "/error-499"
	resp, body := httpGet(t, ws.URL+resourcePath, nil)

	require.Equal(t, 499, resp.StatusCode, "GET %q: status code", resourcePath)
	require.Equal(t, string(errorPageBody), body, "GET %q: response body", resourcePath)
}

func TestGzipAssets(t *testing.T) {
	path := "/assets/static.txt"
	content := "asset"
	require.NoError(t, setupStaticFile(path, content))

	buf := &bytes.Buffer{}
	gzipWriter := gzip.NewWriter(buf)
	_, err := gzipWriter.Write([]byte(content))
	require.NoError(t, err)
	require.NoError(t, gzipWriter.Close())
	contentGzip := buf.String()
	require.NoError(t, setupStaticFile(path+".gz", contentGzip))

	proxied := false
	ts := testhelper.TestServerWithHandler(regexp.MustCompile(`.`), func(w http.ResponseWriter, r *http.Request) {
		proxied = true
		w.WriteHeader(404)
	})
	defer ts.Close()
	ws := startWorkhorseServer(ts.URL)
	defer ws.Close()

	testCases := []struct {
		content         string
		path            string
		acceptEncoding  string
		contentEncoding string
	}{
		{content: content, path: path},
		{content: contentGzip, path: path, acceptEncoding: "gzip", contentEncoding: "gzip"},
		{content: contentGzip, path: path, acceptEncoding: "gzip, compress, br", contentEncoding: "gzip"},
		{content: contentGzip, path: path, acceptEncoding: "br;q=1.0, gzip;q=0.8, *;q=0.1", contentEncoding: "gzip"},
	}

	for _, tc := range testCases {
		desc := fmt.Sprintf("accept-encoding: %q", tc.acceptEncoding)
		req, err := http.NewRequest("GET", ws.URL+tc.path, nil)
		require.NoError(t, err, desc)
		req.Header.Set("Accept-Encoding", tc.acceptEncoding)

		resp, err := http.DefaultTransport.RoundTrip(req)
		require.NoError(t, err, desc)
		defer resp.Body.Close()
		b, err := ioutil.ReadAll(resp.Body)
		require.NoError(t, err, desc)

		require.Equal(t, 200, resp.StatusCode, "%s: status code", desc)
		require.Equal(t, tc.content, string(b), "%s: response body", desc)
		require.Equal(t, tc.contentEncoding, resp.Header.Get("Content-Encoding"), "%s: response body", desc)
		require.False(t, proxied, "%s: should not have made it to backend", desc)
	}
}

func TestAltDocumentAssets(t *testing.T) {
	path := "/assets/static.txt"
	content := "asset"
	require.NoError(t, setupAltStaticFile(path, content))

	buf := &bytes.Buffer{}
	gzipWriter := gzip.NewWriter(buf)
	_, err := gzipWriter.Write([]byte(content))
	require.NoError(t, err)
	require.NoError(t, gzipWriter.Close())
	contentGzip := buf.String()
	require.NoError(t, setupAltStaticFile(path+".gz", contentGzip))

	proxied := false
	ts := testhelper.TestServerWithHandler(regexp.MustCompile(`.`), func(w http.ResponseWriter, r *http.Request) {
		proxied = true
		w.WriteHeader(404)
	})
	defer ts.Close()

	upstreamConfig := newUpstreamConfig(ts.URL)
	upstreamConfig.AltDocumentRoot = testAltDocumentRoot

	ws := startWorkhorseServerWithConfig(upstreamConfig)
	defer ws.Close()

	testCases := []struct {
		desc            string
		path            string
		content         string
		acceptEncoding  string
		contentEncoding string
	}{
		{desc: "plaintext asset", path: path, content: content},
		{desc: "gzip asset available", path: path, content: contentGzip, acceptEncoding: "gzip", contentEncoding: "gzip"},
		{desc: "non-existent file", path: "/assets/non-existent"},
	}

	for _, tc := range testCases {
		req, err := http.NewRequest("GET", ws.URL+tc.path, nil)
		require.NoError(t, err)

		if tc.acceptEncoding != "" {
			req.Header.Set("Accept-Encoding", tc.acceptEncoding)
		}

		resp, err := http.DefaultTransport.RoundTrip(req)
		require.NoError(t, err)
		defer resp.Body.Close()
		b, err := ioutil.ReadAll(resp.Body)
		require.NoError(t, err)

		if tc.content != "" {
			require.Equal(t, 200, resp.StatusCode, "%s: status code", tc.desc)
			require.Equal(t, tc.content, string(b), "%s: response body", tc.desc)
			require.False(t, proxied, "%s: should not have made it to backend", tc.desc)

			if tc.contentEncoding != "" {
				require.Equal(t, tc.contentEncoding, resp.Header.Get("Content-Encoding"))
			}
		} else {
			require.Equal(t, 404, resp.StatusCode, "%s: status code", tc.desc)
		}
	}
}

var sendDataHeader = "Gitlab-Workhorse-Send-Data"

func sendDataResponder(command string, literalJSON string) *httptest.Server {
	handler := func(w http.ResponseWriter, r *http.Request) {
		data := base64.URLEncoding.EncodeToString([]byte(literalJSON))
		w.Header().Set(sendDataHeader, fmt.Sprintf("%s:%s", command, data))

		// This should never be returned
		if _, err := fmt.Fprintf(w, "gibberish"); err != nil {
			panic(err)
		}
	}

	return testhelper.TestServerWithHandler(regexp.MustCompile(`.`), handler)
}

func doSendDataRequest(path string, command, literalJSON string) (*http.Response, []byte, error) {
	ts := sendDataResponder(command, literalJSON)
	defer ts.Close()

	ws := startWorkhorseServer(ts.URL)
	defer ws.Close()

	resp, err := http.Get(ws.URL + path)
	if err != nil {
		return nil, nil, err
	}
	defer resp.Body.Close()

	bodyData, err := ioutil.ReadAll(resp.Body)
	if err != nil {
		return resp, nil, err
	}

	headerValue := resp.Header.Get(sendDataHeader)
	if headerValue != "" {
		return resp, bodyData, fmt.Errorf("%s header should not be present, but has value %q", sendDataHeader, headerValue)
	}

	return resp, bodyData, nil
}

func TestArtifactsGetSingleFile(t *testing.T) {
	// We manually created this zip file in the gitlab-workhorse Git repository
	archivePath := `testdata/artifacts-archive.zip`
	fileName := "myfile"
	fileContents := "MY FILE"
	resourcePath := `/namespace/project/builds/123/artifacts/file/` + fileName
	encodedFilename := base64.StdEncoding.EncodeToString([]byte(fileName))
	jsonParams := fmt.Sprintf(`{"Archive":"%s","Entry":"%s"}`, archivePath, encodedFilename)

	resp, body, err := doSendDataRequest(resourcePath, "artifacts-entry", jsonParams)
	require.NoError(t, err)

	require.Equal(t, 200, resp.StatusCode, "GET %q: status code", resourcePath)
	require.Equal(t, fileContents, string(body), "GET %q: response body", resourcePath)
	requireNginxResponseBuffering(t, "no", resp, "GET %q: nginx response buffering", resourcePath)
}

func TestImageResizing(t *testing.T) {
	imageLocation := `testdata/image.png`
	requestedWidth := 40
	imageFormat := "image/png"
	jsonParams := fmt.Sprintf(`{"Location":"%s","Width":%d, "ContentType":"%s"}`, imageLocation, requestedWidth, imageFormat)
	resourcePath := "/uploads/-/system/user/avatar/123/avatar.png?width=40"

	resp, body, err := doSendDataRequest(resourcePath, "send-scaled-img", jsonParams)
	require.NoError(t, err, "send resize request")
	require.Equal(t, 200, resp.StatusCode, "GET %q: body: %s", resourcePath, body)

	img, err := png.Decode(bytes.NewReader(body))
	require.NoError(t, err, "decode resized image")

	bounds := img.Bounds()
	require.Equal(t, requestedWidth, bounds.Size().X, "wrong width after resizing")
}

func TestSendURLForArtifacts(t *testing.T) {
	expectedBody := strings.Repeat("CONTENT!", 1024)

	regularHandler := http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		w.Header().Set("Content-Length", strconv.Itoa(len(expectedBody)))
		w.Write([]byte(expectedBody))
	})

	chunkedHandler := http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		w.Header().Set("Transfer-Encoding", "chunked")
		w.Write([]byte(expectedBody))
	})

	rawHandler := http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		hj, ok := w.(http.Hijacker)
		require.Equal(t, true, ok)

		conn, buf, err := hj.Hijack()
		require.NoError(t, err)
		defer conn.Close()
		defer buf.Flush()

		fmt.Fprint(buf, "HTTP/1.1 200 OK\r\nContent-Type: application/zip\r\n\r\n")
		fmt.Fprint(buf, expectedBody)
	})

	for _, tc := range []struct {
		name             string
		handler          http.Handler
		transferEncoding []string
		contentLength    int
	}{
		{"No content-length, chunked TE", chunkedHandler, []string{"chunked"}, -1},    // Case 3 in https://tools.ietf.org/html/rfc7230#section-3.3.2
		{"Known content-length, identity TE", regularHandler, nil, len(expectedBody)}, // Case 5 in https://tools.ietf.org/html/rfc7230#section-3.3.2
		{"No content-length, identity TE", rawHandler, []string{"chunked"}, -1},       // Case 7 in https://tools.ietf.org/html/rfc7230#section-3.3.2
	} {
		t.Run(tc.name, func(t *testing.T) {
			server := httptest.NewServer(tc.handler)
			defer server.Close()

			jsonParams := fmt.Sprintf(`{"URL":%q}`, server.URL)

			resourcePath := `/namespace/project/builds/123/artifacts/file/download`
			resp, body, err := doSendDataRequest(resourcePath, "send-url", jsonParams)
			require.NoError(t, err)

			require.Equal(t, http.StatusOK, resp.StatusCode, "GET %q: status code", resourcePath)
			require.Equal(t, int64(tc.contentLength), resp.ContentLength, "GET %q: Content-Length", resourcePath)
			require.Equal(t, tc.transferEncoding, resp.TransferEncoding, "GET %q: Transfer-Encoding", resourcePath)
			require.Equal(t, expectedBody, string(body), "GET %q: response body", resourcePath)
			requireNginxResponseBuffering(t, "no", resp, "GET %q: nginx response buffering", resourcePath)
		})
	}
}

func TestApiContentTypeBlock(t *testing.T) {
	wrongResponse := `{"hello":"world"}`
	ts := testhelper.TestServerWithHandler(regexp.MustCompile(`.`), func(w http.ResponseWriter, _ *http.Request) {
		w.Header().Set("Content-Type", api.ResponseContentType)
		_, err := w.Write([]byte(wrongResponse))
		require.NoError(t, err, "write upstream response")
	})
	defer ts.Close()

	ws := startWorkhorseServer(ts.URL)
	defer ws.Close()

	resourcePath := "/something"
	resp, body := httpGet(t, ws.URL+resourcePath, nil)

	require.Equal(t, 500, resp.StatusCode, "GET %q: status code", resourcePath)
	require.NotContains(t, wrongResponse, body, "GET %q: response body", resourcePath)
}

func TestAPIFalsePositivesAreProxied(t *testing.T) {
	goodResponse := []byte(`<html></html>`)
	ts := testhelper.TestServerWithHandler(regexp.MustCompile(`.`), func(w http.ResponseWriter, r *http.Request) {
		url := r.URL.String()
		if url[len(url)-1] == '/' {
			w.WriteHeader(500)
			w.Write([]byte("PreAuthorize request included a trailing slash"))
		} else if r.Header.Get(secret.RequestHeader) != "" && r.Method != "GET" {
			w.WriteHeader(500)
			w.Write([]byte("non-GET request went through PreAuthorize handler"))
		} else {
			w.Header().Set("Content-Type", "text/html")
			_, err := w.Write(goodResponse)
			require.NoError(t, err)
		}
	})
	defer ts.Close()

	ws := startWorkhorseServer(ts.URL)
	defer ws.Close()

	// Each of these cases is a specially-handled path in Workhorse that may
	// actually be a request to be sent to gitlab-rails.
	for _, tc := range []struct {
		method string
		path   string
	}{
		{"GET", "/nested/group/project/blob/master/foo.git/info/refs"},
		{"POST", "/nested/group/project/blob/master/foo.git/git-upload-pack"},
		{"POST", "/nested/group/project/blob/master/foo.git/git-receive-pack"},
		{"PUT", "/nested/group/project/blob/master/foo.git/gitlab-lfs/objects/0000000000000000000000000000000000000000000000000000000000000000/0"},
		{"GET", "/nested/group/project/blob/master/environments/1/terminal.ws"},
	} {
		t.Run(tc.method+"_"+tc.path, func(t *testing.T) {
			req, err := http.NewRequest(tc.method, ws.URL+tc.path, nil)
			require.NoError(t, err, "Constructing %s %q", tc.method, tc.path)
			resp, err := http.DefaultClient.Do(req)
			require.NoError(t, err, "%s %q", tc.method, tc.path)
			defer resp.Body.Close()

			respBody, err := ioutil.ReadAll(resp.Body)
			require.NoError(t, err, "%s %q: reading body", tc.method, tc.path)

			require.Equal(t, 200, resp.StatusCode, "%s %q: status code", tc.method, tc.path)
			testhelper.RequireResponseHeader(t, resp, "Content-Type", "text/html")
			require.Equal(t, string(goodResponse), string(respBody), "%s %q: response body", tc.method, tc.path)
		})
	}
}

func TestCorrelationIdHeader(t *testing.T) {
	ts := testhelper.TestServerWithHandler(regexp.MustCompile(`.`), func(w http.ResponseWriter, r *http.Request) {
		w.Header().Add("X-Request-Id", "12345678")
		w.WriteHeader(200)
	})
	defer ts.Close()
	ws := startWorkhorseServer(ts.URL)
	defer ws.Close()

	for _, resource := range []string{
		"/api/v3/projects/123/repository/not/special",
	} {
		resp, _ := httpGet(t, ws.URL+resource, nil)

		require.Equal(t, 200, resp.StatusCode, "GET %q: status code", resource)
		requestIds := resp.Header["X-Request-Id"]
		require.Equal(t, 1, len(requestIds), "GET %q: One X-Request-Id present", resource)
	}
}

func TestPropagateCorrelationIdHeader(t *testing.T) {
	ts := testhelper.TestServerWithHandler(regexp.MustCompile(`.`), func(w http.ResponseWriter, r *http.Request) {
		w.Header().Add("X-Request-Id", r.Header.Get("X-Request-Id"))
		w.WriteHeader(200)
	})
	defer ts.Close()

	testCases := []struct {
		desc                   string
		propagateCorrelationID bool
	}{
		{
			desc:                   "propagateCorrelatedId is true",
			propagateCorrelationID: true,
		},
		{
			desc:                   "propagateCorrelatedId is false",
			propagateCorrelationID: false,
		},
	}

	for _, tc := range testCases {
		t.Run(tc.desc, func(t *testing.T) {
			upstreamConfig := newUpstreamConfig(ts.URL)
			upstreamConfig.PropagateCorrelationID = tc.propagateCorrelationID

			ws := startWorkhorseServerWithConfig(upstreamConfig)
			defer ws.Close()

			resource := "/api/v3/projects/123/repository/not/special"
			propagatedRequestId := "Propagated-RequestId-12345678"
			resp, _ := httpGet(t, ws.URL+resource, map[string]string{"X-Request-Id": propagatedRequestId})
			requestIds := resp.Header["X-Request-Id"]

			require.Equal(t, 200, resp.StatusCode, "GET %q: status code", resource)
			require.Equal(t, 1, len(requestIds), "GET %q: One X-Request-Id present", resource)

			if tc.propagateCorrelationID {
				require.Contains(t, requestIds, propagatedRequestId, "GET %q: Has X-Request-Id %s present", resource, propagatedRequestId)
			} else {
				require.NotContains(t, requestIds, propagatedRequestId, "GET %q: X-Request-Id not propagated")
			}
		})
	}
}

func TestRejectUnknownMethod(t *testing.T) {
	ts := testhelper.TestServerWithHandler(regexp.MustCompile(`.`), func(w http.ResponseWriter, r *http.Request) {
		w.WriteHeader(200)
	})
	defer ts.Close()
	ws := startWorkhorseServer(ts.URL)
	defer ws.Close()

	req, err := http.NewRequest("UNKNOWN", ws.URL+"/api/v3/projects/123/repository/not/special", nil)
	require.NoError(t, err)

	resp, err := http.DefaultClient.Do(req)
	require.NoError(t, err)
	defer resp.Body.Close()

	require.Equal(t, http.StatusMethodNotAllowed, resp.StatusCode)
}

func setupStaticFile(fpath, content string) error {
	return setupStaticFileHelper(fpath, content, testDocumentRoot)
}

func setupAltStaticFile(fpath, content string) error {
	return setupStaticFileHelper(fpath, content, testAltDocumentRoot)
}

func setupStaticFileHelper(fpath, content, directory string) error {
	cwd, err := os.Getwd()
	if err != nil {
		return err
	}
	absDocumentRoot = path.Join(cwd, directory)
	if err := os.MkdirAll(path.Join(absDocumentRoot, path.Dir(fpath)), 0755); err != nil {
		return err
	}
	staticFile := path.Join(absDocumentRoot, fpath)
	return ioutil.WriteFile(staticFile, []byte(content), 0666)
}

func prepareDownloadDir(t *testing.T) {
	require.NoError(t, os.RemoveAll(scratchDir))
	require.NoError(t, os.MkdirAll(scratchDir, 0755))
}

func newBranch() string {
	return fmt.Sprintf("branch-%d", time.Now().UnixNano())
}

func testAuthServer(t *testing.T, url *regexp.Regexp, params url.Values, code int, body interface{}) *httptest.Server {
	return testhelper.TestServerWithHandler(url, func(w http.ResponseWriter, r *http.Request) {
		require.NotEmpty(t, r.Header.Get("X-Request-Id"))

		// return a 204 No Content response if we don't receive the JWT header
		if r.Header.Get(secret.RequestHeader) == "" {
			w.WriteHeader(204)
			return
		}

		w.Header().Set("Content-Type", api.ResponseContentType)

		logEntry := log.WithFields(log.Fields{
			"method": r.Method,
			"url":    r.URL,
		})
		logEntryWithCode := logEntry.WithField("code", code)

		if params != nil {
			currentParams := r.URL.Query()
			for key := range params {
				if currentParams.Get(key) != params.Get(key) {
					logEntry.Info("UPSTREAM", "DENY", "invalid auth server params")
					w.WriteHeader(http.StatusForbidden)
					return
				}
			}
		}

		// Write pure string
		if data, ok := body.(string); ok {
			logEntryWithCode.Info("UPSTREAM")

			w.WriteHeader(code)
			fmt.Fprint(w, data)
			return
		}

		// Write json string
		data, err := json.Marshal(body)
		if err != nil {
			logEntry.WithError(err).Error("UPSTREAM")

			w.WriteHeader(503)
			fmt.Fprint(w, err)
			return
		}

		logEntryWithCode.Info("UPSTREAM")

		w.WriteHeader(code)
		w.Write(data)
	})
}

func newUpstreamConfig(authBackend string) *config.Config {
	return &config.Config{
		Version:            "123",
		DocumentRoot:       testDocumentRoot,
		Backend:            helper.URLMustParse(authBackend),
		ImageResizerConfig: config.DefaultImageResizerConfig,
	}
}

func startWorkhorseServer(authBackend string) *httptest.Server {
	return startWorkhorseServerWithConfig(newUpstreamConfig(authBackend))
}

func startWorkhorseServerWithConfig(cfg *config.Config) *httptest.Server {
	testhelper.ConfigureSecret()
	u := upstream.NewUpstream(*cfg, logrus.StandardLogger())

	return httptest.NewServer(u)
}

func runOrFail(t *testing.T, cmd *exec.Cmd) {
	out, err := cmd.CombinedOutput()
	t.Logf("%s", out)
	require.NoError(t, err)
}

func gitOkBody(t *testing.T) *api.Response {
	return &api.Response{
		GL_ID:       "user-123",
		GL_USERNAME: "username",
		Repository: gitalypb.Repository{
			StorageName:  "default",
			RelativePath: "foo/bar.git",
		},
	}
}

func httpGet(t *testing.T, url string, headers map[string]string) (*http.Response, string) {
	req, err := http.NewRequest("GET", url, nil)
	require.NoError(t, err)

	for k, v := range headers {
		req.Header.Set(k, v)
	}

	resp, err := http.DefaultClient.Do(req)
	require.NoError(t, err)
	defer resp.Body.Close()

	b, err := ioutil.ReadAll(resp.Body)
	require.NoError(t, err)

	return resp, string(b)
}

func httpPost(t *testing.T, url string, headers map[string]string, reqBody io.Reader) *http.Response {
	req, err := http.NewRequest("POST", url, reqBody)
	require.NoError(t, err)

	for k, v := range headers {
		req.Header.Set(k, v)
	}

	resp, err := http.DefaultClient.Do(req)
	require.NoError(t, err)

	return resp
}

func requireNginxResponseBuffering(t *testing.T, expected string, resp *http.Response, msgAndArgs ...interface{}) {
	actual := resp.Header.Get(helper.NginxResponseBufferHeader)
	require.Equal(t, expected, actual, msgAndArgs...)
}

// TestHealthChecksNoStaticHTML verifies that health endpoints pass errors through and don't return the static html error pages
func TestHealthChecksNoStaticHTML(t *testing.T) {
	apiResponse := "API RESPONSE"
	errorPageBody := `<html>
<body>
This is a static error page for code 503
</body>
</html>
`
	require.NoError(t, setupStaticFile("503.html", errorPageBody))

	ts := testhelper.TestServerWithHandler(regexp.MustCompile(`.`), func(w http.ResponseWriter, _ *http.Request) {
		w.Header().Set("X-Gitlab-Custom-Error", "1")
		w.WriteHeader(503)
		_, err := w.Write([]byte(apiResponse))
		require.NoError(t, err)
	})
	defer ts.Close()

	ws := startWorkhorseServer(ts.URL)
	defer ws.Close()

	for _, resource := range []string{
		"/-/health",
		"/-/readiness",
		"/-/liveness",
	} {
		t.Run(resource, func(t *testing.T) {
			resp, body := httpGet(t, ws.URL+resource, nil)

			require.Equal(t, 503, resp.StatusCode, "status code")
			require.Equal(t, apiResponse, body, "response body")
			requireNginxResponseBuffering(t, "", resp, "nginx response buffering")
		})
	}
}

// TestHealthChecksUnreachable verifies that health endpoints return the correct content-type when the upstream is down
func TestHealthChecksUnreachable(t *testing.T) {
	ws := startWorkhorseServer("http://127.0.0.1:99999") // This url should point to nothing for the test to be accurate (equivalent to upstream being down)
	defer ws.Close()

	testCases := []struct {
		path         string
		content      string
		responseType string
	}{
		{path: "/-/health", content: "Bad Gateway\n", responseType: "text/plain; charset=utf-8"},
		{path: "/-/readiness", content: "{\"error\":\"Bad Gateway\",\"status\":502}\n", responseType: "application/json; charset=utf-8"},
		{path: "/-/liveness", content: "{\"error\":\"Bad Gateway\",\"status\":502}\n", responseType: "application/json; charset=utf-8"},
	}

	for _, tc := range testCases {
		t.Run(tc.path, func(t *testing.T) {
			resp, body := httpGet(t, ws.URL+tc.path, nil)

			require.Equal(t, 502, resp.StatusCode, "status code")
			require.Equal(t, tc.responseType, resp.Header.Get("Content-Type"), "content-type")
			require.Equal(t, tc.content, body, "response body")
			requireNginxResponseBuffering(t, "", resp, "nginx response buffering")
		})
	}
}
