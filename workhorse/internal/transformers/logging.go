// Package transformers provides shared utilities for artifact transformers
package transformers

import (
	"context"
	"io"

	"gitlab.com/gitlab-org/labkit/log"
)

// TransformLogger helps track and log artifact transformation metrics
type TransformLogger struct {
	artifactType string
	inputSize    int64
}

// NewTransformLogger creates a new logger for tracking artifact transformation
func NewTransformLogger(artifactType string, inputSize int64) *TransformLogger {
	return &TransformLogger{
		artifactType: artifactType,
		inputSize:    inputSize,
	}
}

// LogStart logs the beginning of transformation processing
func (tl *TransformLogger) LogStart(ctx context.Context) {
	log.WithContextFields(ctx, log.Fields{
		"artifact_type":                tl.artifactType,
		"artifact_original_size_bytes": tl.inputSize,
		"artifact_processing":          true,
	}).Info("cached incoming artifact file for processing")
}

// LogComplete logs the completion of transformation with size metrics
func (tl *TransformLogger) LogComplete(ctx context.Context, outputSize int64) {
	sizeRatio := float64(0)
	if tl.inputSize > 0 {
		sizeRatio = float64(outputSize) / float64(tl.inputSize)
	}

	log.WithContextFields(ctx, log.Fields{
		"artifact_type":                 tl.artifactType,
		"artifact_original_size_bytes":  tl.inputSize,
		"artifact_processed_size_bytes": outputSize,
		"artifact_size_ratio":           sizeRatio,
		"artifact_size_change_bytes":    outputSize - tl.inputSize,
		"artifact_processing":           false,
	}).Info("completed artifact file transformation")
}

// CountingWriter wraps an io.Writer and counts the number of bytes written
type CountingWriter struct {
	Writer io.Writer
	Count  int64
}

// Write implements io.Writer interface while counting bytes
func (cw *CountingWriter) Write(p []byte) (int, error) {
	n, err := cw.Writer.Write(p)
	cw.Count += int64(n)
	return n, err
}
