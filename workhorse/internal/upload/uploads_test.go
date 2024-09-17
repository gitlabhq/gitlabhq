package upload

import (
	"bufio"
	"bytes"
	"context"
	"fmt"
	"io"
	"mime/multipart"
	"net/http"
	"net/http/httptest"
	"net/textproto"
	"os"
	"path"
	"regexp"
	"strconv"
	"strings"
	"testing"
	"time"

	"github.com/stretchr/testify/assert"
	"github.com/stretchr/testify/require"

	"gitlab.com/gitlab-org/gitlab/workhorse/internal/api"
	"gitlab.com/gitlab-org/gitlab/workhorse/internal/config"
	"gitlab.com/gitlab-org/gitlab/workhorse/internal/helper"
	"gitlab.com/gitlab-org/gitlab/workhorse/internal/proxy"
	"gitlab.com/gitlab-org/gitlab/workhorse/internal/testhelper"
	"gitlab.com/gitlab-org/gitlab/workhorse/internal/upload/destination/objectstore/test"
	"gitlab.com/gitlab-org/gitlab/workhorse/internal/upstream/roundtripper"
)

var nilHandler = http.HandlerFunc(func(http.ResponseWriter, *http.Request) {})

const (
	urlPath = "/url/path"
)

type testFormProcessor struct{ SavedFileTracker }

func (a *testFormProcessor) ProcessField(_ context.Context, formName string, _ *multipart.Writer) error {
	if formName != "token" && !strings.HasPrefix(formName, "file.") && !strings.HasPrefix(formName, "other.") {
		return fmt.Errorf("illegal field: %v", formName)
	}
	return nil
}

func (a *testFormProcessor) Finalize(_ context.Context) error {
	return nil
}

func TestUploadTempPathRequirement(t *testing.T) {
	apiResponse := &api.Response{}
	preparer := &DefaultPreparer{}
	_, err := preparer.Prepare(apiResponse)
	require.Error(t, err)
}

func TestUploadHandlerForwardingRawData(t *testing.T) {
	ts := testhelper.TestServerWithHandler(regexp.MustCompile(`/url/path\z`), func(w http.ResponseWriter, r *http.Request) {
		assert.Equal(t, "PATCH", r.Method, "method")

		body, err := io.ReadAll(r.Body)
		assert.NoError(t, err)
		assert.Equal(t, "REQUEST", string(body), "request body")

		w.WriteHeader(202)
		fmt.Fprint(w, "RESPONSE")
	})
	defer ts.Close()

	ctx, cancel := context.WithCancel(context.Background())
	defer cancel()

	httpRequest, err := http.NewRequestWithContext(ctx, "PATCH", ts.URL+urlPath, bytes.NewBufferString("REQUEST"))
	require.NoError(t, err)

	tempPath := t.TempDir()
	response := httptest.NewRecorder()

	handler := newProxy(ts.URL)
	fa := &eagerAuthorizer{&api.Response{TempPath: tempPath}}
	preparer := &DefaultPreparer{}

	interceptMultipartFiles(response, httpRequest, handler, nil, fa, preparer, config.NewDefaultConfig())

	require.Equal(t, 202, response.Code)
	require.Equal(t, "RESPONSE", response.Body.String(), "response body")
}

