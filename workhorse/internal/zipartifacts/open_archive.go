package zipartifacts

import (
	"archive/zip"
	"context"
	"fmt"
	"io"
	"net"
	"net/http"
	"os"
	"strings"
	"time"

	"gitlab.com/gitlab-org/gitlab/workhorse/internal/httprs"

	"gitlab.com/gitlab-org/labkit/correlation"
	"gitlab.com/gitlab-org/labkit/mask"
	"gitlab.com/gitlab-org/labkit/tracing"
)

var httpClient = &http.Client{
	Transport: tracing.NewRoundTripper(correlation.NewInstrumentedRoundTripper(&http.Transport{
		Proxy: http.ProxyFromEnvironment,
		DialContext: (&net.Dialer{
			Timeout:   30 * time.Second,
			KeepAlive: 10 * time.Second,
		}).DialContext,
		IdleConnTimeout:       30 * time.Second,
		TLSHandshakeTimeout:   10 * time.Second,
		ExpectContinueTimeout: 10 * time.Second,
		ResponseHeaderTimeout: 30 * time.Second,
		DisableCompression:    true,
	})),
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
	if err != nil {
		return nil, fmt.Errorf("HTTP GET %q: %v", scrubbedArchivePath, err)
	} else if resp.StatusCode == http.StatusNotFound {
		return nil, ErrorCode[CodeArchiveNotFound]
	} else if resp.StatusCode != http.StatusOK {
		return nil, fmt.Errorf("HTTP GET %q: %d: %v", scrubbedArchivePath, resp.StatusCode, resp.Status)
	}

	rs := httprs.NewHttpReadSeeker(resp, httpClient)

	go func() {
		<-ctx.Done()
		resp.Body.Close()
		rs.Close()
	}()

	return &archive{reader: rs, size: resp.ContentLength}, nil
}

func openFileArchive(ctx context.Context, archivePath string) (*archive, error) {
	file, err := os.Open(archivePath)
	if err != nil {
		if os.IsNotExist(err) {
			return nil, ErrorCode[CodeArchiveNotFound]
		}
	}

	go func() {
		<-ctx.Done()
		// We close the archive from this goroutine so that we can safely return a *zip.Reader instead of a *zip.ReadCloser
		file.Close()
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
