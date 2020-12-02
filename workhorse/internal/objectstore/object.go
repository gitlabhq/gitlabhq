package objectstore

import (
	"context"
	"fmt"
	"io"
	"io/ioutil"
	"net"
	"net/http"
	"time"

	"gitlab.com/gitlab-org/labkit/correlation"
	"gitlab.com/gitlab-org/labkit/mask"
	"gitlab.com/gitlab-org/labkit/tracing"
)

// httpTransport defines a http.Transport with values
// that are more restrictive than for http.DefaultTransport,
// they define shorter TLS Handshake, and more aggressive connection closing
// to prevent the connection hanging and reduce FD usage
var httpTransport = tracing.NewRoundTripper(correlation.NewInstrumentedRoundTripper(&http.Transport{
	Proxy: http.ProxyFromEnvironment,
	DialContext: (&net.Dialer{
		Timeout:   30 * time.Second,
		KeepAlive: 10 * time.Second,
	}).DialContext,
	MaxIdleConns:          2,
	IdleConnTimeout:       30 * time.Second,
	TLSHandshakeTimeout:   10 * time.Second,
	ExpectContinueTimeout: 10 * time.Second,
	ResponseHeaderTimeout: 30 * time.Second,
}))

var httpClient = &http.Client{
	Transport: httpTransport,
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

func (o *Object) Upload(ctx context.Context, r io.Reader) error {
	// we should prevent pr.Close() otherwise it may shadow error set with pr.CloseWithError(err)
	req, err := http.NewRequest(http.MethodPut, o.putURL, ioutil.NopCloser(r))

	if err != nil {
		return fmt.Errorf("PUT %q: %v", mask.URL(o.putURL), err)
	}
	req.ContentLength = o.size

	for k, v := range o.putHeaders {
		req.Header.Set(k, v)
	}

	resp, err := httpClient.Do(req)
	if err != nil {
		return fmt.Errorf("PUT request %q: %v", mask.URL(o.putURL), err)
	}
	defer resp.Body.Close()

	if resp.StatusCode != http.StatusOK {
		if o.metrics {
			objectStorageUploadRequestsInvalidStatus.Inc()
		}
		return StatusCodeError(fmt.Errorf("PUT request %v returned: %s", mask.URL(o.putURL), resp.Status))
	}

	o.etag = extractETag(resp.Header.Get("ETag"))

	return nil
}

func (o *Object) ETag() string {
	return o.etag
}

func (o *Object) Abort() {
	o.Delete()
}

func (o *Object) Delete() {
	deleteURL(o.deleteURL)
}
