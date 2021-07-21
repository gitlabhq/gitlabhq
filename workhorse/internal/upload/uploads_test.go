package upload

import (
	"bytes"
	"context"
	"fmt"
	"io/ioutil"
	"mime/multipart"
	"net/http"
	"net/http/httptest"
	"os"
	"regexp"
	"strconv"
	"strings"
	"testing"
	"time"

	"github.com/stretchr/testify/require"

	"gitlab.com/gitlab-org/gitlab/workhorse/internal/api"
	"gitlab.com/gitlab-org/gitlab/workhorse/internal/filestore"
	"gitlab.com/gitlab-org/gitlab/workhorse/internal/helper"
	"gitlab.com/gitlab-org/gitlab/workhorse/internal/objectstore/test"
	"gitlab.com/gitlab-org/gitlab/workhorse/internal/proxy"
	"gitlab.com/gitlab-org/gitlab/workhorse/internal/testhelper"
	"gitlab.com/gitlab-org/gitlab/workhorse/internal/upstream/roundtripper"
)

var nilHandler = http.HandlerFunc(func(http.ResponseWriter, *http.Request) {})

type testFormProcessor struct{}

func (a *testFormProcessor) ProcessFile(ctx context.Context, formName string, file *filestore.FileHandler, writer *multipart.Writer) error {
	return nil
}

func (a *testFormProcessor) ProcessField(ctx context.Context, formName string, writer *multipart.Writer) error {
	if formName != "token" && !strings.HasPrefix(formName, "file.") && !strings.HasPrefix(formName, "other.") {
		return fmt.Errorf("illegal field: %v", formName)
	}
	return nil
}

func (a *testFormProcessor) Finalize(ctx context.Context) error {
	return nil
}

func (a *testFormProcessor) Name() string {
	return ""
}

func TestUploadTempPathRequirement(t *testing.T) {
	apiResponse := &api.Response{}
	preparer := &DefaultPreparer{}
	_, _, err := preparer.Prepare(apiResponse)
	require.Error(t, err)
}

func TestUploadHandlerForwardingRawData(t *testing.T) {
	ts := testhelper.TestServerWithHandler(regexp.MustCompile(`/url/path\z`), func(w http.ResponseWriter, r *http.Request) {
		require.Equal(t, "PATCH", r.Method, "method")

		body, err := ioutil.ReadAll(r.Body)
		require.NoError(t, err)
		require.Equal(t, "REQUEST", string(body), "request body")

		w.WriteHeader(202)
		fmt.Fprint(w, "RESPONSE")
	})
	defer ts.Close()

	httpRequest, err := http.NewRequest("PATCH", ts.URL+"/url/path", bytes.NewBufferString("REQUEST"))
	require.NoError(t, err)

	tempPath, err := ioutil.TempDir("", "uploads")
	require.NoError(t, err)
	defer os.RemoveAll(tempPath)

	response := httptest.NewRecorder()

	handler := newProxy(ts.URL)
	apiResponse := &api.Response{TempPath: tempPath}
	preparer := &DefaultPreparer{}
	opts, _, err := preparer.Prepare(apiResponse)
	require.NoError(t, err)

	HandleFileUploads(response, httpRequest, handler, apiResponse, nil, opts)

	require.Equal(t, 202, response.Code)
	require.Equal(t, "RESPONSE", response.Body.String(), "response body")
}

