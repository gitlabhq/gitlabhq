package transformers

import (
	"bytes"
	"context"
	"testing"

	"github.com/sirupsen/logrus"
	"github.com/stretchr/testify/assert"
	"github.com/stretchr/testify/require"
)

// captureStandardLogOutput temporarily redirects the standard logrus logger's
// output and returns everything logged during fn's execution.
func captureStandardLogOutput(t *testing.T, fn func()) string {
	t.Helper()
	buf := &bytes.Buffer{}
	logger := logrus.StandardLogger()
	oldOut := logger.Out
	logger.Out = buf
	defer func() { logger.Out = oldOut }()
	fn()
	return buf.String()
}

func TestNewTransformLogger(t *testing.T) {
	tl := NewTransformLogger("zip", 1024)
	assert.Equal(t, "zip", tl.artifactType)
	assert.Equal(t, int64(1024), tl.inputSize)
}

func TestTransformLoggerLogStart(t *testing.T) {
	tl := NewTransformLogger("zip", 2048)
	ctx := context.Background()

	output := captureStandardLogOutput(t, func() {
		tl.LogStart(ctx)
	})

	require.Contains(t, output, "cached incoming artifact file for processing")
	require.Contains(t, output, "artifact_type=zip")
	require.Contains(t, output, "artifact_original_size_bytes=2048")
	require.Contains(t, output, "artifact_processing=true")
}

func TestTransformLoggerLogComplete(t *testing.T) {
	tests := []struct {
		name         string
		inputSize    int64
		outputSize   int64
		wantContains []string
	}{
		{
			name:       "normal shrinking transformation",
			inputSize:  1000,
			outputSize: 800,
			wantContains: []string{
				"completed artifact file transformation",
				"artifact_type=tgz",
				"artifact_original_size_bytes=1000",
				"artifact_processed_size_bytes=800",
				"artifact_size_ratio=0.8",
				"artifact_size_change_bytes=-200",
				"artifact_processing=false",
			},
		},
		{
			name:       "growing transformation",
			inputSize:  500,
			outputSize: 1000,
			wantContains: []string{
				"completed artifact file transformation",
				"artifact_size_ratio=2",
				"artifact_size_change_bytes=500",
			},
		},
		{
			name:       "zero input size avoids divide by zero",
			inputSize:  0,
			outputSize: 100,
			wantContains: []string{
				"completed artifact file transformation",
				"artifact_size_ratio=0",
				"artifact_size_change_bytes=100",
			},
		},
		{
			name:       "identical sizes yields ratio of 1",
			inputSize:  512,
			outputSize: 512,
			wantContains: []string{
				"artifact_size_ratio=1",
				"artifact_size_change_bytes=0",
			},
		},
	}

	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			tl := NewTransformLogger("tgz", tt.inputSize)
			ctx := context.Background()

			output := captureStandardLogOutput(t, func() {
				tl.LogComplete(ctx, tt.outputSize)
			})

			for _, want := range tt.wantContains {
				require.Contains(t, output, want)
			}
		})
	}
}

func TestTransformLoggerLogStartThenComplete(t *testing.T) {
	tl := NewTransformLogger("zip", 4096)
	ctx := context.Background()

	var startOutput, completeOutput string

	// We only care that LogStart records artifact_processing=true
	// and LogComplete records artifact_processing=false
	startOutput = captureStandardLogOutput(t, func() {
		tl.LogStart(ctx)
	})
	completeOutput = captureStandardLogOutput(t, func() {
		tl.LogComplete(ctx, 2048)
	})

	assert.Contains(t, startOutput, "artifact_processing=true", "LogStart should mark processing=true")
	assert.Contains(t, completeOutput, "artifact_processing=false", "LogComplete should mark processing=false")
}

func TestCountingWriter(t *testing.T) {
	tests := []struct {
		name      string
		writes    [][]byte
		wantCount int64
		wantData  string
	}{
		{
			name:      "single write",
			writes:    [][]byte{[]byte("hello")},
			wantCount: 5,
			wantData:  "hello",
		},
		{
			name:      "multiple writes accumulate count",
			writes:    [][]byte{[]byte("foo"), []byte("bar"), []byte("baz")},
			wantCount: 9,
			wantData:  "foobarbaz",
		},
		{
			name:      "empty write",
			writes:    [][]byte{{}},
			wantCount: 0,
			wantData:  "",
		},
	}

	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			buf := &bytes.Buffer{}
			cw := &CountingWriter{Writer: buf}

			for _, data := range tt.writes {
				n, err := cw.Write(data)
				require.NoError(t, err)
				assert.Equal(t, len(data), n)
			}

			assert.Equal(t, tt.wantCount, cw.Count)
			assert.Equal(t, tt.wantData, buf.String())
		})
	}
}

func TestCountingWriterPropagatesWriteError(t *testing.T) {
	cw := &CountingWriter{Writer: &errorWriter{}}

	n, err := cw.Write([]byte("data"))
	require.Error(t, err)
	assert.Zero(t, n)
	assert.Zero(t, cw.Count)
}

// errorWriter always returns an error on Write.
type errorWriter struct{}

func (e *errorWriter) Write(_ []byte) (int, error) {
	return 0, assert.AnError
}
