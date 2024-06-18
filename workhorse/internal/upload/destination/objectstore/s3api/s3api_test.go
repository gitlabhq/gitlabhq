package s3api

import (
	"testing"

	"github.com/stretchr/testify/require"
)

func TestCompleteMultipartUploadError(t *testing.T) {
	tests := []struct {
		name     string
		err      *CompleteMultipartUploadError
		expected string
	}{
		{
			name: "NoSuchKey error",
			err: &CompleteMultipartUploadError{
				Code:    "NoSuchKey",
				Message: "The specified key does not exist.",
			},
			expected: `CompleteMultipartUpload remote error "NoSuchKey": The specified key does not exist.`,
		},
		{
			name: "Empty code with message",
			err: &CompleteMultipartUploadError{
				Code:    "",
				Message: "The specified key does not exist.",
			},
			expected: `CompleteMultipartUpload remote error "": The specified key does not exist.`,
		},
		{
			name: "Empty message with code",
			err: &CompleteMultipartUploadError{
				Code:    "Some Code",
				Message: "The specified key does not exist.",
			},
			expected: `CompleteMultipartUpload remote error "Some Code": The specified key does not exist.`,
		},
		{
			name: "Empty code and message",
			err: &CompleteMultipartUploadError{
				Code:    "",
				Message: "",
			},
			expected: `CompleteMultipartUpload remote error "": `,
		},
	}

	for _, tc := range tests {
		t.Run(tc.name, func(t *testing.T) {
			require.Equal(t, tc.expected, tc.err.Error())
		})
	}
}
