package upload

import (
	"context"
	"fmt"
	"io"
	"net/http"
	"net/http/httptest"
	"os"
	"strconv"
	"strings"
	"testing"

	jwt "github.com/golang-jwt/jwt/v5"
	"github.com/stretchr/testify/assert"
	"github.com/stretchr/testify/require"

	"gitlab.com/gitlab-org/gitlab/workhorse/internal/api"
	"gitlab.com/gitlab-org/gitlab/workhorse/internal/testhelper"
	"gitlab.com/gitlab-org/gitlab/workhorse/internal/upload/destination"
)

const (
	fileContent = "A test file content"
	fileLen     = len(fileContent)
)

func TestRequestBody(t *testing.T) {
	testhelper.ConfigureSecret()

	body := strings.NewReader(fileContent)

	ctx, cancel := context.WithCancel(context.Background())
	defer cancel()

	resp := testUpload(ctx, &rails{}, &alwaysLocalPreparer{}, echoProxy(t, fileLen), body)
	defer resp.Body.Close()
	require.Equal(t, http.StatusOK, resp.StatusCode)

	uploadEcho, err := io.ReadAll(resp.Body)

	require.NoError(t, err, "Can't read response body")
	require.Equal(t, fileContent, string(uploadEcho))
}

func TestRequestBodyWithAPIResponse(t *testing.T) {
	testhelper.ConfigureSecret()

	body := strings.NewReader(fileContent)

	ctx, cancel := context.WithCancel(context.Background())
	defer cancel()

	resp := testUploadWithAPIResponse(ctx, &rails{}, &alwaysLocalPreparer{}, echoProxy(t, fileLen), body, &api.Response{TempPath: os.TempDir()})
	defer resp.Body.Close()
	require.Equal(t, http.StatusOK, resp.StatusCode)

	uploadEcho, err := io.ReadAll(resp.Body)

	require.NoError(t, err, "Can't read response body")
	require.Equal(t, fileContent, string(uploadEcho))
}

func TestRequestBodyCustomPreparer(t *testing.T) {
	body := strings.NewReader(fileContent)

	ctx, cancel := context.WithCancel(context.Background())
	defer cancel()

	resp := testUpload(ctx, &rails{}, &alwaysLocalPreparer{}, echoProxy(t, fileLen), body)
	defer resp.Body.Close()
	require.Equal(t, http.StatusOK, resp.StatusCode)

	uploadEcho, err := io.ReadAll(resp.Body)
	require.NoError(t, err, "Can't read response body")
	require.Equal(t, fileContent, string(uploadEcho))
}

func TestRequestBodyAuthorizationFailure(t *testing.T) {
	testNoProxyInvocation(t, http.StatusUnauthorized, &rails{unauthorized: true}, &alwaysLocalPreparer{})
}

func TestRequestBodyErrors(t *testing.T) {
	tests := []struct {
		name     string
		preparer *alwaysLocalPreparer
	}{
		{name: "Prepare failure", preparer: &alwaysLocalPreparer{prepareError: fmt.Errorf("")}},
	}

	for _, test := range tests {
		t.Run(test.name, func(t *testing.T) {
			testNoProxyInvocation(t, http.StatusInternalServerError, &rails{}, test.preparer)
		})
	}
}

func TestRequestBodyUploadFailedErrorMessage(t *testing.T) {
	testhelper.ConfigureSecret()

	tests := []struct {
		name           string
		preparer       Preparer
		expectedStatus int
		description    string
	}{
		{
			name:           "Size limit exceeded triggers RequestBody upload failed error",
			preparer:       &sizeErrorPreparer{},
			expectedStatus: http.StatusRequestEntityTooLarge,
			description:    "Should return 413 status when upload size exceeds limit",
		},
		{
			name:           "Invalid temp path triggers RequestBody upload failed error",
			preparer:       &uploadErrorPreparer{},
			expectedStatus: http.StatusInternalServerError,
			description:    "Should return 500 status when upload destination is invalid",
		},
	}

	for _, test := range tests {
		t.Run(test.name, func(t *testing.T) {
			body := strings.NewReader(fileContent)

			ctx, cancel := context.WithCancel(context.Background())
			defer cancel()

			proxy := http.HandlerFunc(func(_ http.ResponseWriter, _ *http.Request) {
				assert.Fail(t, "request should not be proxied when upload fails")
			})

			resp := testUpload(ctx, &rails{}, test.preparer, proxy, body)
			defer resp.Body.Close()

			require.Equal(t, test.expectedStatus, resp.StatusCode, test.description)

			responseBody, err := io.ReadAll(resp.Body)
			require.NoError(t, err)
			require.NotEmpty(t, responseBody, "Error response should have a body")
		})
	}
}

func testNoProxyInvocation(t *testing.T, expectedStatus int, auth api.PreAuthorizer, preparer Preparer) {
	proxy := http.HandlerFunc(func(_ http.ResponseWriter, _ *http.Request) {
		assert.Fail(t, "request proxied upstream")
	})

	ctx, cancel := context.WithCancel(context.Background())
	defer cancel()

	resp := testUpload(ctx, auth, preparer, proxy, nil)
	defer resp.Body.Close()
	require.Equal(t, expectedStatus, resp.StatusCode)
}

