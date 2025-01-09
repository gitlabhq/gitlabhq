package main

import (
	"bytes"
	"fmt"
	"io"
	"mime/multipart"
	"net/http"
	"net/http/httptest"
	"os"
	"regexp"
	"strconv"
	"strings"
	"testing"

	"github.com/golang-jwt/jwt/v5"
	"github.com/stretchr/testify/assert"
	"github.com/stretchr/testify/require"

	"gitlab.com/gitlab-org/gitlab/workhorse/internal/api"
	"gitlab.com/gitlab-org/gitlab/workhorse/internal/secret"
	"gitlab.com/gitlab-org/gitlab/workhorse/internal/testhelper"
	"gitlab.com/gitlab-org/gitlab/workhorse/internal/upload"
)

type uploadArtifactsFunction func(url, contentType string, body io.Reader) (*http.Response, string, error)

func uploadArtifactsV4(url, contentType string, body io.Reader) (*http.Response, string, error) {
	resource := `/api/v4/jobs/123/artifacts`
	resp, err := http.Post(url+resource, contentType, body)
	return resp, resource, err
}

const (
	requestBody         = "test data"
	testRspSuccessBody  = "test success"
	authorizeUploadPath = "/api/v4/internal/workhorse/authorize_upload"
	authorizeSuffix     = "/authorize"
)

func testArtifactsUpload(t *testing.T, uploadArtifacts uploadArtifactsFunction) {
	reqBody, contentType, err := multipartBodyWithFile()
	require.NoError(t, err)

	ts := signedUploadTestServer(t, nil, nil)
	defer ts.Close()

	ws := startWorkhorseServer(t, ts.URL)

	resp, resource, err := uploadArtifacts(ws.URL, contentType, reqBody)
	require.NoError(t, err)
	defer resp.Body.Close()

	require.Equal(t, 200, resp.StatusCode, "GET %q: expected 200, got %d", resource, resp.StatusCode)
}

func TestArtifactsUpload(t *testing.T) {
	testArtifactsUpload(t, uploadArtifactsV4)
}

func expectSignedRequest(t *testing.T, r *http.Request) {
	t.Helper()

	_, err := jwt.Parse(r.Header.Get(secret.RequestHeader), testhelper.ParseJWT)
	require.NoError(t, err)
}

func uploadTestServer(t *testing.T, allowedHashFunctions []string, authorizeTests func(r *http.Request), extraTests func(r *http.Request)) *httptest.Server {
	return testhelper.TestServerWithHandler(regexp.MustCompile(`.`), func(w http.ResponseWriter, r *http.Request) {
		if strings.HasSuffix(r.URL.Path, authorizeSuffix) || r.URL.Path == authorizeUploadPath {
			expectSignedRequest(t, r)

			w.Header().Set("Content-Type", api.ResponseContentType)
			var err error

			if len(allowedHashFunctions) == 0 {
				_, err = fmt.Fprintf(w, `{"TempPath":"%s"}`, t.TempDir())
			} else {
				_, err = fmt.Fprintf(w, `{"TempPath":"%s", "UploadHashFunctions": ["%s"]}`, t.TempDir(), strings.Join(allowedHashFunctions, `","`))
			}

			assert.NoError(t, err)

			if authorizeTests != nil {
				authorizeTests(r)
			}
			return
		}

		assert.NoError(t, r.ParseMultipartForm(100000))

		nValues := len([]string{
			"name",
			"path",
			"remote_url",
			"remote_id",
			"size",
			"upload_duration",
			"gitlab-workhorse-upload",
		})

		if n := len(allowedHashFunctions); n > 0 {
			nValues += n
		} else {
			nValues += len([]string{"md5", "sha1", "sha256", "sha512"}) // Default hash functions
		}

		assert.Len(t, r.MultipartForm.Value, nValues)
		assert.Empty(t, r.MultipartForm.File, "multipart form files")

		if extraTests != nil {
			extraTests(r)
		}
		w.WriteHeader(200)
	})
}

func signedUploadTestServer(t *testing.T, authorizeTests func(r *http.Request), extraTests func(r *http.Request)) *httptest.Server {
	t.Helper()

	return uploadTestServer(t, nil, authorizeTests, func(r *http.Request) {
		expectSignedRequest(t, r)

		if extraTests != nil {
			extraTests(r)
		}
	})
}

