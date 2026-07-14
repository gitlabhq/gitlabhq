/*
In this file we handle 'git archive' downloads
*/

package git

import (
	"bufio"
	"fmt"
	"io"
	"net/http"
	"os"
	"path"
	"path/filepath"
	"regexp"
	"time"

	"google.golang.org/grpc/codes"
	"google.golang.org/grpc/status"
	"google.golang.org/protobuf/proto"

	"github.com/prometheus/client_golang/prometheus"
	"github.com/prometheus/client_golang/prometheus/promauto"

	"gitlab.com/gitlab-org/gitaly/v18/proto/go/gitalypb"

	"gitlab.com/gitlab-org/gitlab/workhorse/internal/api"
	"gitlab.com/gitlab-org/gitlab/workhorse/internal/gitaly"
	"gitlab.com/gitlab-org/gitlab/workhorse/internal/helper/fail"
	"gitlab.com/gitlab-org/gitlab/workhorse/internal/log"
	"gitlab.com/gitlab-org/gitlab/workhorse/internal/senddata"
)

type archive struct {
	senddata.Prefix
	cleaner *archiveCleaner
}

type archiveParams struct {
	ArchivePath       string
	ArchivePrefix     string
	CommitID          string
	GitalyServer      api.GitalyServer
	GitalyRepository  gitalypb.Repository
	DisableCache      bool
	GetArchiveRequest []byte
	StoragePath       string
	UseArchiveCleaner bool
}

var (
	// SendArchive sends a Git archive to the client, retrieving from the local disk cache if available.
	SendArchive     = newArchive("git-archive:")
	gitArchiveCache = promauto.NewCounterVec(
		prometheus.CounterOpts{
			Name: "gitlab_workhorse_git_archive_cache",
			Help: "Cache hits and misses for 'git archive' streaming",
		},
		[]string{"result"},
	)
)

func newArchive(prefix string) *archive {
	return &archive{
		Prefix:  senddata.Prefix(prefix),
		cleaner: newArchiveCleaner(),
	}
}

func (a *archive) Inject(w http.ResponseWriter, r *http.Request, sendData string) {
	var params archiveParams
	if err := a.Unpack(&params, sendData); err != nil {
		fail.Request(w, r, fmt.Errorf("SendArchive: unpack sendData: %v", err))
		return
	}

	urlPath := r.URL.Path
	format, ok := parseBasename(filepath.Base(urlPath))
	if !ok {
		fail.Request(w, r, fmt.Errorf("SendArchive: invalid format: %s", urlPath))
		return
	}

	cacheEnabled := !params.DisableCache

	if cacheEnabled && a.tryServeCachedArchive(w, r, &params, format) {
		return
	}

	a.serveArchiveFromGitaly(w, r, &params, format, cacheEnabled)
}

func (a *archive) tryServeCachedArchive(w http.ResponseWriter, r *http.Request, params *archiveParams, format gitalypb.GetArchiveRequest_Format) bool {
	archiveFilename := path.Base(params.ArchivePath)
	if params.UseArchiveCleaner {
		a.cleaner.RegisterPath(params.StoragePath)
	}

	cachedArchive, err := os.Open(params.ArchivePath)
	if err != nil {
		return false
	}
	defer func() {
		if err := cachedArchive.Close(); err != nil {
			log.WithError(err).Error("SendArchive: failed to close cached archive")
		}
	}()

	gitArchiveCache.WithLabelValues("hit").Inc()
	setArchiveHeaders(w, format, archiveFilename)
	// Even if somebody deleted the cachedArchive from disk since we opened
	// the file, Unix file semantics guarantee we can still read from the
	// open file in this process.
	http.ServeContent(w, r, "", time.Unix(0, 0), cachedArchive)
	return true
}