func TestUploadHandlerRewritingMultiPartData(t *testing.T) {
	var filePath string
	tempPath := t.TempDir()

	ts := testhelper.TestServerWithHandler(regexp.MustCompile(`/url/path\z`), func(w http.ResponseWriter, r *http.Request) {
		assert.Equal(t, "PUT", r.Method, "method")
		assert.NoError(t, r.ParseMultipartForm(100000))

		assert.Empty(t, r.MultipartForm.File, "Expected to not receive any files")
		assert.Equal(t, "test", r.FormValue("token"), "Expected to receive token")
		assert.Equal(t, "my.file", r.FormValue("file.name"), "Expected to receive a filename")

		filePath = r.FormValue("file.path")
		assert.True(t, strings.HasPrefix(filePath, tempPath), "Expected to the file to be in tempPath")

		assert.Empty(t, r.FormValue("file.remote_url"), "Expected to receive empty remote_url")
		assert.Empty(t, r.FormValue("file.remote_id"), "Expected to receive empty remote_id")
		assert.Equal(t, "4", r.FormValue("file.size"), "Expected to receive the file size")

		hashes := map[string]string{
			"sha1":   "a94a8fe5ccb19ba61c4c0873d391e987982fbbd3",
			"sha256": "9f86d081884c7d659a2feaa0c55ad015a3bf4f1b2b0b822cd15d6c15b0f00a08",
			"sha512": "ee26b0dd4af7e749aa1a8ee3c10ae9923f618980772e473f8819a5d4940e0db27ac185f8a0e1d5f84f88bc887fd67b143732c304cc5fa9ad8e6f57f50028a8ff",
		}

		for algo, hash := range hashes {
			assert.Equal(t, hash, r.FormValue("file."+algo), "file hash %s", algo)
		}

		expectedLen := 12

		assert.Equal(t, "098f6bcd4621d373cade4e832627b4f6", r.FormValue("file.md5"), "file hash md5")
		assert.Len(t, r.MultipartForm.Value, expectedLen, "multipart form values")

		w.WriteHeader(202)
		fmt.Fprint(w, "RESPONSE")
	})
	defer ts.Close()

	var buffer bytes.Buffer

	writer := multipart.NewWriter(&buffer)
	writer.WriteField("token", "test")
	file, err := writer.CreateFormFile("file", "my.file")
	require.NoError(t, err)
	fmt.Fprint(file, "test")
	writer.Close()

	ctx, cancel := context.WithCancel(context.Background())
	httpRequest, err := http.NewRequestWithContext(ctx, "PUT", ts.URL+urlPath, nil)
	require.NoError(t, err)

	httpRequest.Body = io.NopCloser(&buffer)
	httpRequest.ContentLength = int64(buffer.Len())
	httpRequest.Header.Set("Content-Type", writer.FormDataContentType())
	response := httptest.NewRecorder()

	handler := newProxy(ts.URL)

	fa := &eagerAuthorizer{&api.Response{TempPath: tempPath}}
	preparer := &DefaultPreparer{}

	interceptMultipartFiles(response, httpRequest, handler, &testFormProcessor{}, fa, preparer, config.NewDefaultConfig())
	require.Equal(t, 202, response.Code)

	cancel() // this will trigger an async cleanup
	waitUntilDeleted(t, filePath)
}

func TestUploadHandlerDetectingInjectedMultiPartData(t *testing.T) {
	var filePath string

	tests := []struct {
		name     string
		field    string
		response int
	}{
		{
			name:     "injected file.path",
			field:    "file.path",
			response: 400,
		},
		{
			name:     "injected file.remote_id",
			field:    "file.remote_id",
			response: 400,
		},
		{
			name:     "field with other prefix",
			field:    "other.path",
			response: 202,
		},
	}

	for _, test := range tests {
		t.Run(test.name, func(t *testing.T) {
			ts := testhelper.TestServerWithHandler(regexp.MustCompile(`/url/path\z`), func(w http.ResponseWriter, r *http.Request) {
				assert.Equal(t, "PUT", r.Method, "method")

				w.WriteHeader(202)
				fmt.Fprint(w, "RESPONSE")
			})
			defer ts.Close()

			var buffer bytes.Buffer

			writer := multipart.NewWriter(&buffer)
			file, err := writer.CreateFormFile("file", "my.file")
			require.NoError(t, err)
			fmt.Fprint(file, "test")

			writer.WriteField(test.field, "value")
			writer.Close()

			ctx, cancel := context.WithCancel(context.Background())
			defer cancel()

			httpRequest, err := http.NewRequestWithContext(ctx, "PUT", ts.URL+urlPath, &buffer)
			require.NoError(t, err)

			httpRequest.Header.Set("Content-Type", writer.FormDataContentType())
			response := httptest.NewRecorder()

			handler := newProxy(ts.URL)

			testInterceptMultipartFiles(t, response, httpRequest, handler, &testFormProcessor{})
			require.Equal(t, test.response, response.Code)

			waitUntilDeleted(t, filePath)
		})
	}
}

