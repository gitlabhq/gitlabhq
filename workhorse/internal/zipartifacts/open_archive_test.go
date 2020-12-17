package zipartifacts

import (
	"archive/zip"
	"context"
	"fmt"
	"io/ioutil"
	"net/http"
	"net/http/httptest"
	"os"
	"path/filepath"
	"testing"

	"github.com/stretchr/testify/require"
)

func TestOpenHTTPArchive(t *testing.T) {
	const (
		zipFile   = "test.zip"
		entryName = "hello.txt"
		contents  = "world"
		testRoot  = "testdata/public"
	)

	require.NoError(t, os.MkdirAll(testRoot, 0755))
	f, err := os.Create(filepath.Join(testRoot, zipFile))
	require.NoError(t, err, "create file")
	defer f.Close()

	zw := zip.NewWriter(f)
	w, err := zw.Create(entryName)
	require.NoError(t, err, "create zip entry")
	_, err = fmt.Fprint(w, contents)
	require.NoError(t, err, "write zip entry contents")
	require.NoError(t, zw.Close(), "close zip writer")
	require.NoError(t, f.Close(), "close file")

	srv := httptest.NewServer(http.FileServer(http.Dir(testRoot)))
	defer srv.Close()

	zr, err := OpenArchive(context.Background(), srv.URL+"/"+zipFile)
	require.NoError(t, err, "call OpenArchive")
	require.Len(t, zr.File, 1)

	zf := zr.File[0]
	require.Equal(t, entryName, zf.Name, "zip entry name")

	entry, err := zf.Open()
	require.NoError(t, err, "get zip entry reader")
	defer entry.Close()

	actualContents, err := ioutil.ReadAll(entry)
	require.NoError(t, err, "read zip entry contents")
	require.Equal(t, contents, string(actualContents), "compare zip entry contents")
}

func TestOpenHTTPArchiveNotSendingAcceptEncodingHeader(t *testing.T) {
	requestHandler := func(w http.ResponseWriter, r *http.Request) {
		require.Equal(t, "GET", r.Method)
		require.Nil(t, r.Header["Accept-Encoding"])
		w.WriteHeader(http.StatusOK)
	}

	srv := httptest.NewServer(http.HandlerFunc(requestHandler))
	defer srv.Close()

	OpenArchive(context.Background(), srv.URL)
}