func (a *archive) serveArchiveFromGitaly(w http.ResponseWriter, r *http.Request, params *archiveParams, format gitalypb.GetArchiveRequest_Format, cacheEnabled bool) {
	archiveFilename := path.Base(params.ArchivePath)
	gitArchiveCache.WithLabelValues("miss").Inc()

	archiveReader, err := handleArchiveWithGitaly(r, params, format)
	if err != nil {
		failArchive(w, r, err, fmt.Errorf("SendArchive: GetArchive: %w", err))
		return
	}

	// The Gitaly GetArchive stream is lazy: an immediate RPC error (for example,
	// FailedPrecondition when the requested path does not exist) only surfaces on
	// the first Read. Force that first Read here, before we commit a cacheable
	// 200 response, so such failures are returned as a non-cacheable error status
	// instead of a well-formed but empty 200 that caching proxies happily store
	// and revalidate forever. See https://gitlab.com/gitlab-org/gitlab/-/issues/604046.
	//
	// io.EOF (an empty stream) is treated as an error too: a valid archive always
	// has content (a zip end-of-central-directory record, tar trailer, gzip
	// header), so a zero-byte archive is always malformed and must not be cached.
	bufReader := bufio.NewReader(archiveReader)
	if _, peekErr := bufReader.Peek(1); peekErr != nil {
		failArchive(w, r, peekErr, fmt.Errorf("SendArchive: read 'git archive' output: %w", peekErr))
		return
	}

	reader := io.Reader(bufReader)

	var tempFile *os.File
	if cacheEnabled {
		tempFile, err = prepareArchiveTempfile(path.Dir(params.ArchivePath), archiveFilename)
		if err != nil {
			failArchive(w, r, err, fmt.Errorf("SendArchive: create tempfile: %w", err))
			return
		}
		defer cleanupTempFile(tempFile)

		reader = io.TeeReader(bufReader, tempFile)
	}

	setArchiveHeaders(w, format, archiveFilename)
	w.WriteHeader(http.StatusOK)

	if _, err := io.Copy(w, reader); err != nil {
		log.WithRequest(r).WithError(&copyError{fmt.Errorf("SendArchive: copy 'git archive' output: %v", err)}).Error()

		// The status code and part of the body have already been sent, so we
		// cannot signal the failure with an error status. Returning normally would
		// cleanly terminate the (chunked) response, producing a well-formed but
		// truncated 200 that caching proxies may store. Aborting resets the
		// connection so the truncated response is treated as a failure and is not
		// cached. http.ErrAbortHandler is recovered by net/http and by Workhorse's
		// recovery middleware, so it does not crash the process. The deferred
		// cleanupTempFile still runs, so no partial archive is left in the cache.
		panic(http.ErrAbortHandler)
	}

	if cacheEnabled {
		if err := finalizeCachedArchive(tempFile, params.ArchivePath); err != nil {
			log.WithRequest(r).WithError(fmt.Errorf("SendArchive: finalize cached archive: %v", err)).Error()
		}
	}
}

// failArchive responds to an archive request that failed before any body was
// sent. The HTTP status is derived from statusErr (the raw Gitaly gRPC error:
// a missing path is a client-facing 404, an unavailable backend is a 503),
// while logErr is the wrapped error used for logging. The caching headers set
// upstream by Rails are cleared so the failure is never cached or revalidated
// into a stuck response. See https://gitlab.com/gitlab-org/gitlab/-/issues/604046.
func failArchive(w http.ResponseWriter, r *http.Request, statusErr, logErr error) {
	w.Header().Set("Cache-Control", "no-store")
	w.Header().Del("Etag")
	w.Header().Del("Last-Modified")
	w.Header().Del("Expires")

	fail.Request(w, r, logErr, fail.WithStatus(archiveErrorStatus(statusErr)))
}

// archiveErrorStatus maps a Gitaly gRPC error to an HTTP status code. It is
// called with the raw error so it does not depend on status.FromError being
// able to unwrap a wrapped error.
func archiveErrorStatus(err error) int {
	switch status.Code(err) {
	case codes.NotFound, codes.InvalidArgument:
		// The requested ref/path does not exist or was invalid: a client-facing
		// not-found.
		return http.StatusNotFound
	case codes.FailedPrecondition:
		// Gitaly's GetArchive returns FailedPrecondition specifically when the
		// requested path, an exclude path, or the (empty) root tree does not exist
		// (see validateGetArchivePrecondition in Gitaly's repository/archive.go),
		// which for an archive download is a client-facing not-found. This mapping
		// is intentionally tied to that current Gitaly behavior: FailedPrecondition
		// is a broad gRPC code, so if Gitaly ever returns it for an unrelated
		// backend-state failure, narrow this case so such errors are not masked as
		// a 404.
		return http.StatusNotFound
	case codes.Unavailable, codes.DeadlineExceeded, codes.Canceled:
		// The backend could not be reached or timed out: a transient server error.
		return http.StatusServiceUnavailable
	default:
		return http.StatusInternalServerError
	}
}