func TestUploadHandlerRewritingMultiPartData(t *testing.T) {
	var filePath string

	tempPath, err := ioutil.TempDir("", "uploads")
	require.NoError(t, err)
	defer os.RemoveAll(tempPath)

	ts := testhelper.TestServerWithHandler(regexp.MustCompile(`/url/path\z`), func(w http.ResponseWriter, r *http.Request) {
		require.Equal(t, "PUT", r.Method, "method")
		require.NoError(t, r.ParseMultipartForm(100000))

		require.Empty(t, r.MultipartForm.File, "Expected to not receive any files")
		require.Equal(t, "test", r.FormValue("token"), "Expected to receive token")
		require.Equal(t, "my.file", r.FormValue("file.name"), "Expected to receive a filename")

		filePath = r.FormValue("file.path")
		require.True(t, strings.HasPrefix(filePath, tempPath), "Expected to the file to be in tempPath")

		require.Empty(t, r.FormValue("file.remote_url"), "Expected to receive empty remote_url")
		require.Empty(t, r.FormValue("file.remote_id"), "Expected to receive empty remote_id")
		require.Equal(t, "4", r.FormValue("file.size"), "Expected to receive the file size")

		hashes := map[string]string{
			"md5":    "098f6bcd4621d373cade4e832627b4f6",
			"sha1":   "a94a8fe5ccb19ba61c4c0873d391e987982fbbd3",
			"sha256": "9f86d081884c7d659a2feaa0c55ad015a3bf4f1b2b0b822cd15d6c15b0f00a08",
			"sha512": "ee26b0dd4af7e749aa1a8ee3c10ae9923f618980772e473f8819a5d4940e0db27ac185f8a0e1d5f84f88bc887fd67b143732c304cc5fa9ad8e6f57f50028a8ff",
		}

		for algo, hash := range hashes {
			require.Equal(t, hash, r.FormValue("file."+algo), "file hash %s", algo)
		}

		require.Len(t, r.MultipartForm.Value, 11, "multipart form values")

		w.WriteHeader(202)
		fmt.Fprint(w, "RESPONSE")
	})

	var buffer bytes.Buffer

	writer := multipart.NewWriter(&buffer)
	writer.WriteField("token", "test")
	file, err := writer.CreateFormFile("file", "my.file")
	require.NoError(t, err)
	fmt.Fprint(file, "test")
	writer.Close()

	httpRequest, err := http.NewRequest("PUT", ts.URL+"/url/path", nil)
	require.NoError(t, err)

	ctx, cancel := context.WithCancel(context.Background())
	httpRequest = httpRequest.WithContext(ctx)
	httpRequest.Body = ioutil.NopCloser(&buffer)
	httpRequest.ContentLength = int64(buffer.Len())
	httpRequest.Header.Set("Content-Type", writer.FormDataContentType())
	response := httptest.NewRecorder()

	handler := newProxy(ts.URL)

	apiResponse := &api.Response{TempPath: tempPath}
	preparer := &DefaultPreparer{}
	opts, _, err := preparer.Prepare(apiResponse)
	require.NoError(t, err)

	HandleFileUploads(response, httpRequest, handler, apiResponse, &testFormProcessor{}, opts)
	require.Equal(t, 202, response.Code)

	cancel() // this will trigger an async cleanup
	waitUntilDeleted(t, filePath)
}

func TestUploadHandlerDetectingInjectedMultiPartData(t *testing.T) {
	var filePath string

	tempPath, err := ioutil.TempDir("", "uploads")
	require.NoError(t, err)
	defer os.RemoveAll(tempPath)

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
				require.Equal(t, "PUT", r.Method, "method")

				w.WriteHeader(202)
				fmt.Fprint(w, "RESPONSE")
			})

			var buffer bytes.Buffer

			writer := multipart.NewWriter(&buffer)
			file, err := writer.CreateFormFile("file", "my.file")
			require.NoError(t, err)
			fmt.Fprint(file, "test")

			writer.WriteField(test.field, "value")
			writer.Close()

			httpRequest, err := http.NewRequest("PUT", ts.URL+"/url/path", &buffer)
			require.NoError(t, err)

			ctx, cancel := context.WithCancel(context.Background())
			httpRequest = httpRequest.WithContext(ctx)
			httpRequest.Header.Set("Content-Type", writer.FormDataContentType())
			response := httptest.NewRecorder()

			handler := newProxy(ts.URL)
			apiResponse := &api.Response{TempPath: tempPath}
			preparer := &DefaultPreparer{}
			opts, _, err := preparer.Prepare(apiResponse)
			require.NoError(t, err)

			HandleFileUploads(response, httpRequest, handler, apiResponse, &testFormProcessor{}, opts)
			require.Equal(t, test.response, response.Code)

			cancel() // this will trigger an async cleanup
			waitUntilDeleted(t, filePath)
		})
	}
}