func TestUploadProcessingField(t *testing.T) {
	var buffer bytes.Buffer

	writer := multipart.NewWriter(&buffer)
	writer.WriteField("token2", "test")
	writer.Close()

	ctx, cancel := context.WithCancel(context.Background())
	defer cancel()

	httpRequest, err := http.NewRequestWithContext(ctx, "PUT", urlPath, &buffer)
	require.NoError(t, err)
	httpRequest.Header.Set("Content-Type", writer.FormDataContentType())

	response := httptest.NewRecorder()

	testInterceptMultipartFiles(t, response, httpRequest, nilHandler, &testFormProcessor{})

	require.Equal(t, 500, response.Code)
}

func TestUploadingMultipleFiles(t *testing.T) {
	testhelper.ConfigureSecret()

	httpRequest, response := setupMultipleFiles(t)

	ctx, cancel := context.WithCancel(context.Background())
	httpRequest = httpRequest.WithContext(ctx)
	defer cancel()

	testInterceptMultipartFiles(t, response, httpRequest, nilHandler, &testFormProcessor{})

	require.Equal(t, 400, response.Code)
	require.Equal(t, "upload request contains more than 10 files\n", response.Body.String())
}

func TestUploadProcessingFile(t *testing.T) {
	testhelper.ConfigureSecret()
	tempPath := t.TempDir()

	objectStore, testServer := test.StartObjectStore()
	defer testServer.Close()

	storeURL := testServer.URL + test.ObjectPath

	tests := []struct {
		name    string
		preauth *api.Response
		content func(t *testing.T) []byte
	}{
		{
			name:    "FileStore Upload",
			preauth: &api.Response{TempPath: tempPath},
			content: func(t *testing.T) []byte {
				entries, err := os.ReadDir(tempPath)
				require.NoError(t, err)
				require.Len(t, entries, 1)
				content, err := os.ReadFile(path.Join(tempPath, entries[0].Name()))
				require.NoError(t, err)
				return content
			},
		},
		{
			name:    "ObjectStore Upload",
			preauth: &api.Response{RemoteObject: api.RemoteObject{StoreURL: storeURL, ID: "123"}},
			content: func(*testing.T) []byte { return objectStore.GetObject(test.ObjectPath) },
		},
	}

	for _, test := range tests {
		t.Run(test.name, func(t *testing.T) {
			var buffer bytes.Buffer
			writer := multipart.NewWriter(&buffer)
			file, err := writer.CreateFormFile("file", "my.file")
			require.NoError(t, err)
			fmt.Fprint(file, "test")
			writer.Close()

			ctx, cancel := context.WithCancel(context.Background())
			defer cancel()

			httpRequest, err := http.NewRequestWithContext(ctx, "PUT", urlPath, &buffer)
			require.NoError(t, err)
			httpRequest.Header.Set("Content-Type", writer.FormDataContentType())

			response := httptest.NewRecorder()
			fa := &eagerAuthorizer{test.preauth}
			preparer := &DefaultPreparer{}

			interceptMultipartFiles(response, httpRequest, nilHandler, &testFormProcessor{}, fa, preparer, config.NewDefaultConfig())

			require.Equal(t, 200, response.Code)
			require.Equal(t, "test", string(test.content(t)))
		})
	}
}

