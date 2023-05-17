package upload

import (
	"fmt"
	"io"
	"net/http"
	"net/http/httptest"
	"os"
	"strconv"
	"strings"
	"testing"

	"github.com/golang-jwt/jwt/v5"
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

	resp := testUpload(&rails{}, &alwaysLocalPreparer{}, echoProxy(t, fileLen), body)
	require.Equal(t, http.StatusOK, resp.StatusCode)

	uploadEcho, err := io.ReadAll(resp.Body)

	require.NoError(t, err, "Can't read response body")
	require.Equal(t, fileContent, string(uploadEcho))
}

func TestRequestBodyCustomPreparer(t *testing.T) {
	body := strings.NewReader(fileContent)

	resp := testUpload(&rails{}, &alwaysLocalPreparer{}, echoProxy(t, fileLen), body)
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

func testNoProxyInvocation(t *testing.T, expectedStatus int, auth PreAuthorizer, preparer Preparer) {
	proxy := http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		require.Fail(t, "request proxied upstream")
	})

	resp := testUpload(auth, preparer, proxy, nil)
	require.Equal(t, expectedStatus, resp.StatusCode)
}

func testUpload(auth PreAuthorizer, preparer Preparer, proxy http.Handler, body io.Reader) *http.Response {
	req := httptest.NewRequest("POST", "http://example.com/upload", body)
	w := httptest.NewRecorder()

	RequestBody(auth, proxy, preparer).ServeHTTP(w, req)

	return w.Result()
}

func echoProxy(t *testing.T, expectedBodyLength int) http.Handler {
	return http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		err := r.ParseForm()
		require.NoError(t, err)

		require.Equal(t, "application/x-www-form-urlencoded", r.Header.Get("Content-Type"), "Wrong Content-Type header")

		require.Contains(t, r.PostForm, "file.md5")
		require.Contains(t, r.PostForm, "file.sha1")
		require.Contains(t, r.PostForm, "file.sha256")
		require.Contains(t, r.PostForm, "file.sha512")

		require.Contains(t, r.PostForm, "file.path")
		require.Contains(t, r.PostForm, "file.size")
		require.Contains(t, r.PostForm, "file.gitlab-workhorse-upload")
		require.Equal(t, strconv.Itoa(expectedBodyLength), r.PostFormValue("file.size"))

		token, err := jwt.ParseWithClaims(r.Header.Get(RewrittenFieldsHeader), &MultipartClaims{}, testhelper.ParseJWT)
		require.NoError(t, err, "Wrong JWT header")

		rewrittenFields := token.Claims.(*MultipartClaims).RewrittenFields
		if len(rewrittenFields) != 1 || len(rewrittenFields["file"]) == 0 {
			t.Fatalf("Unexpected rewritten_fields value: %v", rewrittenFields)
		}

		token, jwtErr := jwt.ParseWithClaims(r.PostFormValue("file.gitlab-workhorse-upload"), &testhelper.UploadClaims{}, testhelper.ParseJWT)
		require.NoError(t, jwtErr, "Wrong signed upload fields")

		uploadFields := token.Claims.(*testhelper.UploadClaims).Upload
		require.Contains(t, uploadFields, "name")
		require.Contains(t, uploadFields, "path")
		require.Contains(t, uploadFields, "remote_url")
		require.Contains(t, uploadFields, "remote_id")
		require.Contains(t, uploadFields, "size")
		require.Contains(t, uploadFields, "md5")
		require.Contains(t, uploadFields, "sha1")
		require.Contains(t, uploadFields, "sha256")
		require.Contains(t, uploadFields, "sha512")

		path := r.PostFormValue("file.path")
		uploaded, err := os.Open(path)
		require.NoError(t, err, "File not uploaded")

		//sending back the file for testing purpose
		io.Copy(w, uploaded)
	})
}

type rails struct {
	unauthorized bool
}

func (r *rails) PreAuthorizeHandler(next api.HandleFunc, _ string) http.Handler {
	if r.unauthorized {
		return http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
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