func TestUploadProcessingField(t *testing.T) {
	tempPath, err := ioutil.TempDir("", "uploads")
	require.NoError(t, err)
	defer os.RemoveAll(tempPath)

	var buffer bytes.Buffer

	writer := multipart.NewWriter(&buffer)
	writer.WriteField("token2", "test")
	writer.Close()

	httpRequest, err := http.NewRequest("PUT", "/url/path", &buffer)
	require.NoError(t, err)
	httpRequest.Header.Set("Content-Type", writer.FormDataContentType())

	response := httptest.NewRecorder()
	apiResponse := &api.Response{TempPath: tempPath}
	preparer := &DefaultPreparer{}
	opts, _, err := preparer.Prepare(apiResponse)
	require.NoError(t, err)

	HandleFileUploads(response, httpRequest, nilHandler, apiResponse, &testFormProcessor{}, opts)

	require.Equal(t, 500, response.Code)
}

func TestUploadProcessingFile(t *testing.T) {
	tempPath, err := ioutil.TempDir("", "uploads")
	require.NoError(t, err)
	defer os.RemoveAll(tempPath)

	_, testServer := test.StartObjectStore()
	defer testServer.Close()

	storeUrl := testServer.URL + test.ObjectPath

	tests := []struct {
		name    string
		preauth api.Response
	}{
		{
			name:    "FileStore Upload",
			preauth: api.Response{TempPath: tempPath},
		},
		{
			name:    "ObjectStore Upload",
			preauth: api.Response{RemoteObject: api.RemoteObject{StoreURL: storeUrl}},
		},
		{
			name: "ObjectStore and FileStore Upload",
			preauth: api.Response{
				TempPath:     tempPath,
				RemoteObject: api.RemoteObject{StoreURL: storeUrl},
			},
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

			httpRequest, err := http.NewRequest("PUT", "/url/path", &buffer)
			require.NoError(t, err)
			httpRequest.Header.Set("Content-Type", writer.FormDataContentType())

			response := httptest.NewRecorder()
			apiResponse := &api.Response{TempPath: tempPath}
			preparer := &DefaultPreparer{}
			opts, _, err := preparer.Prepare(apiResponse)
			require.NoError(t, err)

			HandleFileUploads(response, httpRequest, nilHandler, apiResponse, &testFormProcessor{}, opts)

			require.Equal(t, 200, response.Code)
		})
	}

}

func TestInvalidFileNames(t *testing.T) {
	testhelper.ConfigureSecret()

	tempPath, err := ioutil.TempDir("", "uploads")
	require.NoError(t, err)
	defer os.RemoveAll(tempPath)

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

		httpRequest, err := http.NewRequest("POST", "/example", buffer)
		require.NoError(t, err)
		httpRequest.Header.Set("Content-Type", writer.FormDataContentType())

		response := httptest.NewRecorder()
		apiResponse := &api.Response{TempPath: tempPath}
		preparer := &DefaultPreparer{}
		opts, _, err := preparer.Prepare(apiResponse)
		require.NoError(t, err)

		HandleFileUploads(response, httpRequest, nilHandler, apiResponse, &SavedFileTracker{Request: httpRequest}, opts)
		require.Equal(t, testCase.code, response.Code)
		require.Equal(t, testCase.expectedPrefix, opts.TempFilePrefix)
	}
}