func cleanupTempFile(tempFile *os.File) {
	// Ignore error, this may have already been closed with finalizeCachedArchive
	_ = tempFile.Close()

	if err := os.Remove(tempFile.Name()); err != nil {
		log.WithError(err).Error("SendArchive: failed to remove tempfile")
	}
}

func handleArchiveWithGitaly(r *http.Request, params *archiveParams, format gitalypb.GetArchiveRequest_Format) (io.Reader, error) {
	var request *gitalypb.GetArchiveRequest
	ctx, c, err := gitaly.NewRepositoryClient(r.Context(), params.GitalyServer)

	if err != nil {
		return nil, err
	}

	if params.GetArchiveRequest != nil {
		request = &gitalypb.GetArchiveRequest{}

		if err := proto.Unmarshal(params.GetArchiveRequest, request); err != nil {
			return nil, fmt.Errorf("unmarshal GetArchiveRequest: %v", err)
		}
	} else {
		request = &gitalypb.GetArchiveRequest{
			Repository: &params.GitalyRepository,
			CommitId:   params.CommitID,
			Prefix:     params.ArchivePrefix,
			Format:     format,
		}
	}

	return c.ArchiveReader(ctx, request)
}

func setArchiveHeaders(w http.ResponseWriter, format gitalypb.GetArchiveRequest_Format, archiveFilename string) {
	w.Header().Del("Content-Length")
	w.Header().Set("Content-Disposition", fmt.Sprintf(`attachment; filename="%s"`, archiveFilename))
	// Caching proxies usually don't cache responses with Set-Cookie header
	// present because it implies user-specific data, which is not the case
	// for repository archives.
	w.Header().Del("Set-Cookie")
	if format == gitalypb.GetArchiveRequest_ZIP {
		w.Header().Set("Content-Type", "application/zip")
	} else {
		w.Header().Set("Content-Type", "application/octet-stream")
	}
	w.Header().Set("Content-Transfer-Encoding", "binary")
}

func prepareArchiveTempfile(dir string, prefix string) (*os.File, error) {
	if err := os.MkdirAll(dir, 0700); err != nil {
		return nil, err
	}
	return os.CreateTemp(dir, prefix)
}

func finalizeCachedArchive(tempFile *os.File, archivePath string) error {
	if err := tempFile.Close(); err != nil {
		return err
	}
	if err := os.Link(tempFile.Name(), archivePath); err != nil && !os.IsExist(err) {
		return err
	}

	return nil
}

var (
	patternZip    = regexp.MustCompile(`\.zip$`)
	patternTar    = regexp.MustCompile(`\.tar$`)
	patternTarGz  = regexp.MustCompile(`\.(tar\.gz|tgz|gz)$`)
	patternTarBz2 = regexp.MustCompile(`\.(tar\.bz2|tbz|tbz2|tb2|bz2)$`)
)

func parseBasename(basename string) (gitalypb.GetArchiveRequest_Format, bool) {
	var format gitalypb.GetArchiveRequest_Format

	switch {
	case (basename == "archive"):
		format = gitalypb.GetArchiveRequest_TAR_GZ
	case patternZip.MatchString(basename):
		format = gitalypb.GetArchiveRequest_ZIP
	case patternTar.MatchString(basename):
		format = gitalypb.GetArchiveRequest_TAR
	case patternTarGz.MatchString(basename):
		format = gitalypb.GetArchiveRequest_TAR_GZ
	case patternTarBz2.MatchString(basename):
		format = gitalypb.GetArchiveRequest_TAR_BZ2
	default:
		return format, false
	}

	return format, true
}