func TestAcceleratedUpload(t *testing.T) {
	tests := []struct {
		method             string
		resource           string
		signedFinalization bool
	}{
		{"POST", `/example`, false},
		{"POST", `/uploads/personal_snippet`, true},
		{"POST", `/uploads/user`, true},
		{"POST", `/api/v4/projects`, false},
		{"PUT", `/api/v4/projects/group%2Fproject`, false},
		{"PUT", `/api/v4/projects/group%2Fsubgroup%2Fproject`, false},
		{"PUT", `/api/v4/projects/39`, false},
		{"POST", `/api/v4/projects/1/uploads`, true},
		{"POST", `/api/v4/projects/group%2Fproject/uploads`, true},
		{"POST", `/api/v4/projects/group%2Fsubgroup%2Fproject/uploads`, true},
		{"POST", `/api/v4/projects/1/wikis/attachments`, false},
		{"POST", `/api/v4/projects/group%2Fproject/wikis/attachments`, false},
		{"POST", `/api/v4/projects/group%2Fsubgroup%2Fproject/wikis/attachments`, false},
		{"POST", `/api/graphql`, false},
		{"POST", `/api/v4/topics`, false},
		{"PUT", `/api/v4/topics`, false},
		{"POST", `/api/v4/organizations`, false},
		{"PUT", `/api/v4/organizations/1`, false},
		{"POST", `/api/v4/groups`, false},
		{"PUT", `/api/v4/groups/5`, false},
		{"PUT", `/api/v4/groups/group%2Fsubgroup`, false},
		{"POST", `/api/v4/groups/1/wikis/attachments`, false},
		{"POST", `/api/v4/groups/my%2Fsubgroup/wikis/attachments`, false},
		{"PUT", `/api/v4/user/avatar`, false},
		{"POST", `/api/v4/users`, false},
		{"PUT", `/api/v4/users/42`, false},
		{"PUT", "/api/v4/projects/9001/packages/nuget/v1/files", true},
		{"PUT", "/api/v4/projects/group%2Fproject/packages/nuget/v1/files", true},
		{"PUT", "/api/v4/projects/group%2Fsubgroup%2Fproject/packages/nuget/v1/files", true},
		{"PUT", "/api/v4/projects/9001/packages/nuget/v2/files", true},
		{"PUT", "/api/v4/projects/group%2Fproject/packages/nuget/v2/files", true},
		{"PUT", "/api/v4/projects/group%2Fsubgroup%2Fproject/packages/nuget/v2/files", true},
		{"POST", `/api/v4/groups/import`, true},
		{"POST", `/api/v4/groups/import/`, true},
		{"POST", `/api/v4/projects/import`, true},
		{"POST", `/api/v4/projects/import/`, true},
		{"POST", `/api/v4/projects/import-relation`, true},
		{"POST", `/api/v4/projects/import-relation/`, true},
		{"POST", `/import/gitlab_project`, true},
		{"POST", `/import/gitlab_project/`, true},
		{"POST", `/import/gitlab_group`, true},
		{"POST", `/import/gitlab_group/`, true},
		{"POST", `/api/v4/projects/9001/packages/pypi`, true},
		{"POST", `/api/v4/projects/group%2Fproject/packages/pypi`, true},
		{"POST", `/api/v4/projects/group%2Fsubgroup%2Fproject/packages/pypi`, true},
		{"POST", `/api/v4/projects/9001/issues/30/metric_images`, true},
		{"POST", `/api/v4/projects/group%2Fproject/issues/30/metric_images`, true},
		{"POST", `/api/v4/projects/9001/alert_management_alerts/30/metric_images`, true},
		{"POST", `/api/v4/projects/group%2Fsubgroup%2Fproject/issues/30/metric_images`, true},
		{"POST", `/my/project/-/requirements_management/requirements/import_csv`, true},
		{"POST", `/my/project/-/requirements_management/requirements/import_csv/`, true},
		{"POST", `/my/project/-/work_items/import_csv`, true},
		{"POST", `/my/project/-/work_items/import_csv/`, true},
		{"POST", "/api/v4/projects/2412/packages/helm/api/stable/charts", true},
		{"POST", "/api/v4/projects/group%2Fproject/packages/helm/api/stable/charts", true},
		{"POST", "/api/v4/projects/group%2Fsubgroup%2Fproject/packages/helm/api/stable/charts", true},
		{"POST", "/groups/my-group/-/group_members/bulk_reassignment_file", true},
	}

	allowedHashFunctions := map[string][]string{
		"default":   nil,
		"sha2_only": {"sha256", "sha512"},
	}

	for _, tt := range tests {
		for hashSet, hashFunctions := range allowedHashFunctions {
			t.Run(tt.resource, func(t *testing.T) {
				ts := uploadTestServer(t,
					hashFunctions,
					func(r *http.Request) {
						if r.URL.Path == authorizeUploadPath {
							// Nothing to validate: this is a hard coded URL
							return
						}
						resource := strings.TrimRight(tt.resource, "/")
						// Validate %2F characters haven't been unescaped
						require.Equal(t, resource+authorizeSuffix, r.URL.String())
					},
					func(r *http.Request) {
						if tt.signedFinalization {
							expectSignedRequest(t, r)
						}

						token, err := jwt.ParseWithClaims(r.Header.Get(upload.RewrittenFieldsHeader), &upload.MultipartClaims{}, testhelper.ParseJWT)
						require.NoError(t, err)

						rewrittenFields := token.Claims.(*upload.MultipartClaims).RewrittenFields
						if len(rewrittenFields) != 1 || len(rewrittenFields["file"]) == 0 {
							t.Fatalf("Unexpected rewritten_fields value: %v", rewrittenFields)
						}

						token, jwtErr := jwt.ParseWithClaims(r.PostFormValue("file.gitlab-workhorse-upload"), &testhelper.UploadClaims{}, testhelper.ParseJWT)
						require.NoError(t, jwtErr)

						uploadFields := token.Claims.(*testhelper.UploadClaims).Upload
						verifyUploadFields(t, uploadFields, hashSet)
					})

				defer ts.Close()
				ws := startWorkhorseServer(t, ts.URL)

				reqBody, contentType, err := multipartBodyWithFile()
				require.NoError(t, err)

				req, err := http.NewRequest(tt.method, ws.URL+tt.resource, reqBody)
				require.NoError(t, err)

				req.Header.Set("Content-Type", contentType)
				resp, err := http.DefaultClient.Do(req)
				require.NoError(t, err)
				require.Equal(t, 200, resp.StatusCode)

				resp.Body.Close()
			})
		}
	}
}

