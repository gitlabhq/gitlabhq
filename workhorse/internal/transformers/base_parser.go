// Package transformers provides shared utilities for artifact transformers
package transformers

import (
	"archive/zip"
	"context"
	"errors"
	"fmt"
	"io"
	"os"
)

// createAndUnlinkTempFile creates and unlinks a temp file.
// Unlinking removes it from directory listings while keeping the file descriptor open.
func createAndUnlinkTempFile(prefix string) (*os.File, error) {
	f, err := os.CreateTemp("", prefix)
	if err != nil {
		return nil, err
	}
	if err := os.Remove(f.Name()); err != nil {
		_ = f.Close()
		return nil, err
	}
	return f, nil
}

// Transformer defines the interface for format-specific transformation logic
type Transformer interface {
	// Parse reads and parses the input data from the first file in the ZIP
	Parse(ctx context.Context, reader io.Reader) error
	// Serialize writes the transformed output to the zip writer
	Serialize(zw *zip.Writer) error
	// Close cleans up any resources
	Close() error
}

// BaseParser provides common functionality for code intelligence parsers
type BaseParser struct {
	pr          *io.PipeReader
	logger      *TransformLogger
	transformer Transformer
}

// NewBaseParser creates a parser with common ZIP handling and transformation pipeline
func NewBaseParser(ctx context.Context, artifactType string, r io.Reader, transformer Transformer) (*BaseParser, error) {
	// ZIP files need to be seekable. Don't hold it all in RAM, use a tempfile
	tempFile, err := createAndUnlinkTempFile(artifactType)
	if err != nil {
		return nil, err
	}

	defer func() { _ = tempFile.Close() }()

	size, err := io.Copy(tempFile, r)
	if err != nil {
		return nil, err
	}

	logger := NewTransformLogger(artifactType, size)
	logger.LogStart(ctx)

	// Open ZIP and extract first file
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

	// Parse format-specific data
	if err := transformer.Parse(ctx, file); err != nil {
		_ = transformer.Close()
		return nil, err
	}

	// Set up transformation pipeline
	pr, pw := io.Pipe()
	parser := &BaseParser{
		pr:          pr,
		logger:      logger,
		transformer: transformer,
	}

	go func() { _ = parser.transform(ctx, artifactType, pw) }()

	return parser, nil
}

// Read implements io.Reader
func (p *BaseParser) Read(b []byte) (int, error) {
	return p.pr.Read(b)
}

// Close implements io.Closer
func (p *BaseParser) Close() error {
	return errors.Join(p.pr.Close(), p.transformer.Close())
}

func (p *BaseParser) transform(ctx context.Context, artifactType string, pw *io.PipeWriter) error {
	cw := &CountingWriter{Writer: pw}
	zw := zip.NewWriter(cw)

	if err := p.transformer.Serialize(zw); err != nil {
		_ = zw.Close() // Free underlying resources only
		pw.CloseWithError(fmt.Errorf("%s parser: Serialize: %v", artifactType, err))
		return err
	}

	if err := zw.Close(); err != nil {
		pw.CloseWithError(fmt.Errorf("%s parser: ZipWriter.Close: %v", artifactType, err))
		return err
	}

	p.logger.LogComplete(ctx, cw.Count)

	return pw.Close()
}