func TestInvalidFileNames(t *testing.T) {
	testhelper.ConfigureSecret()

	for _, testCase := range []struct {
		filename       string
		code           int
		expectedPrefix string
	}{
		{"foobar", 200, "foobar"}, // sanity check for test setup below
		{"foo/bar", 200, "bar"},
		{"foo/bar/baz", 200, "baz"},
		{"/../../foobar", 200, "foobar"},
		{".", 500, ""},
		{"..", 500, ""},
		{"./", 500, ""},
	} {
		buffer := &bytes.Buffer{}

		writer := multipart.NewWriter(buffer)
		file, err := writer.CreateFormFile("file", testCase.filename)
		require.NoError(t, err)
		fmt.Fprint(file, "test")
		writer.Close()

		ctx, cancel := context.WithCancel(context.Background())
		defer cancel()

		httpRequest, err := http.NewRequestWithContext(ctx, "POST", "/example", buffer)
		require.NoError(t, err)
		httpRequest.Header.Set("Content-Type", writer.FormDataContentType())

		response := httptest.NewRecorder()
		testInterceptMultipartFiles(t, response, httpRequest, nilHandler, &SavedFileTracker{Request: httpRequest})
		require.Equal(t, testCase.code, response.Code)
	}
}

func TestIncompleteMultipartData(t *testing.T) {
	testhelper.ConfigureSecret()

	buffer := &bytes.Buffer{}

	writer := multipart.NewWriter(buffer)
	file, err := writer.CreateFormFile("file", "somefile.txt")
	require.NoError(t, err)
	fmt.Fprint(file, "test")
	writer.Close()

	// Truncate the buffer to simulate an incomplete multipart request
	truncatedBuffer := buffer.Bytes()[:buffer.Len()-1]
	customReader := bytes.NewReader(truncatedBuffer)

	ctx, cancel := context.WithCancel(context.Background())
	defer cancel()

	httpRequest, err := http.NewRequestWithContext(ctx, "POST", "/example", customReader)
	require.NoError(t, err)
	httpRequest.Header.Set("Content-Type", writer.FormDataContentType())

	response := httptest.NewRecorder()
	testInterceptMultipartFiles(t, response, httpRequest, nilHandler, &SavedFileTracker{Request: httpRequest})
	require.Equal(t, 400, response.Code)
}

func TestBadMultipartHeader(t *testing.T) {
	ctx, cancel := context.WithCancel(context.Background())
	defer cancel()

	httpRequest, err := http.NewRequestWithContext(ctx, "POST", "/example", bytes.NewReader(nil))
	require.NoError(t, err)

	// Invalid header: missing boundary
	httpRequest.Header.Set("Content-Type", "multipart/form-data")

	response := httptest.NewRecorder()
	testInterceptMultipartFiles(t, response, httpRequest, nilHandler, &SavedFileTracker{Request: httpRequest})
	require.Equal(t, 400, response.Code)
}

func TestUnauthorizedMultipartHeader(t *testing.T) {
	testhelper.ConfigureSecret()

	httpRequest, response := setupMultipleFiles(t)

	ts := httptest.NewServer(http.HandlerFunc(func(w http.ResponseWriter, _ *http.Request) {
		w.WriteHeader(http.StatusUnauthorized)
	}))
	defer ts.Close()

	api := api.NewAPI(helper.URLMustParse(ts.URL), "123", http.DefaultTransport)
	interceptMultipartFiles(response, httpRequest, nilHandler, &testFormProcessor{}, &apiAuthorizer{api}, &DefaultPreparer{}, config.NewDefaultConfig())

	require.Equal(t, 401, response.Code)
	require.Equal(t, "401 Unauthorized\n", response.Body.String())
}

func TestMalformedMimeHeader(t *testing.T) {
	testhelper.ConfigureSecret()

	h := make(textproto.MIMEHeader)
	h.Set("Invalid Header Line\r\nContent-Type", "text/plain\r\n\r\n")

	buffer := &bytes.Buffer{}
	writer := multipart.NewWriter(buffer)
	file, err := writer.CreatePart(h)
	require.NoError(t, err)
	fmt.Fprint(file, "test")
	writer.Close()

	ctx, cancel := context.WithCancel(context.Background())
	defer cancel()

	httpRequest, err := http.NewRequestWithContext(ctx, "POST", "/example", buffer)
	require.NoError(t, err)
	httpRequest.Header.Set("Content-Type", writer.FormDataContentType())

	response := httptest.NewRecorder()
	testInterceptMultipartFiles(t, response, httpRequest, nilHandler, &SavedFileTracker{Request: httpRequest})
	require.Equal(t, 400, response.Code)
}

