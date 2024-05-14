package upload

import (
	"context"
	"errors"
	"fmt"
	"io"
	"mime"
	"mime/multipart"
	"net/http"
	"net/textproto"
	"path/filepath"
	"strings"

	"github.com/prometheus/client_golang/prometheus"
	"github.com/prometheus/client_golang/prometheus/promauto"

	"gitlab.com/gitlab-org/gitlab/workhorse/internal/api"
	"gitlab.com/gitlab-org/gitlab/workhorse/internal/config"
	"gitlab.com/gitlab-org/gitlab/workhorse/internal/upload/destination"
	"gitlab.com/gitlab-org/gitlab/workhorse/internal/upload/exif"
)

const maxFilesAllowed = 10

// ErrInjectedClientParam means that the client sent a parameter that overrides one of our own fields
var (
	ErrInjectedClientParam    = errors.New("injected client parameter")
	ErrTooManyFilesUploaded   = fmt.Errorf("upload request contains more than %v files", maxFilesAllowed)
	ErrUnexpectedMultipartEOF = fmt.Errorf("unexpected EOF when reading multipart data")
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

func rewriteFormFilesFromMultipart(r *http.Request, writer *multipart.Writer, filter MultipartFormProcessor, fa fileAuthorizer, preparer Preparer, cfg *config.Config) error {
	// Create multipart reader
	reader, err := r.MultipartReader()
	if err != nil {
		// We want to be able to recognize these errors elsewhere so no fmt.Errorf
		return err
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
			// Unfortunately as described in https://github.com/golang/go/issues/54133,
			// we don't have a good way to determine the actual error cause of NextPart()
			// without an ugly string comparison.
			// io.EOF is treated differently from an unexpected EOF:
			// https://github.com/golang/go/blob/69d6c7b8ee62b4db5a8f6399e15f27d47b209a29/src/mime/multipart/multipart.go#L395-L405
			if err.Error() == "multipart: NextPart: EOF" {
				return ErrUnexpectedMultipartEOF
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
			err = rew.handleFilePart(r, name, p, cfg)
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

func (rew *rewriter) handleFilePart(r *http.Request, name string, p *multipart.Part, cfg *config.Config) error {
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

	ctx := r.Context()
	inputReader, err := rew.filter.TransformContents(ctx, filename, p)
	if err != nil {
		return err
	}
	defer func() {
		if err = inputReader.Close(); err != nil {
			fmt.Printf("error closing multipart file: %v", err)
		}
	}()

	fh, err := destination.Upload(ctx, inputReader, -1, filename, opts)
	if err != nil {
		switch err {
		case destination.ErrEntityTooLarge, exif.ErrRemovingExif:
			return err
		default:
			return fmt.Errorf("persisting multipart file: %w", err)
		}
	}

	fields, err := fh.GitLabFinalizeFields(name)
	if err != nil {
		return fmt.Errorf("failed to finalize fields: %v", err)
	}

	for key, value := range fields {
		if err := rew.writer.WriteField(key, value); err != nil {
			return err
		}
		rew.finalizedFields[key] = true
	}

	multipartFileUploadBytes.WithLabelValues(rew.filter.Name()).Add(float64(fh.Size))

	return rew.filter.ProcessFile(ctx, name, fh, rew.writer, cfg)
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

func (ea *eagerAuthorizer) AuthorizeFile(_ *http.Request) (*api.Response, error) {
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