func TestUploadHandlerRemovingExif(t *testing.T) {
	content, err := ioutil.ReadFile("exif/testdata/sample_exif.jpg")
	require.NoError(t, err)

	runUploadTest(t, content, "sample_exif.jpg", 200, func(w http.ResponseWriter, r *http.Request) {
		err := r.ParseMultipartForm(100000)
		require.NoError(t, err)

		size, err := strconv.Atoi(r.FormValue("file.size"))
		require.NoError(t, err)
		require.True(t, size < len(content), "Expected the file to be smaller after removal of exif")
		require.True(t, size > 0, "Expected to receive not empty file")

		w.WriteHeader(200)
		fmt.Fprint(w, "RESPONSE")
	})
}

func TestUploadHandlerRemovingExifTiff(t *testing.T) {
	content, err := ioutil.ReadFile("exif/testdata/sample_exif.tiff")
	require.NoError(t, err)

	runUploadTest(t, content, "sample_exif.tiff", 200, func(w http.ResponseWriter, r *http.Request) {
		err := r.ParseMultipartForm(100000)
		require.NoError(t, err)

		size, err := strconv.Atoi(r.FormValue("file.size"))
		require.NoError(t, err)
		require.True(t, size < len(content), "Expected the file to be smaller after removal of exif")
		require.True(t, size > 0, "Expected to receive not empty file")

		w.WriteHeader(200)
		fmt.Fprint(w, "RESPONSE")
	})
}

func TestUploadHandlerRemovingExifInvalidContentType(t *testing.T) {
	content, err := ioutil.ReadFile("exif/testdata/sample_exif_invalid.jpg")
	require.NoError(t, err)

	runUploadTest(t, content, "sample_exif_invalid.jpg", 200, func(w http.ResponseWriter, r *http.Request) {
		err := r.ParseMultipartForm(100000)
		require.NoError(t, err)

		output, err := ioutil.ReadFile(r.FormValue("file.path"))
		require.NoError(t, err)
		require.Equal(t, content, output, "Expected the file to be same as before")

		w.WriteHeader(200)
		fmt.Fprint(w, "RESPONSE")
	})
}

func TestUploadHandlerRemovingExifCorruptedFile(t *testing.T) {
	content, err := ioutil.ReadFile("exif/testdata/sample_exif_corrupted.jpg")
	require.NoError(t, err)

	runUploadTest(t, content, "sample_exif_corrupted.jpg", 422, func(w http.ResponseWriter, r *http.Request) {
		err := r.ParseMultipartForm(100000)
		require.Error(t, err)
	})
}

func runUploadTest(t *testing.T, image []byte, filename string, httpCode int, tsHandler func(http.ResponseWriter, *http.Request)) {
	tempPath, err := ioutil.TempDir("", "uploads")
	require.NoError(t, err)
	defer os.RemoveAll(tempPath)

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

	httpRequest, err := http.NewRequest("POST", ts.URL+"/url/path", &buffer)
	require.NoError(t, err)

	ctx, cancel := context.WithCancel(context.Background())
	defer cancel()

	httpRequest = httpRequest.WithContext(ctx)
	httpRequest.ContentLength = int64(buffer.Len())
	httpRequest.Header.Set("Content-Type", writer.FormDataContentType())
	response := httptest.NewRecorder()

	handler := newProxy(ts.URL)
	apiResponse := &api.Response{TempPath: tempPath}
	preparer := &DefaultPreparer{}
	opts, _, err := preparer.Prepare(apiResponse)
	require.NoError(t, err)

	HandleFileUploads(response, httpRequest, handler, apiResponse, &testFormProcessor{}, opts)
	require.Equal(t, httpCode, response.Code)
}

func newProxy(url string) *proxy.Proxy {
	parsedURL := helper.URLMustParse(url)
	return proxy.NewProxy(parsedURL, "123", roundtripper.NewTestBackendRoundTripper(parsedURL))
}

func waitUntilDeleted(t *testing.T, path string) {
	var err error

	// Poll because the file removal is async
	for i := 0; i < 100; i++ {
		_, err = os.Stat(path)
		if err != nil {
			break
		}
		time.Sleep(100 * time.Millisecond)
	}

	require.True(t, os.IsNotExist(err), "expected the file to be deleted")
}
