package limit

import (
	"errors"
	"io"
	"sync/atomic"
)

var ErrLimitExceeded = errors.New("reader limit exceeded")

const megabyte = 1 << 20

// LimitedReaderAt supports running a callback in case of reaching a read limit
// (bytes), and allows using a smaller limit than a defined offset for a read.
type LimitedReaderAt struct {
	read      int64
	limit     int64
	parent    io.ReaderAt
	limitFunc func(int64)
}

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

func NewLimitedReaderAt(reader io.ReaderAt, limit int64, limitFunc func(int64)) io.ReaderAt {
	return &LimitedReaderAt{parent: reader, limit: limit, limitFunc: limitFunc}
}

// SizeToLimit tries to dermine an appropriate limit in bytes for an archive of
// a given size. If the size is less than 1 gigabyte we always limit a reader
// to 100 megabytes, otherwise the limit is 10% of a given size.
func SizeToLimit(size int64) int64 {
	if size <= 1024*megabyte {
		return 100 * megabyte
	}

	return size / 10
}
