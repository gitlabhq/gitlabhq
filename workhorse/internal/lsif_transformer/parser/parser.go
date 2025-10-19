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

	pr         *io.PipeReader
	inputSize  int64
	outputSize int64
}

// countingWriter wraps an io.Writer and counts the number of bytes written
type countingWriter struct {
	writer io.Writer
	count  int64
}

func (cw *countingWriter) Write(p []byte) (int, error) {
	n, err := cw.writer.Write(p)
	cw.count += int64(n)
	return n, err
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
	log.WithContextFields(ctx, log.Fields{
		"lsif_original_size_bytes": size,
		"lsif_processing":          true,
	}).Info("cached incoming LSIF file for processing")

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
		Docs:      docs,
		pr:        pr,
		inputSize: size,
	}

	go func() { _ = parser.transform(ctx, pw) }()

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

func (p *Parser) transform(ctx context.Context, pw *io.PipeWriter) error {
	cw := &countingWriter{writer: pw}
	zw := zip.NewWriter(cw)

	if err := p.Docs.SerializeEntries(zw); err != nil {
		_ = zw.Close() // Free underlying resources only
		pw.CloseWithError(fmt.Errorf("lsif parser: Docs.SerializeEntries: %v", err))
		return err
	}

	if err := zw.Close(); err != nil {
		pw.CloseWithError(fmt.Errorf("lsif parser: ZipWriter.Close: %v", err))
		return err
	}

	p.outputSize = cw.count

	sizeRatio := float64(0)
	if p.inputSize > 0 {
		sizeRatio = float64(p.outputSize) / float64(p.inputSize)
	}

	log.WithContextFields(ctx, log.Fields{
		"lsif_original_size_bytes":  p.inputSize,
		"lsif_processed_size_bytes": p.outputSize,
		"lsif_size_ratio":           sizeRatio,
		"lsif_size_change_bytes":    p.outputSize - p.inputSize,
		"lsif_processing":           true,
	}).Info("completed LSIF file transformation")

	return pw.Close()
}
