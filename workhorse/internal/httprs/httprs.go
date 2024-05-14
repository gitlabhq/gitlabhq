/*
Package httprs provides a ReadSeeker for http.Response.Body.

Usage :

	resp, err := http.Get(url)
	rs := httprs.NewHttpReadSeeker(resp)
	defer rs.Close()
	io.ReadFull(rs, buf) // reads the first bytes from the response body
	rs.Seek(1024, 0) // moves the position, but does no range request
	io.ReadFull(rs, buf) // does a range request and reads from the response body

If you want use a specific http.Client for additional range requests :

	rs := httprs.NewHttpReadSeeker(resp, client)
*/
package httprs

import (
	"context"
	"errors"
	"fmt"
	"io"
	"net/http"

	"github.com/mitchellh/copystructure"
)

const shortSeekBytes = 1024

// A HTTPReadSeeker reads from a http.Response.Body. It can Seek
// by doing range requests.
type HTTPReadSeeker struct {
	c   *http.Client
	req *http.Request
	res *http.Response
	ctx context.Context
	r   io.ReadCloser
	pos int64

	Requests int
}

var _ io.ReadCloser = (*HTTPReadSeeker)(nil)
var _ io.Seeker = (*HTTPReadSeeker)(nil)

var (
	// ErrNoContentLength is returned by Seek when the initial http response did not include a Content-Length header
	ErrNoContentLength = errors.New("header Content-Length was not set")
	// ErrRangeRequestsNotSupported is returned by Seek and Read
	// when the remote server does not allow range requests (Accept-Ranges was not set)
	ErrRangeRequestsNotSupported = errors.New("range requests are not supported by the remote server")
	// ErrInvalidRange is returned by Read when trying to read past the end of the file
	ErrInvalidRange = errors.New("invalid range")
	// ErrContentHasChanged is returned by Read when the content has changed since the first request
	ErrContentHasChanged = errors.New("content has changed since first request")
)

// NewHTTPReadSeeker returns a HttpReadSeeker, using the http.Response and, optionaly, the http.Client
// that needs to be used for future range requests. If no http.Client is given, http.DefaultClient will
// be used.
//
// res.Request will be reused for range requests, headers may be added/removed
func NewHTTPReadSeeker(res *http.Response, client ...*http.Client) *HTTPReadSeeker {
	r := &HTTPReadSeeker{
		req: res.Request,
		ctx: res.Request.Context(),
		res: res,
		r:   res.Body,
	}
	if len(client) > 0 {
		r.c = client[0]
	} else {
		r.c = http.DefaultClient
	}
	return r
}

// Clone clones the reader to enable parallel downloads of ranges
func (r *HTTPReadSeeker) Clone() (*HTTPReadSeeker, error) {
	req, err := copystructure.Copy(r.req)
	if err != nil {
		return nil, err
	}
	return &HTTPReadSeeker{
		req: req.(*http.Request),
		res: r.res,
		r:   nil,
		c:   r.c,
	}, nil
}

// Read reads from the response body. It does a range request if Seek was called before.
//
// May return ErrRangeRequestsNotSupported, ErrInvalidRange or ErrContentHasChanged
func (r *HTTPReadSeeker) Read(p []byte) (n int, err error) {
	if r.r == nil {
		err = r.rangeRequest()
	}
	if r.r != nil {
		n, err = r.r.Read(p)
		r.pos += int64(n)
	}
	return
}

// ReadAt reads from the response body starting at offset off.
//
// May return ErrRangeRequestsNotSupported, ErrInvalidRange or ErrContentHasChanged
func (r *HTTPReadSeeker) ReadAt(p []byte, off int64) (n int, err error) {
	var nn int

	_, _ = r.Seek(off, 0)

	for n < len(p) && err == nil {
		nn, err = r.Read(p[n:])
		n += nn
	}
	return
}

// Close closes the response body
func (r *HTTPReadSeeker) Close() error {
	if r.r != nil {
		return r.r.Close()
	}
	return nil
}

// Seek moves the reader position to a new offset.
//
// It does not send http requests, allowing for multiple seeks without overhead.
// The http request will be sent by the next Read call.
//
// May return ErrNoContentLength or ErrRangeRequestsNotSupported
func (r *HTTPReadSeeker) Seek(offset int64, whence int) (int64, error) {
	var err error
	switch whence {
	case 0:
	case 1:
		offset += r.pos
	case 2:
		if r.res.ContentLength <= 0 {
			return 0, ErrNoContentLength
		}
		offset = r.res.ContentLength - offset
	}
	if r.r != nil {
		// Try to read, which is cheaper than doing a request
		if r.pos < offset && offset-r.pos <= shortSeekBytes {
			_, copyNErr := io.CopyN(io.Discard, r, offset-r.pos)
			if copyNErr != nil {
				return 0, copyNErr
			}
		}

		if r.pos != offset {
			err = r.r.Close()
			r.r = nil
		}
	}
	r.pos = offset
	return r.pos, err
}

func cloneHeader(h http.Header) http.Header {
	h2 := make(http.Header, len(h))
	for k, vv := range h {
		vv2 := make([]string, len(vv))
		copy(vv2, vv)
		h2[k] = vv2
	}
	return h2
}

func (r *HTTPReadSeeker) newRequest() *http.Request {
	newreq := r.req.WithContext(r.ctx) // includes shallow copies of maps, but okay
	if r.req.ContentLength == 0 {
		newreq.Body = nil // Issue 16036: nil Body for http.Transport retries
	}
	newreq.Header = cloneHeader(r.req.Header)
	return newreq
}

func (r *HTTPReadSeeker) rangeRequest() error {
	r.req = r.newRequest()
	r.req.Header.Set("Range", fmt.Sprintf("bytes=%d-", r.pos))
	etag, last := r.res.Header.Get("ETag"), r.res.Header.Get("Last-Modified")
	switch {
	case last != "":
		r.req.Header.Set("If-Range", last)
	case etag != "":
		r.req.Header.Set("If-Range", etag)
	}

	r.Requests++

	res, err := r.c.Do(r.req)
	if err != nil {
		return err
	}
	switch res.StatusCode {
	case http.StatusRequestedRangeNotSatisfiable:
		return ErrInvalidRange
	case http.StatusOK:
		// some servers return 200 OK for bytes=0-
		if r.pos > 0 ||
			(etag != "" && etag != res.Header.Get("ETag")) {
			return ErrContentHasChanged
		}
		fallthrough
	case http.StatusPartialContent:
		r.r = res.Body
		return nil
	}

	_ = res.Body.Close()
	return ErrRangeRequestsNotSupported
}