func TestContentDispositionRewrite(t *testing.T) {
	testhelper.ConfigureSecret()

	tests := []struct {
		desc            string
		header          string
		code            int
		sanitizedHeader string
	}{
		{
			desc:            "with name",
			header:          `form-data; name="foo"`,
			code:            200,
			sanitizedHeader: `form-data; name=foo`,
		},
		{
			desc:            "with name and name*",
			header:          `form-data; name="foo"; name*=UTF-8''bar`,
			code:            200,
			sanitizedHeader: `form-data; name=bar`,
		},
		{
			desc:            "with name and invalid name*",
			header:          `form-data; name="foo"; name*=UTF-16''bar`,
			code:            200,
			sanitizedHeader: `form-data; name=foo`,
		},
	}

	for _, testCase := range tests {
		t.Run(testCase.desc, func(t *testing.T) {
			h := make(textproto.MIMEHeader)
			h.Set("Content-Disposition", testCase.header)
			h.Set("Content-Type", "application/octet-stream")

			buffer := &bytes.Buffer{}
			writer := multipart.NewWriter(buffer)
			file, err := writer.CreatePart(h)
			require.NoError(t, err)
			fmt.Fprint(file, "test")
			writer.Close()

			httpRequest := httptest.NewRequest("POST", "/example", buffer)
			httpRequest.Header.Set("Content-Type", writer.FormDataContentType())

			var upstreamRequestBuffer bytes.Buffer
			customHandler := http.HandlerFunc(func(_ http.ResponseWriter, r *http.Request) {
				r.Write(&upstreamRequestBuffer)
			})

			response := httptest.NewRecorder()
			testInterceptMultipartFiles(t, response, httpRequest, customHandler, &SavedFileTracker{Request: httpRequest})

			upstreamRequest, err := http.ReadRequest(bufio.NewReader(&upstreamRequestBuffer))
			require.NoError(t, err)

			reader, err := upstreamRequest.MultipartReader()
			require.NoError(t, err)

			for i := 0; ; i++ {
				p, err := reader.NextPart()
				if err == io.EOF {
					require.Equal(t, 1, i)
					break
				}
				require.NoError(t, err)
				require.Equal(t, testCase.sanitizedHeader, p.Header.Get("Content-Disposition"))
			}

			require.Equal(t, testCase.code, response.Code)
		})
	}
}

func TestUploadHandlerRemovingExif(t *testing.T) {
	content, err := os.ReadFile("exif/testdata/sample_exif.jpg")
	require.NoError(t, err)

	runUploadTest(t, content, "sample_exif.jpg", 200, func(w http.ResponseWriter, r *http.Request) {
		err := r.ParseMultipartForm(100000)
		assert.NoError(t, err)

		size, err := strconv.Atoi(r.FormValue("file.size"))
		assert.NoError(t, err)
		assert.Less(t, size, len(content), "Expected the file to be smaller after removal of exif")
		assert.Positive(t, size, 0, "Expected to receive non-empty file")

		w.WriteHeader(200)
		fmt.Fprint(w, "RESPONSE")
	})
}

func TestUploadHandlerRemovingExifTiff(t *testing.T) {
	content, err := os.ReadFile("exif/testdata/sample_exif.tiff")
	require.NoError(t, err)

	runUploadTest(t, content, "sample_exif.tiff", 200, func(w http.ResponseWriter, r *http.Request) {
		err := r.ParseMultipartForm(100000)
		assert.NoError(t, err)

		size, err := strconv.Atoi(r.FormValue("file.size"))
		assert.NoError(t, err)
		assert.Less(t, size, len(content), "Expected the file to be smaller after removal of exif")
		assert.Positive(t, size, 0, "Expected to receive not empty file")

		w.WriteHeader(200)
		fmt.Fprint(w, "RESPONSE")
	})
}

