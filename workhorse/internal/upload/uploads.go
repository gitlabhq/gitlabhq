/*
Package upload provides functionality for handling file uploads in GitLab Workhorse.

It includes features for processing multipart requests, handling file destinations,
and extracting EXIF data from uploaded images.
*/
package upload

import (
	"bytes"
	"context"
	"errors"
	"fmt"
	"io"
	"mime/multipart"
	"net/http"
	"net/textproto"

	"github.com/golang-jwt/jwt/v5"

	"gitlab.com/gitlab-org/gitlab/workhorse/internal/api"
	"gitlab.com/gitlab-org/gitlab/workhorse/internal/config"
	"gitlab.com/gitlab-org/gitlab/workhorse/internal/helper/fail"
	"gitlab.com/gitlab-org/gitlab/workhorse/internal/upload/destination"
	"gitlab.com/gitlab-org/gitlab/workhorse/internal/upload/exif"
	"gitlab.com/gitlab-org/gitlab/workhorse/internal/zipartifacts"
)

// RewrittenFieldsHeader is the HTTP header used to indicate multipart form fields
// that have been rewritten by GitLab Workhorse.
const RewrittenFieldsHeader = "Gitlab-Workhorse-Multipart-Fields"

// PreAuthorizer provides methods for pre-authorizing multipart requests.
type PreAuthorizer interface {
	PreAuthorizeHandler(next api.HandleFunc, suffix string) http.Handler
}

// MultipartClaims represents the claims included in a JWT token used for multipart requests.
type MultipartClaims struct {
	RewrittenFields map[string]string `json:"rewritten_fields"`
	jwt.RegisteredClaims
}

// MultipartFormProcessor abstracts away implementation differences
// between generic MIME multipart file uploads and CI artifact uploads.
type MultipartFormProcessor interface {
	ProcessFile(ctx context.Context, formName string, file *destination.FileHandler, writer *multipart.Writer, cfg *config.Config) error
	ProcessField(ctx context.Context, formName string, writer *multipart.Writer) error
	Finalize(ctx context.Context) error
	Name() string
	Count() int
	TransformContents(ctx context.Context, filename string, r io.Reader) (io.ReadCloser, error)
}

// interceptMultipartFiles is the core of the implementation of
// Multipart.
func interceptMultipartFiles(w http.ResponseWriter, r *http.Request, h http.Handler, filter MultipartFormProcessor, fa fileAuthorizer, p Preparer, cfg *config.Config) {
	var body bytes.Buffer
	writer := multipart.NewWriter(&body)
	defer func() {
		if writerErr := writer.Close(); writerErr != nil {
			_, _ = fmt.Fprintln(w, writerErr.Error())
		}
	}()

	// Rewrite multipart form data
	err := rewriteFormFilesFromMultipart(r, writer, filter, fa, p, cfg)
	if err != nil {
		switch err {
		case http.ErrNotMultipart:
			h.ServeHTTP(w, r)
		case ErrInjectedClientParam, ErrUnexpectedMultipartEOF, http.ErrMissingBoundary:
			fail.Request(w, r, err, fail.WithStatus(http.StatusBadRequest))
		case ErrTooManyFilesUploaded:
			fail.Request(w, r, err, fail.WithStatus(http.StatusBadRequest), fail.WithBody(err.Error()))
		case destination.ErrEntityTooLarge, zipartifacts.ErrBadMetadata:
			fail.Request(w, r, err, fail.WithStatus(http.StatusRequestEntityTooLarge))
		case exif.ErrRemovingExif:
			fail.Request(w, r, err, fail.WithStatus(http.StatusUnprocessableEntity),
				fail.WithBody("Failed to process image"))
		default:
			if errors.Is(err, context.DeadlineExceeded) {
				fail.Request(w, r, err, fail.WithStatus(http.StatusGatewayTimeout), fail.WithBody("deadline exceeded"))
				return
			}

			switch t := err.(type) {
			case textproto.ProtocolError:
				fail.Request(w, r, err, fail.WithStatus(http.StatusBadRequest))
			case *api.PreAuthorizeFixedPathError:
				fail.Request(w, r, err, fail.WithStatus(t.StatusCode), fail.WithBody(t.Status))
			default:
				fail.Request(w, r, fmt.Errorf("handleFileUploads: extract files from multipart: %v", err))
			}
		}
		return
	}

	// Close writer
	if writerErr := writer.Close(); writerErr != nil {
		_, _ = fmt.Fprintln(w, writerErr.Error())
	}

	// Hijack the request
	r.Body = io.NopCloser(&body)
	r.ContentLength = int64(body.Len())
	r.Header.Set("Content-Type", writer.FormDataContentType())

	if err := filter.Finalize(r.Context()); err != nil {
		fail.Request(w, r, fmt.Errorf("handleFileUploads: Finalize: %v", err))
		return
	}

	// Proxy the request
	h.ServeHTTP(w, r)
}