func verifyUploadFields(t *testing.T, fields map[string]string, hashSet string) {
	t.Helper()

	require.Contains(t, fields, "name")
	require.Contains(t, fields, "path")
	require.Contains(t, fields, "remote_url")
	require.Contains(t, fields, "remote_id")
	require.Contains(t, fields, "size")

	if hashSet == "default" {
		require.Contains(t, fields, "md5")
		require.Contains(t, fields, "sha1")
		require.Contains(t, fields, "sha256")
		require.Contains(t, fields, "sha512")
	} else {
		require.NotContains(t, fields, "md5")
		require.NotContains(t, fields, "sha1")
		require.Contains(t, fields, "sha256")
		require.Contains(t, fields, "sha512")
	}
}

func multipartBodyWithFile() (io.Reader, string, error) {
	result := &bytes.Buffer{}
	writer := multipart.NewWriter(result)
	file, err := writer.CreateFormFile("file", "my.file")
	if err != nil {
		return nil, "", err
	}
	fmt.Fprint(file, "SHOULD BE ON DISK, NOT IN MULTIPART")
	return result, writer.FormDataContentType(), writer.Close()
}

func unacceleratedUploadTestServer(t *testing.T) *httptest.Server {
	return testhelper.TestServerWithHandler(regexp.MustCompile(`.`), func(w http.ResponseWriter, r *http.Request) {
		assert.False(t, strings.HasSuffix(r.URL.Path, "/authorize"))
		assert.Empty(t, r.Header.Get(upload.RewrittenFieldsHeader))

		w.WriteHeader(200)
	})
}