func testUpload(ctx context.Context, auth api.PreAuthorizer, preparer Preparer, proxy http.Handler, body io.Reader) *http.Response {
	req := httptest.NewRequest("POST", "http://example.com/upload", body).WithContext(ctx)
	w := httptest.NewRecorder()

	RequestBody(auth, proxy, preparer).ServeHTTP(w, req)

	return w.Result()
}

func testUploadWithAPIResponse(ctx context.Context, auth api.PreAuthorizer, preparer Preparer, proxy http.Handler, body io.Reader, api *api.Response) *http.Response {
	req := httptest.NewRequest("POST", "http://example.com/upload", body).WithContext(ctx)
	w := httptest.NewRecorder()

	RequestBody(auth, proxy, preparer).ServeHTTPWithAPIResponse(w, req, api)

	return w.Result()
}

func echoProxy(t *testing.T, expectedBodyLength int) http.Handler {
	return http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		err := r.ParseForm()
		assert.NoError(t, err)

		assert.Equal(t, "application/x-www-form-urlencoded", r.Header.Get("Content-Type"), "Wrong Content-Type header")

		assert.Contains(t, r.PostForm, "file.md5")
		assert.Contains(t, r.PostForm, "file.sha1")
		assert.Contains(t, r.PostForm, "file.sha256")
		assert.Contains(t, r.PostForm, "file.sha512")

		assert.Contains(t, r.PostForm, "file.path")
		assert.Contains(t, r.PostForm, "file.size")
		assert.Contains(t, r.PostForm, "file.gitlab-workhorse-upload")
		assert.Equal(t, strconv.Itoa(expectedBodyLength), r.PostFormValue("file.size"))

		token, err := jwt.ParseWithClaims(r.Header.Get(RewrittenFieldsHeader), &MultipartClaims{}, testhelper.ParseJWT)
		assert.NoError(t, err, "Wrong JWT header")

		rewrittenFields := token.Claims.(*MultipartClaims).RewrittenFields
		if len(rewrittenFields) != 1 || len(rewrittenFields["file"]) == 0 {
			t.Fatalf("Unexpected rewritten_fields value: %v", rewrittenFields)
		}

		token, jwtErr := jwt.ParseWithClaims(r.PostFormValue("file.gitlab-workhorse-upload"), &testhelper.UploadClaims{}, testhelper.ParseJWT)
		assert.NoError(t, jwtErr, "Wrong signed upload fields")

		uploadFields := token.Claims.(*testhelper.UploadClaims).Upload
		assert.Contains(t, uploadFields, "name")
		assert.Contains(t, uploadFields, "path")
		assert.Contains(t, uploadFields, "remote_url")
		assert.Contains(t, uploadFields, "remote_id")
		assert.Contains(t, uploadFields, "size")
		assert.Contains(t, uploadFields, "md5")
		assert.Contains(t, uploadFields, "sha1")
		assert.Contains(t, uploadFields, "sha256")
		assert.Contains(t, uploadFields, "sha512")

		path := r.PostFormValue("file.path")
		uploaded, err := os.Open(path)
		assert.NoError(t, err, "File not uploaded")

		// sending back the file for testing purpose
		io.Copy(w, uploaded)
	})
}

type rails struct {
	unauthorized bool
}

func (r *rails) PreAuthorizeHandler(next api.HandleFunc, _ string) http.Handler {
	if r.unauthorized {
		return http.HandlerFunc(func(w http.ResponseWriter, _ *http.Request) {
			w.WriteHeader(http.StatusUnauthorized)
		})
	}

	return http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		next(w, r, &api.Response{TempPath: os.TempDir()})
	})
}

type alwaysLocalPreparer struct {
	prepareError error
}

func (a *alwaysLocalPreparer) Prepare(_ *api.Response) (*destination.UploadOpts, error) {
	opts, err := destination.GetOpts(&api.Response{TempPath: os.TempDir()})
	if err != nil {
		return nil, err
	}

	return opts, a.prepareError
}

type sizeErrorPreparer struct{}

func (s *sizeErrorPreparer) Prepare(_ *api.Response) (*destination.UploadOpts, error) {
	opts, err := destination.GetOpts(&api.Response{TempPath: os.TempDir()})
	if err != nil {
		return nil, err
	}

	// Set a very small size limit to trigger a size error
	opts.MaximumSize = 1
	return opts, nil
}

type uploadErrorPreparer struct{}

func (u *uploadErrorPreparer) Prepare(_ *api.Response) (*destination.UploadOpts, error) {
	// Create opts that will cause upload to fail by using a device file as temp path
	// Device files like /dev/null cannot be used as directories, so mkdir will fail
	// This is more reliable than depending on filesystem permissions
	return &destination.UploadOpts{
		LocalTempPath: "/dev/null", // This will cause mkdir to fail reliably
		MaximumSize:   1024 * 1024, // 1MB
	}, nil
}
