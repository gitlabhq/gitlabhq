// Package limit provides functionality for limiting reads from a reader
package limit

import (
	"errors"
	"io"
	"sync/atomic"
)

// ErrLimitExceeded is returned when the reader limit is exceeded
var ErrLimitExceeded = errors.New("reader limit exceeded")

// LimitedReaderAt supports running a callback in case of reaching a read limit
// (bytes), and allows using a smaller limit than a defined offset for a read.
type LimitedReaderAt struct {
	read      int64
	limit     int64
	parent    io.ReaderAt
	limitFunc func(int64)
}

// ReadAt reads bytes from a specified offset
func (r *LimitedReaderAt) ReadAt(p []byte, off int64) (int, error) {
	if max := r.limit - r.read; int64(len(p)) > max {
		p = p[0:max]
	}

	n, err := r.parent.ReadAt(p, off)
	atomic.AddInt64(&r.read, int64(n))

	if r.read >= r.limit {
		r.limitFunc(r.read)

		return n, ErrLimitExceeded
	}

	return n, err
}

// NewLimitedReaderAt returns a new LimitedReaderAt with the given reader, limit, and limit function.
func NewLimitedReaderAt(reader io.ReaderAt, limit int64, limitFunc func(int64)) io.ReaderAt {
	return &LimitedReaderAt{parent: reader, limit: limit, limitFunc: limitFunc}
}