func TestUnacceleratedUploads(t *testing.T) {
	tests := []struct {
		method   string
		resource string
	}{
		{"POST", `/api/v4/projects/group/subgroup/project/wikis/attachments`},
		{"POST", `/api/v4/projects/group/project/wikis/attachments`},
		{"PUT", "/api/v4/projects/group/subgroup/project/packages/nuget/v1/files"},
		{"PUT", "/api/v4/projects/group/project/packages/nuget/v1/files"},
		{"POST", "/api/v4/projects/group/subgroup/project/packages/nuget/v2/files"},
		{"POST", "/api/v4/projects/group/project/packages/nuget/v2/files"},
		{"POST", `/api/v4/projects/group/subgroup/project/packages/pypi`},
		{"POST", `/api/v4/projects/group/project/packages/pypi`},
		{"POST", `/api/v4/projects/group/subgroup/project/packages/pypi`},
		{"POST", "/api/v4/projects/group/project/packages/helm/api/stable/charts"},
		{"POST", "/api/v4/projects/group/subgroup%2Fproject/packages/helm/api/stable/charts"},
		{"POST", `/api/v4/projects/group/project/issues/30/metric_images`},
		{"POST", `/api/v4/projects/group/subgroup/project/issues/30/metric_images`},
	}

	for _, tt := range tests {
		t.Run(tt.resource, func(t *testing.T) {
			ts := unacceleratedUploadTestServer(t)

			defer ts.Close()
			ws := startWorkhorseServer(t, ts.URL)

			reqBody, contentType, err := multipartBodyWithFile()
			require.NoError(t, err)

			req, err := http.NewRequest(tt.method, ws.URL+tt.resource, reqBody)
			require.NoError(t, err)

			req.Header.Set("Content-Type", contentType)
			resp, err := http.DefaultClient.Do(req)
			require.NoError(t, err)
			require.Equal(t, 200, resp.StatusCode)

			resp.Body.Close()
		})
	}
}

func TestBlockingRewrittenFieldsHeader(t *testing.T) {
	canary := "untrusted header passed by user"
	multiPartBody, multiPartContentType, err := multipartBodyWithFile()
	require.NoError(t, err)

	testCases := []struct {
		desc        string
		contentType string
		body        io.Reader
		present     bool
	}{
		{"multipart with file", multiPartContentType, multiPartBody, true},
		{"no multipart", "text/plain", nil, false},
	}

	for _, tc := range testCases {
		t.Run(tc.desc, func(t *testing.T) {
			ts := testhelper.TestServerWithHandler(regexp.MustCompile(`.`), func(w http.ResponseWriter, r *http.Request) {
				switch r.URL.Path {
				case authorizeUploadPath:
					w.Header().Set("Content-Type", api.ResponseContentType)
					io.WriteString(w, `{"TempPath":"`+os.TempDir()+`"}`)
				default:
					if tc.present {
						assert.Contains(t, r.Header, upload.RewrittenFieldsHeader)
					} else {
						assert.NotContains(t, r.Header, upload.RewrittenFieldsHeader)
					}
				}

				assert.NotEqual(t, canary, r.Header.Get(upload.RewrittenFieldsHeader), "Found canary %q in header", canary)
			})
			defer ts.Close()
			ws := startWorkhorseServer(t, ts.URL)

			req, err := http.NewRequest("POST", ws.URL+"/something", tc.body)
			require.NoError(t, err)

			req.Header.Set("Content-Type", tc.contentType)
			req.Header.Set(upload.RewrittenFieldsHeader, canary)
			resp, err := http.DefaultClient.Do(req)
			require.NoError(t, err)
			defer resp.Body.Close()

			assert.Equal(t, 200, resp.StatusCode, "status code")
		})
	}
}

