package helper

import (
	"net/http"
)

type CountingResponseWriter interface {
	http.ResponseWriter
	Count() int64
	Status() int
}

type countingResponseWriter struct {
	rw     http.ResponseWriter
	status int
	count  int64
}

func NewCountingResponseWriter(rw http.ResponseWriter) CountingResponseWriter {
	return &countingResponseWriter{rw: rw}
}

func (c *countingResponseWriter) Header() http.Header {
	return c.rw.Header()
}

func (c *countingResponseWriter) Write(data []byte) (int, error) {
	if c.status == 0 {
		c.WriteHeader(http.StatusOK)
	}

	n, err := c.rw.Write(data)
	c.count += int64(n)
	return n, err
}

func (c *countingResponseWriter) WriteHeader(status int) {
	if c.status != 0 {
		return
	}

	c.status = status
	c.rw.WriteHeader(status)
}

// Count returns the number of bytes written to the ResponseWriter. This
// function is not thread-safe.
func (c *countingResponseWriter) Count() int64 {
	return c.count
}

// Status returns the first HTTP status value that was written to the
// ResponseWriter. This function is not thread-safe.
func (c *countingResponseWriter) Status() int {
	return c.status
}
