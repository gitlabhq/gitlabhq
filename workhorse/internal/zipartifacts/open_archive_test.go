package zipartifacts

import (
	"archive/zip"
	"bytes"
	"context"
	"fmt"
	"io"
	"net/http"
	"net/http/httptest"
	"os"
	"path/filepath"
	"testing"

	"github.com/stretchr/testify/assert"
	"github.com/stretchr/testify/require"
)

func createArchive(t *testing.T, dir string) (map[string][]byte, int64) {
	f, err := os.Create(filepath.Join(dir, "test.zip"))
	require.NoError(t, err)
	defer f.Close()
	zw := zip.NewWriter(f)

	entries := make(map[string][]byte)
	for _, size := range []int{0, 32 * 1024, 128 * 1024, 5 * 1024 * 1024} {
		entryName := fmt.Sprintf("file_%d", size)
		entries[entryName] = bytes.Repeat([]byte{'z'}, size)

		w, entryNameErr := zw.Create(entryName)
		require.NoError(t, entryNameErr)

		_, err = w.Write(entries[entryName])
		require.NoError(t, err)
	}

	require.NoError(t, zw.Close())
	fi, err := f.Stat()
	require.NoError(t, err)
	require.NoError(t, f.Close())

	return entries, fi.Size()
}

func TestOpenHTTPArchive(t *testing.T) {
	dir := t.TempDir()
	entries, _ := createArchive(t, dir)

	srv := httptest.NewServer(http.FileServer(http.Dir(dir)))
	defer srv.Close()

	ctx, cancel := context.WithCancel(context.Background())
	defer cancel()

	zr, err := OpenArchive(ctx, srv.URL+"/test.zip")
	require.NoError(t, err)
	require.Len(t, zr.File, len(entries))

	for _, zf := range zr.File {
		entry, ok := entries[zf.Name]
		require.True(t, ok)

		r, err := zf.Open()
		require.NoError(t, err)

		contents, err := io.ReadAll(r)
		require.NoError(t, err)
		require.Equal(t, entry, contents)

		require.NoError(t, r.Close())
	}
}

func TestMinimalRangeRequests(t *testing.T) {
	dir := t.TempDir()
	entries, archiveSize := createArchive(t, dir)

	mux := http.NewServeMux()

	var ranges []string
	mux.HandleFunc("/", func(rw http.ResponseWriter, r *http.Request) {
		rangeHdr := r.Header.Get("Range")
		if rangeHdr == "" {
			rw.Header().Add("Content-Length", fmt.Sprintf("%d", archiveSize))
			return
		}

		ranges = append(ranges, rangeHdr)
		http.FileServer(http.Dir(dir)).ServeHTTP(rw, r)
	})

	srv := httptest.NewServer(mux)
	defer srv.Close()

	ctx, cancel := context.WithCancel(context.Background())
	defer cancel()

	zr, err := OpenArchive(ctx, srv.URL+"/test.zip")
	require.NoError(t, err)
	require.Len(t, zr.File, len(entries))

	require.Len(t, ranges, 2, "range requests should be minimal")
	require.NotContains(t, ranges, "bytes=0-", "range request should not request from zero")

	for _, zf := range zr.File {
		r, err := zf.Open()
		require.NoError(t, err)

		_, err = io.Copy(io.Discard, r)
		require.NoError(t, err)

		require.NoError(t, r.Close())
	}

	// ensure minimal requests: https://gitlab.com/gitlab-org/gitlab/-/issues/340778
	require.Len(t, ranges, 3, "range requests should be minimal")
	require.Contains(t, ranges, "bytes=0-")
}

func TestOpenHTTPArchiveNotSendingAcceptEncodingHeader(t *testing.T) {
	requestHandler := func(w http.ResponseWriter, r *http.Request) {
		assert.Equal(t, "GET", r.Method)
		assert.Nil(t, r.Header["Accept-Encoding"])
		w.WriteHeader(http.StatusOK)
	}

	srv := httptest.NewServer(http.HandlerFunc(requestHandler))
	defer srv.Close()

	ctx, cancel := context.WithCancel(context.Background())
	defer cancel()

	OpenArchive(ctx, srv.URL)
}
