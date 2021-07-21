package artifacts

import (
	"archive/zip"
	"bytes"
	"compress/gzip"
	"encoding/json"
	"fmt"
	"io"
	"io/ioutil"
	"mime/multipart"
	"net/http"
	"net/http/httptest"
	"os"
	"testing"

	"github.com/dgrijalva/jwt-go"

	"gitlab.com/gitlab-org/gitlab/workhorse/internal/api"
	"gitlab.com/gitlab-org/gitlab/workhorse/internal/filestore"
	"gitlab.com/gitlab-org/gitlab/workhorse/internal/helper"
	"gitlab.com/gitlab-org/gitlab/workhorse/internal/proxy"
	"gitlab.com/gitlab-org/gitlab/workhorse/internal/testhelper"
	"gitlab.com/gitlab-org/gitlab/workhorse/internal/upload"
	"gitlab.com/gitlab-org/gitlab/workhorse/internal/upstream/roundtripper"
	"gitlab.com/gitlab-org/gitlab/workhorse/internal/zipartifacts"

	"github.com/stretchr/testify/require"
)

const (
	MetadataHeaderKey     = "Metadata-Status"
	MetadataHeaderPresent = "present"
	MetadataHeaderMissing = "missing"
	Path                  = "/url/path"
)

func testArtifactsUploadServer(t *testing.T, authResponse api.Response, bodyProcessor func(w http.ResponseWriter, r *http.Request)) *httptest.Server {
	mux := http.NewServeMux()
	mux.HandleFunc(Path+"/authorize", func(w http.ResponseWriter, r *http.Request) {
		if r.Method != "POST" {
			t.Fatal("Expected POST request")
		}

		w.Header().Set("Content-Type", api.ResponseContentType)

		data, err := json.Marshal(&authResponse)
		if err != nil {
			t.Fatal("Expected to marshal")
		}
		w.Write(data)
	})
	mux.HandleFunc(Path, func(w http.ResponseWriter, r *http.Request) {
		opts, err := filestore.GetOpts(&authResponse)
		require.NoError(t, err)

		if r.Method != "POST" {
			t.Fatal("Expected POST request")
		}
		if opts.IsLocal() {
			if r.FormValue("file.path") == "" {
				t.Fatal("Expected file to be present")
				return
			}

			_, err := ioutil.ReadFile(r.FormValue("file.path"))
			if err != nil {
				t.Fatal("Expected file to be readable")
				return
			}
		} else {
			if r.FormValue("file.remote_url") == "" {
				t.Fatal("Expected file to be remote accessible")
				return
			}
		}

		if r.FormValue("metadata.path") != "" {
			metadata, err := ioutil.ReadFile(r.FormValue("metadata.path"))
			if err != nil {
				t.Fatal("Expected metadata to be readable")
				return
			}
			gz, err := gzip.NewReader(bytes.NewReader(metadata))
			if err != nil {
				t.Fatal("Expected metadata to be valid gzip")
				return
			}
			defer gz.Close()
			metadata, err = ioutil.ReadAll(gz)
			if err != nil {
				t.Fatal("Expected metadata to be valid")
				return
			}
			if !bytes.HasPrefix(metadata, []byte(zipartifacts.MetadataHeaderPrefix+zipartifacts.MetadataHeader)) {
				t.Fatal("Expected metadata to be of valid format")
				return
			}

			w.Header().Set(MetadataHeaderKey, MetadataHeaderPresent)

		} else {
			w.Header().Set(MetadataHeaderKey, MetadataHeaderMissing)
		}

		w.WriteHeader(http.StatusOK)

		if bodyProcessor != nil {
			bodyProcessor(w, r)
		}
	})
	return testhelper.TestServerWithHandler(nil, mux.ServeHTTP)
}

type testServer struct {
	url        string
	writer     *multipart.Writer
	buffer     *bytes.Buffer
	fileWriter io.Writer
	cleanup    func()
}