func TestUploadHandlerRemovingExifInvalidContentType(t *testing.T) {
	content, err := os.ReadFile("exif/testdata/sample_exif_invalid.jpg")
	require.NoError(t, err)

	runUploadTest(t, content, "sample_exif_invalid.jpg", 200, func(w http.ResponseWriter, r *http.Request) {
		err := r.ParseMultipartForm(100000)
		assert.NoError(t, err)

		output, err := os.ReadFile(r.FormValue("file.path"))
		assert.NoError(t, err)
		assert.Equal(t, content, output, "Expected the file to be same as before")

		w.WriteHeader(200)
		fmt.Fprint(w, "RESPONSE")
	})
}

func TestUploadHandlerRemovingExifCorruptedFile(t *testing.T) {
	content, err := os.ReadFile("exif/testdata/sample_exif_corrupted.jpg")
	require.NoError(t, err)

	runUploadTest(t, content, "sample_exif_corrupted.jpg", 422, func(_ http.ResponseWriter, r *http.Request) {
		err := r.ParseMultipartForm(100000)
		assert.Error(t, err)
	})
}

func runUploadTest(t *testing.T, image []byte, filename string, httpCode int, tsHandler func(http.ResponseWriter, *http.Request)) {
	var buffer bytes.Buffer

	writer := multipart.NewWriter(&buffer)
	file, err := writer.CreateFormFile("file", filename)
	require.NoError(t, err)

	_, err = file.Write(image)
	require.NoError(t, err)

	err = writer.Close()
	require.NoError(t, err)

	ts := testhelper.TestServerWithHandler(regexp.MustCompile(`/url/path\z`), tsHandler)
	defer ts.Close()

	ctx, cancel := context.WithCancel(context.Background())
	defer cancel()

	httpRequest, err := http.NewRequestWithContext(ctx, "POST", ts.URL+urlPath, &buffer)
	require.NoError(t, err)

	httpRequest = httpRequest.WithContext(ctx)
	httpRequest.ContentLength = int64(buffer.Len())
	httpRequest.Header.Set("Content-Type", writer.FormDataContentType())
	response := httptest.NewRecorder()

	handler := newProxy(ts.URL)

	testInterceptMultipartFiles(t, response, httpRequest, handler, &testFormProcessor{})
	require.Equal(t, httpCode, response.Code)
}

func newProxy(url string) *proxy.Proxy {
	parsedURL := helper.URLMustParse(url)
	return proxy.NewProxy(parsedURL, "123", roundtripper.NewTestBackendRoundTripper(parsedURL))
}

func waitUntilDeleted(t *testing.T, path string) {
	var err error
	require.Eventually(t, func() bool {
		_, err = os.Stat(path)
		return err != nil
	}, 10*time.Second, 10*time.Millisecond)
	require.True(t, os.IsNotExist(err), "expected the file to be deleted")
}

func testInterceptMultipartFiles(t *testing.T, w http.ResponseWriter, r *http.Request, h http.Handler, filter MultipartFormProcessor) {
	t.Helper()

	fa := &eagerAuthorizer{&api.Response{TempPath: t.TempDir()}}
	preparer := &DefaultPreparer{}

	interceptMultipartFiles(w, r, h, filter, fa, preparer, config.NewDefaultConfig())
}

func setupMultipleFiles(t *testing.T) (*http.Request, *httptest.ResponseRecorder) {
	var buffer bytes.Buffer

	t.Helper()

	writer := multipart.NewWriter(&buffer)
	for i := 0; i < 11; i++ {
		_, err := writer.CreateFormFile(fmt.Sprintf("file %v", i), "my.file")
		require.NoError(t, err)
	}
	require.NoError(t, writer.Close())

	httpRequest, err := http.NewRequest("PUT", urlPath, &buffer)
	require.NoError(t, err)
	httpRequest.Header.Set("Content-Type", writer.FormDataContentType())

	return httpRequest, httptest.NewRecorder()
}
