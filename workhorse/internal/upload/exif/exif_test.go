package exif

import (
	"context"
	"io"
	"os"
	"strings"
	"testing"

	"github.com/stretchr/testify/require"
)

func TestFileTypeFromSuffix(t *testing.T) {
	tests := []struct {
		name     string
		expected FileType
	}{
		{
			name:     "/full/path.jpg",
			expected: TypeJPEG,
		},
		{
			name:     "path.jpeg",
			expected: TypeJPEG,
		},
		{
			name:     "path.tiff",
			expected: TypeTIFF,
		},
		{
			name:     "path.JPG",
			expected: TypeJPEG,
		},
		{
			name:     "path.tar",
			expected: TypeUnknown,
		},
		{
			name:     "path",
			expected: TypeUnknown,
		},
		{
			name:     "something.jpg.py",
			expected: TypeUnknown,
		},
		{
			name:     "something.py.jpg",
			expected: TypeJPEG,
		},
		{
			name: `something.jpg
			.py`,
			expected: TypeUnknown,
		},
		{
			name: `something.something
			.jpg`,
			expected: TypeUnknown,
		},
	}
	for _, test := range tests {
		t.Run(test.name, func(t *testing.T) {
			require.Equal(t, test.expected, FileTypeFromSuffix(test.name))
		})
	}
}

func TestNewCleanerWithValidFile(t *testing.T) {
	input, err := os.Open("testdata/sample_exif.jpg")
	require.NoError(t, err)
	ctx, cancel := context.WithCancel(context.Background())
	defer cancel()

	cleaner, err := NewCleaner(ctx, input)
	require.NoError(t, err, "Expected no error when creating cleaner command")

	size, err := io.Copy(io.Discard, cleaner)
	require.NoError(t, err, "Expected no error when reading output")

	sizeAfterStrip := int64(25399)
	require.Equal(t, sizeAfterStrip, size, "Different size of converted image")
}

func TestNewCleanerWithInvalidFile(t *testing.T) {
	ctx, cancel := context.WithCancel(context.Background())
	defer cancel()

	cleaner, err := NewCleaner(ctx, strings.NewReader("invalid image"))
	require.NoError(t, err, "Expected no error when creating cleaner command")

	size, err := io.Copy(io.Discard, cleaner)
	require.Error(t, err, "Expected error when reading output")
	require.Equal(t, int64(0), size, "Size of invalid image should be 0")
}

func TestNewCleanerReadingAfterEOF(t *testing.T) {
	input, err := os.Open("testdata/sample_exif.jpg")
	require.NoError(t, err)
	ctx, cancel := context.WithCancel(context.Background())
	defer cancel()

	cleaner, err := NewCleaner(ctx, input)
	require.NoError(t, err, "Expected no error when creating cleaner command")

	_, err = io.Copy(io.Discard, cleaner)
	require.NoError(t, err, "Expected no error when reading output")

	buf := make([]byte, 1)
	size, err := cleaner.Read(buf)
	require.Equal(t, 0, size, "The output was already consumed by previous reads")
	require.Equal(t, io.EOF, err, "We return EOF")
}
