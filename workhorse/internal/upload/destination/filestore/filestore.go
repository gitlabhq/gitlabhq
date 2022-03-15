package filestore

import (
	"context"
	"io"
	"time"
)

type LocalFile struct {
	File io.WriteCloser
}

func (lf *LocalFile) Consume(_ context.Context, r io.Reader, _ time.Time) (int64, error) {
	n, err := io.Copy(lf.File, r)
	errClose := lf.File.Close()
	if err == nil {
		err = errClose
	}
	return n, err
}