func TestLfsUpload(t *testing.T) {
	oid := "916f0027a575074ce72a331777c3478d6513f786a591bd892da1a577bf2335f9"
	resource := fmt.Sprintf("/%s/gitlab-lfs/objects/%s/%d", testRepo, oid, len(requestBody))

	lfsAPIResponse := fmt.Sprintf(
		`{"TempPath":%q, "LfsOid":%q, "LfsSize": %d}`,
		t.TempDir(), oid, len(requestBody),
	)

	ts := testhelper.TestServerWithHandler(regexp.MustCompile(`.`), func(w http.ResponseWriter, r *http.Request) {
		assert.Equal(t, "PUT", r.Method)
		switch r.RequestURI {
		case resource + authorizeSuffix:
			expectSignedRequest(t, r)

			// Instruct workhorse to accept the upload
			w.Header().Set("Content-Type", api.ResponseContentType)
			_, err := fmt.Fprint(w, lfsAPIResponse)
			assert.NoError(t, err)

		case resource:
			expectSignedRequest(t, r)

			// Expect the request to point to a file on disk containing the data
			assert.NoError(t, r.ParseForm())
			assert.Equal(t, oid, r.Form.Get("file.sha256"), "Invalid SHA256 populated")
			assert.Equal(t, strconv.Itoa(len(requestBody)), r.Form.Get("file.size"), "Invalid size populated")

			tempfile, err := os.ReadFile(r.Form.Get("file.path"))
			assert.NoError(t, err)
			assert.Equal(t, requestBody, string(tempfile), "Temporary file has the wrong body")

			fmt.Fprint(w, testRspSuccessBody)
		default:
			t.Fatalf("Unexpected request to upstream! %v %q", r.Method, r.RequestURI)
		}
	})
	defer ts.Close()

	ws := startWorkhorseServer(t, ts.URL)

	req, err := http.NewRequest("PUT", ws.URL+resource, strings.NewReader(requestBody))
	require.NoError(t, err)

	req.Header.Set("Content-Type", "application/octet-stream")
	req.ContentLength = int64(len(requestBody))

	resp, err := http.DefaultClient.Do(req)
	require.NoError(t, err)

	defer resp.Body.Close()
	rspData, err := io.ReadAll(resp.Body)
	require.NoError(t, err)

	// Expect the (eventual) response to be proxied through, untouched
	require.Equal(t, 200, resp.StatusCode)
	require.Equal(t, testRspSuccessBody, string(rspData))
}

func TestLfsUploadRouting(t *testing.T) {
	oid := "916f0027a575074ce72a331777c3478d6513f786a591bd892da1a577bf2335f9"

	ts := testhelper.TestServerWithHandler(regexp.MustCompile(`.`), func(w http.ResponseWriter, r *http.Request) {
		if r.Header.Get(secret.RequestHeader) == "" {
			w.WriteHeader(204)
		} else {
			fmt.Fprint(w, testRspSuccessBody)
		}
	})
	defer ts.Close()

	ws := startWorkhorseServer(t, ts.URL)

	testCases := []struct {
		method      string
		path        string
		contentType string
		match       bool
	}{
		{"PUT", "/toplevel.git/gitlab-lfs/objects", "application/octet-stream", true},
		{"PUT", "/toplevel.wiki.git/gitlab-lfs/objects", "application/octet-stream", true},
		{"PUT", "/toplevel/child/project.git/gitlab-lfs/objects", "application/octet-stream", true},
		{"PUT", "/toplevel/child/project.wiki.git/gitlab-lfs/objects", "application/octet-stream", true},
		{"PUT", "/toplevel/child/project/snippets/123.git/gitlab-lfs/objects", "application/octet-stream", true},
		{"PUT", "/snippets/123.git/gitlab-lfs/objects", "application/octet-stream", true},
		{"PUT", "/foo/bar/gitlab-lfs/objects", "application/octet-stream", false},
		{"PUT", "/foo/bar.git/gitlab-lfs/objects/zzz", "application/octet-stream", false},
		{"PUT", "/.git/gitlab-lfs/objects", "application/octet-stream", false},
		{"PUT", "/toplevel.git/gitlab-lfs/objects", "application/zzz", false},
		{"POST", "/toplevel.git/gitlab-lfs/objects", "application/octet-stream", false},
	}

	for _, tc := range testCases {
		t.Run(tc.path, func(t *testing.T) {
			resource := fmt.Sprintf(tc.path+"/%s/%d", oid, len(requestBody))

			req, err := http.NewRequest(
				tc.method,
				ws.URL+resource,
				strings.NewReader(requestBody),
			)
			require.NoError(t, err)

			req.Header.Set("Content-Type", tc.contentType)
			req.ContentLength = int64(len(requestBody))

			resp, err := http.DefaultClient.Do(req)
			require.NoError(t, err)
			defer resp.Body.Close()

			rspData, err := io.ReadAll(resp.Body)
			require.NoError(t, err)

			if tc.match {
				require.Equal(t, 200, resp.StatusCode)
				require.Equal(t, testRspSuccessBody, string(rspData), "expect response generated by test upstream server")
			} else {
				require.Equal(t, 204, resp.StatusCode)
				require.Empty(t, rspData, "normal request has empty response body")
			}
		})
	}
}

