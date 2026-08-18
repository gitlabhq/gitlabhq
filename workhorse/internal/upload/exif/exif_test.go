package exif

import (
	"context"
	"fmt"
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
	defer cleaner.Close()

	size, err := io.Copy(io.Discard, cleaner)
	require.NoError(t, err, "Expected no error when reading output")

	sizeAfterStrip := int64(22464)
	require.Equal(t, sizeAfterStrip, size, "Different size of converted image")
}

func TestNewCleanerWithInvalidFile(t *testing.T) {
	ctx, cancel := context.WithCancel(context.Background())
	defer cancel()

	cleaner, err := NewCleaner(ctx, strings.NewReader("invalid image"))
	require.NoError(t, err, "Expected no error when creating cleaner command")
	defer cleaner.Close()

	// The prestrip pass fails on a non-image, and the failure is not the malformed-offset
	// signature, so it surfaces when draining the stream.
	_, err = io.Copy(io.Discard, cleaner)
	require.ErrorIs(t, err, ErrRemovingExif, "Expected error when reading output")
}

func TestNewCleanerFallsBackToFullStripOnBrokenOffset(t *testing.T) {
	input, err := os.Open("testdata/sample_exif_broken_offset.jpg")
	require.NoError(t, err)
	defer input.Close()

	ctx, cancel := context.WithCancel(context.Background())
	defer cancel()

	// The prestrip pass fails on this image with an OtherImageStart offset error. Instead of
	// rejecting the upload we fall back to a plain full strip, which succeeds.
	cleaner, err := NewCleaner(ctx, input)
	require.NoError(t, err, "Expected no error when creating cleaner command")
	defer cleaner.Close()

	size, err := io.Copy(io.Discard, cleaner)
	require.NoError(t, err, "Expected the full-strip fallback to succeed")
	require.Positive(t, size, "Expected non-empty stripped output")
}

// payloadPerPassReader serves a different payload on each pass over the input. The cleaner
// rewinds its input before the fallback strip, so this lets a test feed exiftool one payload
// that fails the prestrip with the malformed-offset signature and another that fails the
// fallback strip too.
type payloadPerPassReader struct {
	passes [][]byte
	pass   int
	pos    int
}

func (r *payloadPerPassReader) Read(p []byte) (int, error) {
	payload := r.passes[r.pass]
	if r.pos >= len(payload) {
		return 0, io.EOF
	}

	n := copy(p, payload[r.pos:])
	r.pos += n

	return n, nil
}

func (r *payloadPerPassReader) Seek(offset int64, whence int) (int64, error) {
	if offset != 0 || whence != io.SeekStart {
		return 0, fmt.Errorf("unexpected seek to offset %d whence %d", offset, whence)
	}

	// Only move on once the current payload has been read, so the rewind before the prestrip
	// leaves the first payload in place.
	if r.pos > 0 && r.pass < len(r.passes)-1 {
		r.pass++
	}
	r.pos = 0

	return 0, nil
}

func TestNewCleanerWhenFallbackFullStripFails(t *testing.T) {
	brokenOffset, err := os.ReadFile("testdata/sample_exif_broken_offset.jpg")
	require.NoError(t, err)

	ctx, cancel := context.WithCancel(context.Background())
	defer cancel()

	// The prestrip fails with the malformed-offset signature, so we fall back to the full strip,
	// but the fallback is handed bytes exiftool cannot write either.
	input := &payloadPerPassReader{passes: [][]byte{brokenOffset, []byte("invalid image")}}

	cleaner, err := NewCleaner(ctx, input)
	require.NoError(t, err, "The fallback strip only fails once it exits, not when it is started")
	defer cleaner.Close()

	_, err = io.Copy(io.Discard, cleaner)
	require.ErrorIs(t, err, ErrRemovingExif, "Expected the fallback strip failure to surface")
}

func TestShouldFallBack(t *testing.T) {
	offsetErr := fmt.Errorf("exit status 1")

	tests := []struct {
		name        string
		preStripErr error
		stderr      string
		fellBack    bool
		bytesRead   int64
		expected    bool
	}{
		{
			name:        "malformed offset error with no output delivered",
			preStripErr: offsetErr,
			stderr:      "Error reading OtherImageStart data in IFD0",
			expected:    true,
		},
		{
			name:     "prestrip succeeded",
			stderr:   "Error reading OtherImageStart data in IFD0",
			expected: false,
		},
		{
			name:        "error without the malformed offset signature",
			preStripErr: offsetErr,
			stderr:      "Error: Writing of this type of file is not supported",
			expected:    false,
		},
		{
			name:        "already fell back once",
			preStripErr: offsetErr,
			stderr:      "Error reading OtherImageStart data in IFD0",
			fellBack:    true,
			expected:    false,
		},
		{
			name:        "partial output already delivered to the caller",
			preStripErr: offsetErr,
			stderr:      "Error reading OtherImageStart data in IFD0",
			bytesRead:   1,
			expected:    false,
		},
	}

	for _, test := range tests {
		t.Run(test.name, func(t *testing.T) {
			c := &cleaner{fellBack: test.fellBack, bytesRead: test.bytesRead}
			c.preStripStderr.WriteString(test.stderr)

			require.Equal(t, test.expected, c.shouldFallBack(test.preStripErr))
		})
	}
}

func TestNewCleanerReadingAfterEOF(t *testing.T) {
	input, err := os.Open("testdata/sample_exif.jpg")
	require.NoError(t, err)
	ctx, cancel := context.WithCancel(context.Background())
	defer cancel()

	cleaner, err := NewCleaner(ctx, input)
	require.NoError(t, err, "Expected no error when creating cleaner command")
	defer cleaner.Close()

	_, err = io.Copy(io.Discard, cleaner)
	require.NoError(t, err, "Expected no error when reading output")

	buf := make([]byte, 1)
	size, err := cleaner.Read(buf)
	require.Equal(t, 0, size, "The output was already consumed by previous reads")
	require.Equal(t, io.EOF, err, "We return EOF")
}
