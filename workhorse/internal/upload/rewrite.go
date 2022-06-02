package upload

import (
	"context"
	"errors"
	"fmt"
	"io"
	"io/ioutil"
	"mime"
	"mime/multipart"
	"net/http"
	"net/textproto"
	"os"
	"path/filepath"
	"strings"

	"github.com/prometheus/client_golang/prometheus"
	"github.com/prometheus/client_golang/prometheus/promauto"
	"golang.org/x/image/tiff"

	"gitlab.com/gitlab-org/gitlab/workhorse/internal/log"

	"gitlab.com/gitlab-org/gitlab/workhorse/internal/api"
	"gitlab.com/gitlab-org/gitlab/workhorse/internal/lsif_transformer/parser"
	"gitlab.com/gitlab-org/gitlab/workhorse/internal/upload/destination"
	"gitlab.com/gitlab-org/gitlab/workhorse/internal/upload/exif"
)

const maxFilesAllowed = 10

// ErrInjectedClientParam means that the client sent a parameter that overrides one of our own fields
var (
	ErrInjectedClientParam  = errors.New("injected client parameter")
	ErrTooManyFilesUploaded = fmt.Errorf("upload request contains more than %v files", maxFilesAllowed)
)

var (
	multipartUploadRequests = promauto.NewCounterVec(
		prometheus.CounterOpts{

			Name: "gitlab_workhorse_multipart_upload_requests",
			Help: "How many multipart upload requests have been processed by gitlab-workhorse. Partitioned by type.",
		},
		[]string{"type"},
	)

	multipartFileUploadBytes = promauto.NewCounterVec(
		prometheus.CounterOpts{
			Name: "gitlab_workhorse_multipart_upload_bytes",
			Help: "How many disk bytes of multipart file parts have been successfully written by gitlab-workhorse. Partitioned by type.",
		},
		[]string{"type"},
	)

	multipartFiles = promauto.NewCounterVec(
		prometheus.CounterOpts{
			Name: "gitlab_workhorse_multipart_upload_files",
			Help: "How many multipart file parts have been processed by gitlab-workhorse. Partitioned by type.",
		},
		[]string{"type"},
	)
)

type rewriter struct {
	writer *multipart.Writer
	fileAuthorizer
	Preparer
	filter          MultipartFormProcessor
	finalizedFields map[string]bool
}

func rewriteFormFilesFromMultipart(r *http.Request, writer *multipart.Writer, filter MultipartFormProcessor, fa fileAuthorizer, preparer Preparer) error {
	// Create multipart reader
	reader, err := r.MultipartReader()
	if err != nil {
		if err == http.ErrNotMultipart {
			// We want to be able to recognize http.ErrNotMultipart elsewhere so no fmt.Errorf
			return http.ErrNotMultipart
		}
		return fmt.Errorf("get multipart reader: %v", err)
	}

	multipartUploadRequests.WithLabelValues(filter.Name()).Inc()

	rew := &rewriter{
		writer:          writer,
		fileAuthorizer:  fa,
		Preparer:        preparer,
		filter:          filter,
		finalizedFields: make(map[string]bool),
	}

	for {
		p, err := reader.NextPart()
		if err != nil {
			if err == io.EOF {
				break
			}
			return err
		}

		name, filename := parseAndNormalizeContentDisposition(p.Header)

		if name == "" {
			continue
		}

		if rew.finalizedFields[name] {
			return ErrInjectedClientParam
		}

		if filename != "" {
			err = rew.handleFilePart(r, name, p)
		} else {
			err = rew.copyPart(r.Context(), name, p)
		}

		if err != nil {
			return err
		}
	}

	return nil
}

func parseAndNormalizeContentDisposition(header textproto.MIMEHeader) (string, string) {
	const key = "Content-Disposition"
	mediaType, params, _ := mime.ParseMediaType(header.Get(key))
	header.Set(key, mime.FormatMediaType(mediaType, params))
	return params["name"], params["filename"]
}

func (rew *rewriter) handleFilePart(r *http.Request, name string, p *multipart.Part) error {
	if rew.filter.Count() >= maxFilesAllowed {
		return ErrTooManyFilesUploaded
	}

	multipartFiles.WithLabelValues(rew.filter.Name()).Inc()

	filename := filepath.Base(p.FileName())

	if strings.Contains(filename, "/") || filename == "." || filename == ".." {
		return fmt.Errorf("illegal filename: %q", filename)
	}

	apiResponse, err := rew.AuthorizeFile(r)
	if err != nil {
		return err
	}
	opts, err := rew.Prepare(apiResponse)
	if err != nil {
		return err
	}

	var inputReader io.ReadCloser
	ctx := r.Context()
	if imageType := exif.FileTypeFromSuffix(filename); imageType != exif.TypeUnknown {
		inputReader, err = handleExifUpload(ctx, p, filename, imageType)
		if err != nil {
			return err
		}
	} else if apiResponse.ProcessLsif {
		inputReader, err = handleLsifUpload(ctx, p, opts.LocalTempPath, filename)
		if err != nil {
			return err
		}
	} else {
		inputReader = ioutil.NopCloser(p)
	}

	defer inputReader.Close()

	fh, err := destination.Upload(ctx, inputReader, -1, filename, opts)
	if err != nil {
		switch err {
		case destination.ErrEntityTooLarge, exif.ErrRemovingExif:
			return err
		default:
			return fmt.Errorf("persisting multipart file: %v", err)
		}
	}

	fields, err := fh.GitLabFinalizeFields(name)
	if err != nil {
		return fmt.Errorf("failed to finalize fields: %v", err)
	}

	for key, value := range fields {
		rew.writer.WriteField(key, value)
		rew.finalizedFields[key] = true
	}

	multipartFileUploadBytes.WithLabelValues(rew.filter.Name()).Add(float64(fh.Size))

	return rew.filter.ProcessFile(ctx, name, fh, rew.writer)
}

