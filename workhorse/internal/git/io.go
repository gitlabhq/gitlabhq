package git

import (
	"context"
	"fmt"
	"io"
	"os"
	"sync"
)

type contextReader struct {
	ctx              context.Context
	underlyingReader io.Reader
}

func newContextReader(ctx context.Context, underlyingReader io.Reader) *contextReader {
	return &contextReader{
		ctx:              ctx,
		underlyingReader: underlyingReader,
	}
}

func (r *contextReader) Read(b []byte) (int, error) {
	if r.canceled() {
		return 0, r.err()
	}

	n, err := r.underlyingReader.Read(b)

	if r.canceled() {
		err = r.err()
	}

	return n, err
}

func (r *contextReader) canceled() bool {
	return r.err() != nil
}

func (r *contextReader) err() error {
	return r.ctx.Err()
}

type writeFlusher interface {
	io.Writer
	Flush() error
}

// Couple r and w so that until r has been drained (before r.Read() has
// returned some error), all writes to w are sent to a tempfile first.
// The caller must call Flush() on the returned WriteFlusher to ensure
// all data is propagated to w.
func newWriteAfterReader(r io.Reader, w io.Writer) (io.Reader, writeFlusher) {
	br := &busyReader{Reader: r}
	return br, &coupledWriter{Writer: w, busyReader: br}
}

type busyReader struct {
	io.Reader

	error
	errorMutex sync.RWMutex
}

func (r *busyReader) Read(p []byte) (int, error) {
	if err := r.getError(); err != nil {
		return 0, err
	}

	n, err := r.Reader.Read(p)
	if err != nil {
		if err != io.EOF {
			err = fmt.Errorf("busyReader: %w", err)
		}
		r.setError(err)
	}
	return n, err
}

func (r *busyReader) IsBusy() bool {
	return r.getError() == nil
}

func (r *busyReader) getError() error {
	r.errorMutex.RLock()
	defer r.errorMutex.RUnlock()
	return r.error
}

func (r *busyReader) setError(err error) {
	if err == nil {
		panic("busyReader: attempt to reset error to nil")
	}
	r.errorMutex.Lock()
	defer r.errorMutex.Unlock()
	r.error = err
}

type coupledWriter struct {
	io.Writer
	*busyReader

	tempfile      *os.File
	tempfileMutex sync.Mutex

	writeError error
}

func (w *coupledWriter) Write(data []byte) (int, error) {
	if w.writeError != nil {
		return 0, w.writeError
	}

	if w.busyReader.IsBusy() {
		n, err := w.tempfileWrite(data)
		if err != nil {
			w.writeError = fmt.Errorf("coupledWriter: %w", err)
		}
		return n, w.writeError
	}

	if err := w.Flush(); err != nil {
		w.writeError = fmt.Errorf("coupledWriter: %w", err)
		return 0, w.writeError
	}

	return w.Writer.Write(data)
}

func (w *coupledWriter) Flush() error {
	w.tempfileMutex.Lock()
	defer w.tempfileMutex.Unlock()

	tempfile := w.tempfile
	if tempfile == nil {
		return nil
	}

	w.tempfile = nil
	defer tempfile.Close()

	if _, err := tempfile.Seek(0, 0); err != nil {
		return err
	}
	if _, err := io.Copy(w.Writer, tempfile); err != nil {
		return err
	}
	return nil
}

func (w *coupledWriter) tempfileWrite(data []byte) (int, error) {
	w.tempfileMutex.Lock()
	defer w.tempfileMutex.Unlock()

	if w.tempfile == nil {
		tempfile, err := w.newTempfile()
		if err != nil {
			return 0, err
		}
		w.tempfile = tempfile
	}

	return w.tempfile.Write(data)
}

func (*coupledWriter) newTempfile() (tempfile *os.File, err error) {
	tempfile, err = os.CreateTemp("", "gitlab-workhorse-coupledWriter")
	if err != nil {
		return nil, err
	}
	if err := os.Remove(tempfile.Name()); err != nil {
		tempfile.Close()
		return nil, err
	}

	return tempfile, nil
}
