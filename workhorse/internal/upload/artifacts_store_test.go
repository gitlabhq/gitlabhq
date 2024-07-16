// Package upload contains tests for artifact storage functionality.
package upload

import (
	"archive/zip"
	"bytes"
	"crypto/md5"
	"encoding/hex"
	"fmt"
	"io"
	"mime/multipart"
	"net/http"
	"net/http/httptest"
	"os"
	"testing"
	"time"

	"github.com/stretchr/testify/assert"
	"github.com/stretchr/testify/require"

	"gitlab.com/gitlab-org/gitlab/workhorse/internal/api"
	"gitlab.com/gitlab-org/gitlab/workhorse/internal/testhelper"
	"gitlab.com/gitlab-org/gitlab/workhorse/internal/upload/destination/objectstore/test"
)

const (
	putURL = "/url/put"
)

func createTestZipArchive(t *testing.T) (data []byte, md5Hash string) {
	var buffer bytes.Buffer
	archive := zip.NewWriter(&buffer)
	fileInArchive, err := archive.Create("test.file")
	require.NoError(t, err)
	fmt.Fprint(fileInArchive, "test")
	archive.Close()
	data = buffer.Bytes()

	hasher := md5.New()
	hasher.Write(data)
	hexHash := hasher.Sum(nil)
	md5Hash = hex.EncodeToString(hexHash)

	return data, md5Hash
}

func createTestMultipartForm(t *testing.T, data []byte) (bytes.Buffer, string) {
	var buffer bytes.Buffer
	writer := multipart.NewWriter(&buffer)
	file, err := writer.CreateFormFile("file", "my.file")
	require.NoError(t, err)
	file.Write(data)
	writer.Close()
	return buffer, writer.FormDataContentType()
}

func testUploadArtifactsFromTestZip(t *testing.T, ts *httptest.Server) *httptest.ResponseRecorder {
	archiveData, _ := createTestZipArchive(t)
	contentBuffer, contentType := createTestMultipartForm(t, archiveData)

	return testUploadArtifacts(t, contentType, ts.URL+Path, &contentBuffer)
}

func TestUploadHandlerSendingToExternalStorage(t *testing.T) {
	tempPath := t.TempDir()

	archiveData, md5 := createTestZipArchive(t)
	archiveFile, err := os.CreateTemp(tempPath, "artifact.zip")
	require.NoError(t, err)
	_, err = archiveFile.Write(archiveData)
	require.NoError(t, err)
	archiveFile.Close()

	storeServerCalled := 0
	storeServerMux := http.NewServeMux()
	storeServerMux.HandleFunc(putURL, func(w http.ResponseWriter, r *http.Request) {
		assert.Equal(t, "PUT", r.Method)

		receivedData, err := io.ReadAll(r.Body)
		assert.NoError(t, err)
		assert.Equal(t, archiveData, receivedData)

		storeServerCalled++
		w.Header().Set("ETag", md5)
		w.WriteHeader(200)
	})
	storeServerMux.HandleFunc("/store-id", func(w http.ResponseWriter, r *http.Request) {
		http.ServeFile(w, r, archiveFile.Name())
	})

	responseProcessorCalled := 0
	responseProcessor := func(w http.ResponseWriter, r *http.Request) {
		assert.Equal(t, "store-id", r.FormValue("file.remote_id"))
		assert.NotEmpty(t, r.FormValue("file.remote_url"))
		w.WriteHeader(200)
		responseProcessorCalled++
	}

	storeServer := httptest.NewServer(storeServerMux)
	defer storeServer.Close()

	qs := fmt.Sprintf("?%s=%s", ArtifactFormatKey, ArtifactFormatZip)

	tests := []struct {
		name    string
		preauth *api.Response
	}{
		{
			name: "ObjectStore Upload",
			preauth: &api.Response{
				RemoteObject: api.RemoteObject{
					StoreURL: storeServer.URL + putURL + qs,
					ID:       "store-id",
					GetURL:   storeServer.URL + "/store-id",
				},
			},
		},
	}

	for _, test := range tests {
		t.Run(test.name, func(t *testing.T) {
			storeServerCalled = 0
			responseProcessorCalled = 0

			ts := testArtifactsUploadServer(t, test.preauth, responseProcessor)
			defer ts.Close()

			contentBuffer, contentType := createTestMultipartForm(t, archiveData)
			response := testUploadArtifacts(t, contentType, ts.URL+Path+qs, &contentBuffer)
			require.Equal(t, http.StatusOK, response.Code)
			testhelper.RequireResponseHeader(t, response, MetadataHeaderKey, MetadataHeaderPresent)
			require.Equal(t, 1, storeServerCalled, "store should be called only once")
			require.Equal(t, 1, responseProcessorCalled, "response processor should be called only once")
		})
	}
}

func TestUploadHandlerSendingToExternalStorageAndStorageServerUnreachable(t *testing.T) {
	tempPath := t.TempDir()

	responseProcessor := func(_ http.ResponseWriter, _ *http.Request) {
		t.Fatal("it should not be called")
	}

	authResponse := &api.Response{
		TempPath: tempPath,
		RemoteObject: api.RemoteObject{
			StoreURL: "http://localhost:12323/invalid/url",
			ID:       "store-id",
		},
	}

	ts := testArtifactsUploadServer(t, authResponse, responseProcessor)
	defer ts.Close()

	response := testUploadArtifactsFromTestZip(t, ts)
	require.Equal(t, http.StatusInternalServerError, response.Code)
}