func handleExifUpload(ctx context.Context, r io.Reader, filename string, imageType exif.FileType) (io.ReadCloser, error) {
	tmpfile, err := ioutil.TempFile("", "exifremove")
	if err != nil {
		return nil, err
	}
	go func() {
		<-ctx.Done()
		tmpfile.Close()
	}()
	if err := os.Remove(tmpfile.Name()); err != nil {
		return nil, err
	}

	_, err = io.Copy(tmpfile, r)
	if err != nil {
		return nil, err
	}

	if _, err := tmpfile.Seek(0, io.SeekStart); err != nil {
		return nil, err
	}

	isValidType := false
	switch imageType {
	case exif.TypeJPEG:
		isValidType = isJPEG(tmpfile)
	case exif.TypeTIFF:
		isValidType = isTIFF(tmpfile)
	}

	if _, err := tmpfile.Seek(0, io.SeekStart); err != nil {
		return nil, err
	}

	if !isValidType {
		log.WithContextFields(ctx, log.Fields{
			"filename":  filename,
			"imageType": imageType,
		}).Info("invalid content type, not running exiftool")

		return tmpfile, nil
	}

	log.WithContextFields(ctx, log.Fields{
		"filename": filename,
	}).Info("running exiftool to remove any metadata")

	cleaner, err := exif.NewCleaner(ctx, tmpfile)
	if err != nil {
		return nil, err
	}

	return cleaner, nil
}

func isTIFF(r io.Reader) bool {
	_, err := tiff.DecodeConfig(r)
	if err == nil {
		return true
	}

	if _, unsupported := err.(tiff.UnsupportedError); unsupported {
		return true
	}

	return false
}

func isJPEG(r io.Reader) bool {
	// Only the first 512 bytes are used to sniff the content type.
	buf, err := ioutil.ReadAll(io.LimitReader(r, 512))
	if err != nil {
		return false
	}

	return http.DetectContentType(buf) == "image/jpeg"
}

func handleLsifUpload(ctx context.Context, reader io.Reader, tempPath, filename string) (io.ReadCloser, error) {
	parserConfig := parser.Config{
		TempPath: tempPath,
	}

	return parser.NewParser(ctx, reader, parserConfig)
}

func (rew *rewriter) copyPart(ctx context.Context, name string, p *multipart.Part) error {
	np, err := rew.writer.CreatePart(p.Header)
	if err != nil {
		return fmt.Errorf("create multipart field: %v", err)
	}

	if _, err := io.Copy(np, p); err != nil {
		return fmt.Errorf("duplicate multipart field: %v", err)
	}

	if err := rew.filter.ProcessField(ctx, name, rew.writer); err != nil {
		return fmt.Errorf("process multipart field: %v", err)
	}

	return nil
}

type fileAuthorizer interface {
	AuthorizeFile(*http.Request) (*api.Response, error)
}

type eagerAuthorizer struct{ response *api.Response }

func (ea *eagerAuthorizer) AuthorizeFile(r *http.Request) (*api.Response, error) {
	return ea.response, nil
}

var _ fileAuthorizer = &eagerAuthorizer{}

type apiAuthorizer struct {
	api *api.API
}

func (aa *apiAuthorizer) AuthorizeFile(r *http.Request) (*api.Response, error) {
	return aa.api.PreAuthorizeFixedPath(
		r,
		"POST",
		"/api/v4/internal/workhorse/authorize_upload",
	)
}

var _ fileAuthorizer = &apiAuthorizer{}

type testAuthorizer struct {
	test   fileAuthorizer
	actual fileAuthorizer
}

func (ta *testAuthorizer) AuthorizeFile(r *http.Request) (*api.Response, error) {
	logger := log.WithRequest(r)
	if response, err := ta.test.AuthorizeFile(r); err != nil {
		logger.WithError(err).Error("test api preauthorize request failed")
	} else {
		logger.WithFields(log.Fields{
			"temp_path": response.TempPath,
		}).Info("test api preauthorize request")
	}

	return ta.actual.AuthorizeFile(r)
}
