package objectstore

import (
	"context"
	"fmt"
	"io"
	"net/http"

	"gitlab.com/gitlab-org/labkit/mask"

	"gitlab.com/gitlab-org/gitlab/workhorse/internal/transport"
)

var httpClient = &http.Client{
	Transport: transport.NewRestrictedTransport(),
}

// Object represents an object on a S3 compatible Object Store service.
// It can be used as io.WriteCloser for uploading an object
type Object struct {
	// putURL is a presigned URL for PutObject
	putURL string
	// deleteURL is a presigned URL for RemoveObject
	deleteURL  string
	putHeaders map[string]string
	size       int64
	etag       string
	metrics    bool

	*uploader
}

// StatusCodeError represents an error with a specific status code.
type StatusCodeError error

// NewObject opens an HTTP connection to Object Store and returns an Object pointer that can be used for uploading.
func NewObject(putURL, deleteURL string, putHeaders map[string]string, size int64) (*Object, error) {
	return newObject(putURL, deleteURL, putHeaders, size, true)
}

func newObject(putURL, deleteURL string, putHeaders map[string]string, size int64, metrics bool) (*Object, error) {
	o := &Object{
		putURL:     putURL,
		deleteURL:  deleteURL,
		putHeaders: putHeaders,
		size:       size,
		metrics:    metrics,
	}

	o.uploader = newETagCheckUploader(o, metrics)
	return o, nil
}

// Upload uploads the content of the object using the provided reader.
func (o *Object) Upload(ctx context.Context, r io.Reader) error {
	// we should prevent pr.Close() otherwise it may shadow error set with pr.CloseWithError(err)
	req, err := http.NewRequestWithContext(ctx, http.MethodPut, o.putURL, io.NopCloser(r))

	if err != nil {
		return fmt.Errorf("PUT %q: %v", mask.URL(o.putURL), err)
	}
	req.ContentLength = o.size

	for k, v := range o.putHeaders {
		req.Header.Set(k, v)
	}

	resp, err := httpClient.Do(req)
	if err != nil {
		return fmt.Errorf("PUT request %q: %w", mask.URL(o.putURL), err)
	}
	defer func() { _ = resp.Body.Close() }()

	if resp.StatusCode != http.StatusOK {
		if o.metrics {
			objectStorageUploadRequestsInvalidStatus.Inc()
		}
		return StatusCodeError(fmt.Errorf("PUT request %v returned: %s", mask.URL(o.putURL), resp.Status))
	}

	o.etag = extractETag(resp.Header.Get("ETag"))

	return nil
}

// ETag returns the ETag of the object.
func (o *Object) ETag() string {
	return o.etag
}

// Abort aborts the operation on the object.
func (o *Object) Abort() {
	o.Delete()
}

// Delete deletes the object.
func (o *Object) Delete() {
	deleteURL(o.deleteURL)
}
