package contentprocessor

import (
	"bytes"
	"io"
	"net/http"

	"gitlab.com/gitlab-org/gitlab/workhorse/internal/headers"
)

type contentDisposition struct {
	rw                     http.ResponseWriter
	buf                    *bytes.Buffer
	wroteHeader            bool
	flushed                bool
	active                 bool
	removedResponseHeaders bool
	status                 int
	sentStatus             bool
}

// SetContentHeaders buffers the response if Gitlab-Workhorse-Detect-Content-Type
// header is found and set the proper content headers based on the current
// value of content type and disposition
func SetContentHeaders(h http.Handler) http.Handler {
	return http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		cd := &contentDisposition{
			rw:     w,
			buf:    &bytes.Buffer{},
			status: http.StatusOK,
		}

		defer cd.flush()

		h.ServeHTTP(cd, r)
	})
}

func (cd *contentDisposition) Header() http.Header {
	return cd.rw.Header()
}

func (cd *contentDisposition) Write(data []byte) (int, error) {
	// Normal write if we don't need to buffer
	if cd.isUnbuffered() {
		cd.WriteHeader(cd.status)
		return cd.rw.Write(data)
	}

	// Write the new data into the buffer
	n, _ := cd.buf.Write(data)

	// If we have enough data to calculate the content headers then flush the Buffer
	var err error
	if cd.buf.Len() >= headers.MaxDetectSize {
		err = cd.flushBuffer()
	}

	return n, err
}

func (cd *contentDisposition) flushBuffer() error {
	if cd.isUnbuffered() {
		return nil
	}

	cd.flushed = true

	// If the buffer has any content then we calculate the content headers and
	// write in the response
	if cd.buf.Len() > 0 {
		cd.writeContentHeaders()
		cd.WriteHeader(cd.status)
		_, err := io.Copy(cd.rw, cd.buf)
		return err
	}

	// If no content is present in the buffer we still need to send the headers
	cd.WriteHeader(cd.status)
	return nil
}

func (cd *contentDisposition) writeContentHeaders() {
	if cd.wroteHeader {
		return
	}

	cd.wroteHeader = true
	contentType, contentDisposition := headers.SafeContentHeaders(cd.buf.Bytes(), cd.Header().Get(headers.ContentDispositionHeader))
	cd.Header().Set(headers.ContentTypeHeader, contentType)
	cd.Header().Set(headers.ContentDispositionHeader, contentDisposition)
}

func (cd *contentDisposition) WriteHeader(status int) {
	if cd.sentStatus {
		return
	}

	cd.status = status

	if cd.isUnbuffered() {
		cd.rw.WriteHeader(cd.status)
		cd.sentStatus = true
	}
}

// If we find any response header, then we must calculate the content headers
// If we don't find any, the data is not buffered and it works as
// a usual ResponseWriter
func (cd *contentDisposition) isUnbuffered() bool {
	if !cd.removedResponseHeaders {
		if headers.IsDetectContentTypeHeaderPresent(cd.rw) {
			cd.active = true
		}

		cd.removedResponseHeaders = true
		// We ensure to clear any response header from the response
		headers.RemoveResponseHeaders(cd.rw)
	}

	return cd.flushed || !cd.active
}

func (cd *contentDisposition) flush() {
	cd.flushBuffer()
}
