package main

import (
	"fmt"
	"io"
	"mime"
	"net/http"
	"os"
	"path"
	"regexp"
	"testing"

	"github.com/stretchr/testify/assert"
	"github.com/stretchr/testify/require"
	"gitlab.com/gitlab-org/labkit/log"

	"gitlab.com/gitlab-org/gitlab/workhorse/internal/testhelper"
)

func TestDeniedLfsDownload(t *testing.T) {
	contentFilename := "b68143e6463773b1b6c6fd009a76c32aeec041faff32ba2ed42fd7f708a17f80"
	url := fmt.Sprintf("gitlab-lfs/objects/%s", contentFilename)

	deniedXSendfileDownload(t, contentFilename, url)
}

func TestAllowedLfsDownload(t *testing.T) {
	contentFilename := "b68143e6463773b1b6c6fd009a76c32aeec041faff32ba2ed42fd7f708a17f80"
	url := fmt.Sprintf("gitlab-lfs/objects/%s", contentFilename)

	allowedXSendfileDownload(t, contentFilename, url)
}

func allowedXSendfileDownload(t *testing.T, contentFilename string, filePath string) {
	contentPath := path.Join(t.TempDir(), contentFilename)
	// Prepare test server and backend
	ts := testhelper.TestServerWithHandler(regexp.MustCompile(`.`), http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		log.WithFields(log.Fields{"method": r.Method, "url": r.URL}).Info("UPSTREAM")

		assert.Equal(t, "X-Sendfile", r.Header.Get("X-Sendfile-Type"))

		w.Header().Set("X-Sendfile", contentPath)
		w.Header().Set("Content-Disposition", fmt.Sprintf(`attachment; filename="%s"`, contentFilename))
		w.Header().Set("Content-Type", "application/octet-stream")
		w.WriteHeader(200)
	}))
	defer ts.Close()
	ws := startWorkhorseServer(t, ts.URL)

	contentBytes := []byte("content")
	require.NoError(t, os.WriteFile(contentPath, contentBytes, 0644))

	resp, err := http.Get(fmt.Sprintf("%s/%s", ws.URL, filePath))
	require.NoError(t, err)

	requireAttachmentName(t, resp, contentFilename)

	actual, err := io.ReadAll(resp.Body)
	require.NoError(t, err)
	require.NoError(t, resp.Body.Close())

	require.Equal(t, actual, contentBytes, "response body")
}

func deniedXSendfileDownload(t *testing.T, contentFilename string, filePath string) {
	// Prepare test server and backend
	ts := testhelper.TestServerWithHandler(regexp.MustCompile(`.`), http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		log.WithFields(log.Fields{"method": r.Method, "url": r.URL}).Info("UPSTREAM")

		assert.Equal(t, "X-Sendfile", r.Header.Get("X-Sendfile-Type"))

		w.Header().Set("Content-Disposition", fmt.Sprintf(`attachment; filename="%s"`, contentFilename))
		w.WriteHeader(200)
		fmt.Fprint(w, "Denied")
	}))
	defer ts.Close()
	ws := startWorkhorseServer(t, ts.URL)

	resp, err := http.Get(fmt.Sprintf("%s/%s", ws.URL, filePath))
	require.NoError(t, err)

	requireAttachmentName(t, resp, contentFilename)

	actual, err := io.ReadAll(resp.Body)
	require.NoError(t, err, "read body")
	require.NoError(t, resp.Body.Close())

	require.Equal(t, []byte("Denied"), actual, "response body")
}

func requireAttachmentName(t *testing.T, resp *http.Response, filename string) {
	mediaType, params, err := mime.ParseMediaType(resp.Header.Get("Content-Disposition"))
	require.NoError(t, err)

	require.Equal(t, "attachment", mediaType)
	require.Equal(t, filename, params["filename"], "filename")
}