func packageUploadTestServer(t *testing.T, method string, resource string, reqBody string, rspBody string) *httptest.Server {
	return testhelper.TestServerWithHandler(regexp.MustCompile(`.`), func(w http.ResponseWriter, r *http.Request) {
		assert.Equal(t, r.Method, method)
		apiResponse := fmt.Sprintf(
			`{"TempPath":%q, "Size": %d}`, t.TempDir(), len(reqBody),
		)
		switch r.RequestURI {
		case resource + authorizeSuffix:
			expectSignedRequest(t, r)

			// Instruct workhorse to accept the upload
			w.Header().Set("Content-Type", api.ResponseContentType)
			_, err := fmt.Fprint(w, apiResponse)
			assert.NoError(t, err)

		case resource:
			expectSignedRequest(t, r)

			// Expect the request to point to a file on disk containing the data
			assert.NoError(t, r.ParseForm())

			fileLen := strconv.Itoa(len(reqBody))
			assert.Equal(t, fileLen, r.Form.Get("file.size"), "Invalid size populated")

			tmpFilePath := r.Form.Get("file.path")
			fileData, err := os.ReadFile(tmpFilePath)
			defer os.Remove(tmpFilePath)

			assert.NoError(t, err)
			assert.Equal(t, reqBody, string(fileData), "Temporary file has the wrong body")

			fmt.Fprint(w, rspBody)
		default:
			t.Fatalf("Unexpected request to upstream! %v %q", r.Method, r.RequestURI)
		}
	})
}

func testPackageFileUpload(t *testing.T, method string, resource string) {
	ts := packageUploadTestServer(t, method, resource, requestBody, testRspSuccessBody)
	defer ts.Close()

	ws := startWorkhorseServer(t, ts.URL)

	req, err := http.NewRequest(method, ws.URL+resource, strings.NewReader(requestBody))
	require.NoError(t, err)

	resp, err := http.DefaultClient.Do(req)
	require.NoError(t, err)

	respData, err := io.ReadAll(resp.Body)
	require.NoError(t, err)
	require.Equal(t, testRspSuccessBody, string(respData), "Temporary file has the wrong body")
	defer resp.Body.Close()

	require.Equal(t, 200, resp.StatusCode)
}

func TestPackageFilesUpload(t *testing.T) {
	routes := []struct {
		method   string
		resource string
	}{
		{"PUT", "/api/v4/packages/conan/v1/files"},
		{"PUT", "/api/v4/projects/2412/packages/conan/v1/files"},
		{"PUT", "/api/v4/projects/2412/packages/maven/v1/files"},
		{"PUT", "/api/v4/projects/2412/packages/generic/mypackage/0.0.1/myfile.tar.gz"},
		{"PUT", "/api/v4/projects/2412/packages/debian/libsample0_1.2.3~alpha2-1_amd64.deb"},
		{"POST", "/api/v4/projects/2412/packages/rubygems/api/v1/gems/sample.gem"},
		{"POST", "/api/v4/projects/2412/packages/rpm/sample-4.23.fc21.x86_64.rpm"},
		{"PUT", "/api/v4/projects/group%2Fproject/packages/conan/v1/files"},
		{"PUT", "/api/v4/projects/group%2Fproject/packages/maven/v1/files"},
		{"PUT", "/api/v4/projects/group%2Fproject/packages/generic/mypackage/0.0.1/myfile.tar.gz"},
		{"PUT", "/api/v4/projects/group%2Fproject/packages/ml_models/mymodel/0.0.1/myfile.tar.gz"},
		{"PUT", "/api/v4/projects/group%2Fproject/packages/debian/libsample0_1.2.3~alpha2-1_amd64.deb"},
		{"POST", "/api/v4/projects/group%2Fproject/packages/rubygems/api/v1/gems/sample.gem"},
		{"POST", "/api/v4/projects/group%2Fproject/packages/rpm/sample-4.23.fc21.x86_64.rpm"},
		{"PUT", "/api/v4/projects/group%2Fproject/packages/terraform/modules/mymodule/mysystem/0.0.1/file"},
	}

	for _, r := range routes {
		testPackageFileUpload(t, r.method, r.resource)
	}
}
