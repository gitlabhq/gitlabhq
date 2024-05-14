// Package filestore has a consumer specific to uploading to local disk storage.
package filestore

import (
	"context"
	"io"
	"time"
)

// LocalFile represents a file opened for writing in the local filesystem.
type LocalFile struct {
	File io.WriteCloser
}

// Consume copies data from an io.Reader to the LocalFile's file, closing it after.
// It returns the number of bytes copied and any errors.
func (lf *LocalFile) Consume(_ context.Context, r io.Reader, _ time.Time) (int64, error) {
	n, err := io.Copy(lf.File, r)
	errClose := lf.File.Close()
	if err == nil {
		err = errClose
	}
	return n, err
}

// ConsumeWithoutDelete is a wrapper around Consume that allows consuming data without deleting the file.
func (lf *LocalFile) ConsumeWithoutDelete(outerCtx context.Context, reader io.Reader, deadLine time.Time) (_ int64, err error) {
	return lf.Consume(outerCtx, reader, deadLine)
}
