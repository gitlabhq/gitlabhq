package zipartifacts

import (
	"archive/zip"
	"context"
	"fmt"
	"io"
	"net/http"
	"os"
	"path/filepath"
	"strings"

	"gitlab.com/gitlab-org/gitlab/workhorse/internal/httprs"
	"gitlab.com/gitlab-org/gitlab/workhorse/internal/transport"

	"gitlab.com/gitlab-org/labkit/mask"
)

var httpClient = &http.Client{
	Transport: transport.NewRestrictedTransport(
		transport.WithDisabledCompression(), // To avoid bugs when serving compressed files from object storage
	),
}

type archive struct {
	reader io.ReaderAt
	size   int64
}

// OpenArchive will open a zip.Reader from a local path or a remote object store URL
// in case of remote url it will make use of ranged requestes to support seeking.
// If the path do not exists error will be ErrArchiveNotFound,
// if the file isn't a zip archive error will be ErrNotAZip
func OpenArchive(ctx context.Context, archivePath string) (*zip.Reader, error) {
	archive, err := openArchiveLocation(ctx, archivePath)
	if err != nil {
		return nil, err
	}

	return openZipReader(archive.reader, archive.size)
}

// OpenArchiveWithReaderFunc opens a zip.Reader from either local path or a
// remote object, similarly to OpenArchive function. The difference is that it
// allows passing a readerFunc that takes a io.ReaderAt that is either going to
// be os.File or a custom reader we use to read from object storage. The
// readerFunc can augment the archive reader and return a type that satisfies
// io.ReaderAt.
func OpenArchiveWithReaderFunc(ctx context.Context, location string, readerFunc func(io.ReaderAt, int64) io.ReaderAt) (*zip.Reader, error) {
	archive, err := openArchiveLocation(ctx, location)
	if err != nil {
		return nil, err
	}

	return openZipReader(readerFunc(archive.reader, archive.size), archive.size)
}

func openArchiveLocation(ctx context.Context, location string) (*archive, error) {
	if isURL(location) {
		return openHTTPArchive(ctx, location)
	}

	return openFileArchive(ctx, location)
}

func isURL(path string) bool {
	return strings.HasPrefix(path, "http://") || strings.HasPrefix(path, "https://")
}

func openHTTPArchive(ctx context.Context, archivePath string) (*archive, error) {
	scrubbedArchivePath := mask.URL(archivePath)
	req, err := http.NewRequest(http.MethodGet, archivePath, nil)
	if err != nil {
		return nil, fmt.Errorf("can't create HTTP GET %q: %v", scrubbedArchivePath, err)
	}
	req = req.WithContext(ctx)

	resp, err := httpClient.Do(req.WithContext(ctx))
	switch {
	case err != nil:
		return nil, fmt.Errorf("HTTP GET %q: %v", scrubbedArchivePath, err)
	case resp.StatusCode == http.StatusNotFound:
		return nil, ErrorCode[CodeArchiveNotFound]
	case resp.StatusCode != http.StatusOK:
		return nil, fmt.Errorf("HTTP GET %q: %d: %v", scrubbedArchivePath, resp.StatusCode, resp.Status)
	}

	rs := httprs.NewHTTPReadSeeker(resp, httpClient)

	go func() {
		<-ctx.Done()
		_ = resp.Body.Close()
		_ = rs.Close()
	}()

	return &archive{reader: rs, size: resp.ContentLength}, nil
}

func openFileArchive(ctx context.Context, archivePath string) (*archive, error) {
	cleanArchivePath := filepath.Clean(archivePath)
	file, err := os.Open(cleanArchivePath)
	if err != nil {
		if os.IsNotExist(err) {
			return nil, ErrorCode[CodeArchiveNotFound]
		}
	}

	go func() {
		<-ctx.Done()
		// We close the archive from this goroutine so that we can safely return a *zip.Reader instead of a *zip.ReadCloser
		if err = file.Close(); err != nil {
			fmt.Printf("Error closing archive: %v\n", err)
		}
	}()

	stat, err := file.Stat()
	if err != nil {
		return nil, err
	}

	return &archive{reader: file, size: stat.Size()}, nil
}

func openZipReader(archive io.ReaderAt, size int64) (*zip.Reader, error) {
	reader, err := zip.NewReader(archive, size)
	if err != nil {
		return nil, ErrorCode[CodeNotZip]
	}

	return reader, nil
}