func setupWithTmpPath(t *testing.T, filename string, includeFormat bool, format string, authResponse *api.Response, bodyProcessor func(w http.ResponseWriter, r *http.Request)) *testServer {
	tempPath, err := ioutil.TempDir("", "uploads")
	require.NoError(t, err)

	if authResponse == nil {
		authResponse = &api.Response{TempPath: tempPath}
	}

	ts := testArtifactsUploadServer(t, *authResponse, bodyProcessor)

	var buffer bytes.Buffer
	writer := multipart.NewWriter(&buffer)
	fileWriter, err := writer.CreateFormFile(filename, "my.file")
	require.NotNil(t, fileWriter)
	require.NoError(t, err)

	cleanup := func() {
		ts.Close()
		require.NoError(t, os.RemoveAll(tempPath))
		require.NoError(t, writer.Close())
	}

	qs := ""

	if includeFormat {
		qs = fmt.Sprintf("?%s=%s", ArtifactFormatKey, format)
	}

	return &testServer{url: ts.URL + Path + qs, writer: writer, buffer: &buffer, fileWriter: fileWriter, cleanup: cleanup}
}

func testUploadArtifacts(t *testing.T, contentType, url string, body io.Reader) *httptest.ResponseRecorder {
	httpRequest, err := http.NewRequest("POST", url, body)
	require.NoError(t, err)

	httpRequest.Header.Set("Content-Type", contentType)
	response := httptest.NewRecorder()
	parsedURL := helper.URLMustParse(url)
	roundTripper := roundtripper.NewTestBackendRoundTripper(parsedURL)
	testhelper.ConfigureSecret()
	apiClient := api.NewAPI(parsedURL, "123", roundTripper)
	proxyClient := proxy.NewProxy(parsedURL, "123", roundTripper)
	UploadArtifacts(apiClient, proxyClient, &upload.DefaultPreparer{}).ServeHTTP(response, httpRequest)
	return response
}

func TestUploadHandlerAddingMetadata(t *testing.T) {
	testCases := []struct {
		desc          string
		format        string
		includeFormat bool
	}{
		{
			desc:          "ZIP format",
			format:        ArtifactFormatZip,
			includeFormat: true,
		},
		{
			desc:          "default format",
			format:        ArtifactFormatDefault,
			includeFormat: true,
		},
		{
			desc:          "default format without artifact_format",
			format:        ArtifactFormatDefault,
			includeFormat: false,
		},
	}

	for _, tc := range testCases {
		t.Run(tc.desc, func(t *testing.T) {
			s := setupWithTmpPath(t, "file", tc.includeFormat, tc.format, nil,
				func(w http.ResponseWriter, r *http.Request) {
					token, err := jwt.ParseWithClaims(r.Header.Get(upload.RewrittenFieldsHeader), &upload.MultipartClaims{}, testhelper.ParseJWT)
					require.NoError(t, err)

					rewrittenFields := token.Claims.(*upload.MultipartClaims).RewrittenFields
					require.Equal(t, 2, len(rewrittenFields))

					require.Contains(t, rewrittenFields, "file")
					require.Contains(t, rewrittenFields, "metadata")
					require.Contains(t, r.PostForm, "file.gitlab-workhorse-upload")
					require.Contains(t, r.PostForm, "metadata.gitlab-workhorse-upload")
				},
			)
			defer s.cleanup()

			archive := zip.NewWriter(s.fileWriter)
			file, err := archive.Create("test.file")
			require.NotNil(t, file)
			require.NoError(t, err)

			require.NoError(t, archive.Close())
			require.NoError(t, s.writer.Close())

			response := testUploadArtifacts(t, s.writer.FormDataContentType(), s.url, s.buffer)
			require.Equal(t, http.StatusOK, response.Code)
			testhelper.RequireResponseHeader(t, response, MetadataHeaderKey, MetadataHeaderPresent)
		})
	}
}

