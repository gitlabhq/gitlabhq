package helper

import (
	"context"
	"io"
)

type ContextReader struct {
	ctx              context.Context
	underlyingReader io.Reader
}

func NewContextReader(ctx context.Context, underlyingReader io.Reader) *ContextReader {
	return &ContextReader{
		ctx:              ctx,
		underlyingReader: underlyingReader,
	}
}

func (r *ContextReader) Read(b []byte) (int, error) {
	if r.canceled() {
		return 0, r.err()
	}

	n, err := r.underlyingReader.Read(b)

	if r.canceled() {
		err = r.err()
	}

	return n, err
}

func (r *ContextReader) canceled() bool {
	return r.err() != nil
}

func (r *ContextReader) err() error {
	return r.ctx.Err()
}