func TestUploadHandlerSendingToExternalStorageAndInvalidURLIsUsed(t *testing.T) {
	tempPath := t.TempDir()

	responseProcessor := func(_ http.ResponseWriter, _ *http.Request) {
		t.Fatal("it should not be called")
	}

	authResponse := &api.Response{
		TempPath: tempPath,
		RemoteObject: api.RemoteObject{
			StoreURL: "htt:////invalid-url",
			ID:       "store-id",
		},
	}

	ts := testArtifactsUploadServer(t, authResponse, responseProcessor)
	defer ts.Close()

	response := testUploadArtifactsFromTestZip(t, ts)
	require.Equal(t, http.StatusInternalServerError, response.Code)
}

func TestUploadHandlerSendingToExternalStorageAndItReturnsAnError(t *testing.T) {
	putCalledTimes := 0

	storeServerMux := http.NewServeMux()
	storeServerMux.HandleFunc(putURL, func(w http.ResponseWriter, r *http.Request) {
		putCalledTimes++
		assert.Equal(t, "PUT", r.Method)
		w.WriteHeader(510)
	})

	responseProcessor := func(_ http.ResponseWriter, _ *http.Request) {
		t.Fatal("it should not be called")
	}

	storeServer := httptest.NewServer(storeServerMux)
	defer storeServer.Close()

	authResponse := &api.Response{
		RemoteObject: api.RemoteObject{
			StoreURL: storeServer.URL + putURL,
			ID:       "store-id",
		},
	}

	ts := testArtifactsUploadServer(t, authResponse, responseProcessor)
	defer ts.Close()

	response := testUploadArtifactsFromTestZip(t, ts)
	require.Equal(t, http.StatusInternalServerError, response.Code)
	require.Equal(t, 1, putCalledTimes, "upload should be called only once")
}

func TestUploadHandlerSendingToExternalStorageAndSupportRequestTimeout(t *testing.T) {
	shutdown := make(chan struct{})
	storeServerMux := http.NewServeMux()
	storeServerMux.HandleFunc(putURL, func(_ http.ResponseWriter, _ *http.Request) {
		<-shutdown
	})

	responseProcessor := func(_ http.ResponseWriter, _ *http.Request) {
		t.Fatal("it should not be called")
	}

	storeServer := httptest.NewServer(storeServerMux)
	defer func() {
		close(shutdown)
		storeServer.Close()
	}()

	authResponse := &api.Response{
		RemoteObject: api.RemoteObject{
			StoreURL: storeServer.URL + putURL,
			ID:       "store-id",
			Timeout:  0.1,
		},
	}

	ts := testArtifactsUploadServer(t, authResponse, responseProcessor)
	defer ts.Close()

	response := testUploadArtifactsFromTestZip(t, ts)
	// HTTP status 504 (gateway timeout) proves that the timeout was enforced
	require.Equal(t, http.StatusGatewayTimeout, response.Code)
}

func TestUploadHandlerMultipartUploadSizeLimit(t *testing.T) {
	os, server := test.StartObjectStore()
	defer server.Close()

	err := os.InitiateMultipartUpload(test.ObjectPath)
	require.NoError(t, err)

	objectURL := server.URL + test.ObjectPath

	uploadSize := 10
	preauth := &api.Response{
		RemoteObject: api.RemoteObject{
			ID: "store-id",
			MultipartUpload: &api.MultipartUploadParams{
				PartSize:    1,
				PartURLs:    []string{objectURL + "?partNumber=1"},
				AbortURL:    objectURL, // DELETE
				CompleteURL: objectURL, // POST
			},
		},
	}

	responseProcessor := func(_ http.ResponseWriter, _ *http.Request) {
		t.Fatal("it should not be called")
	}

	ts := testArtifactsUploadServer(t, preauth, responseProcessor)
	defer ts.Close()

	contentBuffer, contentType := createTestMultipartForm(t, make([]byte, uploadSize))
	response := testUploadArtifacts(t, contentType, ts.URL+Path, &contentBuffer)
	require.Equal(t, http.StatusRequestEntityTooLarge, response.Code)
	require.Eventually(t, func() bool {
		return !os.IsMultipartUpload(test.ObjectPath)
	}, time.Second, time.Millisecond, "MultipartUpload should not be in progress anymore")
	require.Empty(t, os.GetObjectMD5(test.ObjectPath), "upload should have failed, so the object should not exists")
}

func TestUploadHandlerMultipartUploadMaximumSizeFromApi(t *testing.T) {
	os, server := test.StartObjectStore()
	defer server.Close()

	err := os.InitiateMultipartUpload(test.ObjectPath)
	require.NoError(t, err)

	objectURL := server.URL + test.ObjectPath

	uploadSize := int64(10)
	maxSize := uploadSize - 1
	preauth := &api.Response{
		MaximumSize: maxSize,
		RemoteObject: api.RemoteObject{
			ID: "store-id",
			MultipartUpload: &api.MultipartUploadParams{
				PartSize:    uploadSize,
				PartURLs:    []string{objectURL + "?partNumber=1"},
				AbortURL:    objectURL, // DELETE
				CompleteURL: objectURL, // POST
			},
		},
	}

	responseProcessor := func(_ http.ResponseWriter, _ *http.Request) {
		t.Fatal("it should not be called")
	}

	ts := testArtifactsUploadServer(t, preauth, responseProcessor)
	defer ts.Close()

	contentBuffer, contentType := createTestMultipartForm(t, make([]byte, uploadSize))
	response := testUploadArtifacts(t, contentType, ts.URL+Path, &contentBuffer)
	require.Equal(t, http.StatusRequestEntityTooLarge, response.Code)

	require.Eventually(t, func() bool {
		return os.GetObjectMD5(test.ObjectPath) == ""
	}, 5*time.Second, time.Millisecond, "file is still present")
}
