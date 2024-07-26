/*
In this file we handle 'git archive' downloads
*/

package git

import (
	"fmt"
	"io"
	"net/http"
	"os"
	"path"
	"path/filepath"
	"regexp"
	"time"

	"google.golang.org/protobuf/proto"

	"github.com/prometheus/client_golang/prometheus"
	"github.com/prometheus/client_golang/prometheus/promauto"

	"gitlab.com/gitlab-org/gitaly/v16/proto/go/gitalypb"

	"gitlab.com/gitlab-org/gitlab/workhorse/internal/api"
	"gitlab.com/gitlab-org/gitlab/workhorse/internal/gitaly"
	"gitlab.com/gitlab-org/gitlab/workhorse/internal/helper/fail"
	"gitlab.com/gitlab-org/gitlab/workhorse/internal/log"
	"gitlab.com/gitlab-org/gitlab/workhorse/internal/senddata"
)

type archive struct{ senddata.Prefix }
type archiveParams struct {
	ArchivePath       string
	ArchivePrefix     string
	CommitId          string
	GitalyServer      api.GitalyServer
	GitalyRepository  gitalypb.Repository
	DisableCache      bool
	GetArchiveRequest []byte
}

var (
	SendArchive     = &archive{"git-archive:"}
	gitArchiveCache = promauto.NewCounterVec(
		prometheus.CounterOpts{
			Name: "gitlab_workhorse_git_archive_cache",
			Help: "Cache hits and misses for 'git archive' streaming",
		},
		[]string{"result"},
	)
)

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
	archiveFilename := path.Base(params.ArchivePath)

	if cacheEnabled {
		cachedArchive, err := os.Open(params.ArchivePath)
		if err == nil {
			defer cachedArchive.Close()
			gitArchiveCache.WithLabelValues("hit").Inc()
			setArchiveHeaders(w, format, archiveFilename)
			// Even if somebody deleted the cachedArchive from disk since we opened
			// the file, Unix file semantics guarantee we can still read from the
			// open file in this process.
			http.ServeContent(w, r, "", time.Unix(0, 0), cachedArchive)
			return
		}
	}

	gitArchiveCache.WithLabelValues("miss").Inc()

	var tempFile *os.File
	var err error

	if cacheEnabled {
		// We assume the tempFile has a unique name so that concurrent requests are
		// safe. We create the tempfile in the same directory as the final cached
		// archive we want to create so that we can use an atomic link(2) operation
		// to finalize the cached archive.
		tempFile, err = prepareArchiveTempfile(path.Dir(params.ArchivePath), archiveFilename)
		if err != nil {
			fail.Request(w, r, fmt.Errorf("SendArchive: create tempfile: %v", err))
			return
		}
		defer tempFile.Close()
		defer os.Remove(tempFile.Name())
	}

	var archiveReader io.Reader

	archiveReader, err = handleArchiveWithGitaly(r, &params, format)
	if err != nil {
		fail.Request(w, r, fmt.Errorf("operations.GetArchive: %v", err))
		return
	}

	reader := archiveReader
	if cacheEnabled {
		reader = io.TeeReader(archiveReader, tempFile)
	}

	// Start writing the response
	setArchiveHeaders(w, format, archiveFilename)

	// According to https://github.com/golang/go/blob/go1.22.4/src/net/http/server.go#L119-L120:
	//
	// 	  If [ResponseWriter.WriteHeader] has not yet been called, Write calls
	// 	  WriteHeader(http.StatusOK) before writing the data.
	//
	// For io.Copy() below, ResponseWriter.WriteHeader(StatusOK) is ultimately called at
	// https://github.com/golang/go/blob/go1.22.4/src/net/http/server.go#L1639 (actually
	// https://gitlab.com/gitlab-org/gitlab/-/blob/4f89a18e85ea039cc52e7308d46d62566d54d70b/workhorse/internal/helper/countingresponsewriter.go#L32)
	// which means we're stuck always returning a HTTP 200, even if io.Copy() errors.
	w.WriteHeader(http.StatusOK)

	if _, err := io.Copy(w, reader); err != nil {
		log.WithRequest(r).WithError(&copyError{fmt.Errorf("SendArchive: copy 'git archive' output: %v", err)}).Error()
		return
	}

	if cacheEnabled {
		err := finalizeCachedArchive(tempFile, params.ArchivePath)
		if err != nil {
			log.WithRequest(r).WithError(fmt.Errorf("SendArchive: finalize cached archive: %v", err)).Error()
			return
		}
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
			CommitId:   params.CommitId,
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
