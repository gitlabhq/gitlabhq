// Package parser provides functionality for parsing, serializing, and managing ranges of data
package parser

import (
	"archive/zip"
	"context"
	"io"

	"gitlab.com/gitlab-org/gitlab/workhorse/internal/transformers"
)

var (
	// Lsif contains the lsif string name
	Lsif = "lsif"
)

// lsifTransformer implements the Transformer interface for LSIF format
type lsifTransformer struct {
	Docs *Docs
}

func (t *lsifTransformer) Parse(_ context.Context, reader io.Reader) error {
	docs, err := NewDocs()
	if err != nil {
		return err
	}
	t.Docs = docs

	return t.Docs.Parse(reader)
}

func (t *lsifTransformer) Serialize(zw *zip.Writer) error {
	return t.Docs.SerializeEntries(zw)
}

func (t *lsifTransformer) Close() error {
	if t.Docs != nil {
		return t.Docs.Close()
	}
	return nil
}

// NewParser creates a new Parser instance and initializes it with the provided reader
func NewParser(ctx context.Context, r io.Reader) (io.ReadCloser, error) {
	transformer := &lsifTransformer{}
	return transformers.NewBaseParser(ctx, Lsif, r, transformer)
}
