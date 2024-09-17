// Package parser provides functionality for parsing, serializing, and managing ranges of data
package parser

import (
	"archive/zip"
	"context"
	"errors"
	"fmt"
	"io"
	"os"

	"gitlab.com/gitlab-org/labkit/log"
)

var (
	// Lsif contains the lsif string name
	Lsif = "lsif"
)

// Parser is responsible for parsing LSIF data
type Parser struct {
	Docs *Docs

	pr *io.PipeReader
}

// NewParser creates a new Parser instance and initializes it with the provided reader
func NewParser(ctx context.Context, r io.Reader) (io.ReadCloser, error) {
	docs, err := NewDocs()
	if err != nil {
		return nil, err
	}

	// ZIP files need to be seekable. Don't hold it all in RAM, use a tempfile
	tempFile, err := os.CreateTemp("", Lsif)
	if err != nil {
		return nil, err
	}

	defer func() { _ = tempFile.Close() }()

	if osRemoveErr := os.Remove(tempFile.Name()); osRemoveErr != nil {
		return nil, osRemoveErr
	}

	size, err := io.Copy(tempFile, r)
	if err != nil {
		return nil, err
	}
	log.WithContextFields(ctx, log.Fields{"lsif_zip_cache_bytes": size}).Print("cached incoming LSIF zip on disk")

	zr, err := zip.NewReader(tempFile, size)
	if err != nil {
		return nil, err
	}

	if len(zr.File) == 0 {
		return nil, errors.New("empty zip file")
	}

	file, err := zr.File[0].Open()
	if err != nil {
		return nil, err
	}

	defer func() { _ = file.Close() }()

	if err := docs.Parse(file); err != nil {
		return nil, err
	}

	pr, pw := io.Pipe()
	parser := &Parser{
		Docs: docs,
		pr:   pr,
	}

	go func() { _ = parser.transform(pw) }()

	return parser, nil
}

// Read reads data from the parser's pipe reader
func (p *Parser) Read(b []byte) (int, error) {
	return p.pr.Read(b)
}

// Close closes the parser and its associated resources
func (p *Parser) Close() error {
	return errors.Join(p.pr.Close(), p.Docs.Close())
}

func (p *Parser) transform(pw *io.PipeWriter) error {
	zw := zip.NewWriter(pw)

	if err := p.Docs.SerializeEntries(zw); err != nil {
		_ = zw.Close() // Free underlying resources only
		pw.CloseWithError(fmt.Errorf("lsif parser: Docs.SerializeEntries: %v", err))
		return err
	}

	if err := zw.Close(); err != nil {
		pw.CloseWithError(fmt.Errorf("lsif parser: ZipWriter.Close: %v", err))
		return err
	}

	return pw.Close()
}
