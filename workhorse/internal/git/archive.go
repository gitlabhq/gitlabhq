/*
In this file we handle 'git archive' downloads
*/

package git

import (
	"fmt"
	"io"
	"io/ioutil"
	"net/http"
	"os"
	"path"
	"path/filepath"
	"regexp"
	"time"

	"github.com/golang/protobuf/proto" //lint:ignore SA1019 https://gitlab.com/gitlab-org/gitlab-workhorse/-/issues/274

	"github.com/prometheus/client_golang/prometheus"
	"github.com/prometheus/client_golang/prometheus/promauto"

	"gitlab.com/gitlab-org/gitaly/v14/proto/go/gitalypb"

	"gitlab.com/gitlab-org/gitlab-workhorse/internal/gitaly"
	"gitlab.com/gitlab-org/gitlab-workhorse/internal/helper"
	"gitlab.com/gitlab-org/gitlab-workhorse/internal/log"
	"gitlab.com/gitlab-org/gitlab-workhorse/internal/senddata"
)

type archive struct{ senddata.Prefix }
type archiveParams struct {
	ArchivePath       string
	ArchivePrefix     string
	CommitId          string
	GitalyServer      gitaly.Server
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
		helper.Fail500(w, r, fmt.Errorf("SendArchive: unpack sendData: %v", err))
		return
	}

	urlPath := r.URL.Path
	format, ok := parseBasename(filepath.Base(urlPath))
	if !ok {
		helper.Fail500(w, r, fmt.Errorf("SendArchive: invalid format: %s", urlPath))
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
			helper.Fail500(w, r, fmt.Errorf("SendArchive: create tempfile: %v", err))
			return
		}
		defer tempFile.Close()
		defer os.Remove(tempFile.Name())
	}

	var archiveReader io.Reader

	archiveReader, err = handleArchiveWithGitaly(r, params, format)
	if err != nil {
		helper.Fail500(w, r, fmt.Errorf("operations.GetArchive: %v", err))
		return
	}

	reader := archiveReader
	if cacheEnabled {
		reader = io.TeeReader(archiveReader, tempFile)
	}

	// Start writing the response
	setArchiveHeaders(w, format, archiveFilename)
	w.WriteHeader(200) // Don't bother with HTTP 500 from this point on, just return
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

func handleArchiveWithGitaly(r *http.Request, params archiveParams, format gitalypb.GetArchiveRequest_Format) (io.Reader, error) {
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
	return ioutil.TempFile(dir, prefix)
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
