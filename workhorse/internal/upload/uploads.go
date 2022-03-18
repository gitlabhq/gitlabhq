package upload

import (
	"bytes"
	"context"
	"fmt"
	"io/ioutil"
	"mime/multipart"
	"net/http"

	"github.com/golang-jwt/jwt/v4"

	"gitlab.com/gitlab-org/gitlab/workhorse/internal/api"
	"gitlab.com/gitlab-org/gitlab/workhorse/internal/helper"
	"gitlab.com/gitlab-org/gitlab/workhorse/internal/upload/destination"
	"gitlab.com/gitlab-org/gitlab/workhorse/internal/upload/exif"
	"gitlab.com/gitlab-org/gitlab/workhorse/internal/zipartifacts"
)

const RewrittenFieldsHeader = "Gitlab-Workhorse-Multipart-Fields"

type PreAuthorizer interface {
	PreAuthorizeHandler(next api.HandleFunc, suffix string) http.Handler
}

type MultipartClaims struct {
	RewrittenFields map[string]string `json:"rewritten_fields"`
	jwt.StandardClaims
}

// MultipartFormProcessor abstracts away implementation differences
// between generic MIME multipart file uploads and CI artifact uploads.
type MultipartFormProcessor interface {
	ProcessFile(ctx context.Context, formName string, file *destination.FileHandler, writer *multipart.Writer) error
	ProcessField(ctx context.Context, formName string, writer *multipart.Writer) error
	Finalize(ctx context.Context) error
	Name() string
	Count() int
}

// interceptMultipartFiles is the core of the implementation of
// Multipart.
func interceptMultipartFiles(w http.ResponseWriter, r *http.Request, h http.Handler, preauth *api.Response, filter MultipartFormProcessor, opts *destination.UploadOpts) {
	var body bytes.Buffer
	writer := multipart.NewWriter(&body)
	defer writer.Close()

	// Rewrite multipart form data
	err := rewriteFormFilesFromMultipart(r, writer, preauth, filter, opts)
	if err != nil {
		switch err {
		case ErrInjectedClientParam:
			helper.CaptureAndFail(w, r, err, "Bad Request", http.StatusBadRequest)
		case ErrTooManyFilesUploaded:
			helper.CaptureAndFail(w, r, err, err.Error(), http.StatusBadRequest)
		case http.ErrNotMultipart:
			h.ServeHTTP(w, r)
		case destination.ErrEntityTooLarge:
			helper.RequestEntityTooLarge(w, r, err)
		case zipartifacts.ErrBadMetadata:
			helper.RequestEntityTooLarge(w, r, err)
		case exif.ErrRemovingExif:
			helper.CaptureAndFail(w, r, err, "Failed to process image", http.StatusUnprocessableEntity)
		default:
			helper.Fail500(w, r, fmt.Errorf("handleFileUploads: extract files from multipart: %v", err))
		}
		return
	}

	// Close writer
	writer.Close()

	// Hijack the request
	r.Body = ioutil.NopCloser(&body)
	r.ContentLength = int64(body.Len())
	r.Header.Set("Content-Type", writer.FormDataContentType())

	if err := filter.Finalize(r.Context()); err != nil {
		helper.Fail500(w, r, fmt.Errorf("handleFileUploads: Finalize: %v", err))
		return
	}

	// Proxy the request
	h.ServeHTTP(w, r)
}