func TestUploadHandlerTarArtifact(t *testing.T) {
	s := setupWithTmpPath(t, "file", true, "tar", nil,
		func(w http.ResponseWriter, r *http.Request) {
			token, err := jwt.ParseWithClaims(r.Header.Get(upload.RewrittenFieldsHeader), &upload.MultipartClaims{}, testhelper.ParseJWT)
			require.NoError(t, err)

			rewrittenFields := token.Claims.(*upload.MultipartClaims).RewrittenFields
			require.Equal(t, 1, len(rewrittenFields))

			require.Contains(t, rewrittenFields, "file")
			require.Contains(t, r.PostForm, "file.gitlab-workhorse-upload")
		},
	)
	defer s.cleanup()

	file, err := os.Open("../../testdata/tarfile.tar")
	require.NoError(t, err)

	_, err = io.Copy(s.fileWriter, file)
	require.NoError(t, err)
	require.NoError(t, file.Close())
	require.NoError(t, s.writer.Close())

	response := testUploadArtifacts(t, s.writer.FormDataContentType(), s.url, s.buffer)
	require.Equal(t, http.StatusOK, response.Code)
	testhelper.RequireResponseHeader(t, response, MetadataHeaderKey, MetadataHeaderMissing)
}

func TestUploadHandlerForUnsupportedArchive(t *testing.T) {
	s := setupWithTmpPath(t, "file", true, "other", nil, nil)
	defer s.cleanup()
	require.NoError(t, s.writer.Close())

	response := testUploadArtifacts(t, s.writer.FormDataContentType(), s.url, s.buffer)
	require.Equal(t, http.StatusOK, response.Code)
	testhelper.RequireResponseHeader(t, response, MetadataHeaderKey, MetadataHeaderMissing)
}

func TestUploadHandlerForMultipleFiles(t *testing.T) {
	s := setupWithTmpPath(t, "file", true, "", nil, nil)
	defer s.cleanup()

	file, err := s.writer.CreateFormFile("file", "my.file")
	require.NotNil(t, file)
	require.NoError(t, err)
	require.NoError(t, s.writer.Close())

	response := testUploadArtifacts(t, s.writer.FormDataContentType(), s.url, s.buffer)
	require.Equal(t, http.StatusInternalServerError, response.Code)
}

func TestUploadFormProcessing(t *testing.T) {
	s := setupWithTmpPath(t, "metadata", true, "", nil, nil)
	defer s.cleanup()
	require.NoError(t, s.writer.Close())

	response := testUploadArtifacts(t, s.writer.FormDataContentType(), s.url, s.buffer)
	require.Equal(t, http.StatusInternalServerError, response.Code)
}

func TestLsifFileProcessing(t *testing.T) {
	tempPath, err := ioutil.TempDir("", "uploads")
	require.NoError(t, err)

	s := setupWithTmpPath(t, "file", true, "zip", &api.Response{TempPath: tempPath, ProcessLsif: true}, nil)
	defer s.cleanup()

	file, err := os.Open("../../testdata/lsif/valid.lsif.zip")
	require.NoError(t, err)

	_, err = io.Copy(s.fileWriter, file)
	require.NoError(t, err)
	require.NoError(t, file.Close())
	require.NoError(t, s.writer.Close())

	response := testUploadArtifacts(t, s.writer.FormDataContentType(), s.url, s.buffer)
	require.Equal(t, http.StatusOK, response.Code)
	testhelper.RequireResponseHeader(t, response, MetadataHeaderKey, MetadataHeaderPresent)
}

func TestInvalidLsifFileProcessing(t *testing.T) {
	tempPath, err := ioutil.TempDir("", "uploads")
	require.NoError(t, err)

	s := setupWithTmpPath(t, "file", true, "zip", &api.Response{TempPath: tempPath, ProcessLsif: true}, nil)
	defer s.cleanup()

	file, err := os.Open("../../testdata/lsif/invalid.lsif.zip")
	require.NoError(t, err)

	_, err = io.Copy(s.fileWriter, file)
	require.NoError(t, err)
	require.NoError(t, file.Close())
	require.NoError(t, s.writer.Close())

	response := testUploadArtifacts(t, s.writer.FormDataContentType(), s.url, s.buffer)
	require.Equal(t, http.StatusInternalServerError, response.Code)
}
