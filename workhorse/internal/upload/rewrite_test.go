package upload

import (
	"os"
	"testing"

	"github.com/stretchr/testify/require"
)

func TestImageTypeRecongition(t *testing.T) {
	tests := []struct {
		filename string
		isJPEG   bool
		isTIFF   bool
	}{
		{
			filename: "exif/testdata/sample_exif.jpg",
			isJPEG:   true,
			isTIFF:   false,
		}, {
			filename: "exif/testdata/sample_exif.tiff",
			isJPEG:   false,
			isTIFF:   true,
		}, {
			filename: "exif/testdata/sample_exif_corrupted.jpg",
			isJPEG:   true,
			isTIFF:   false,
		}, {
			filename: "exif/testdata/sample_exif_invalid.jpg",
			isJPEG:   false,
			isTIFF:   false,
		},
	}

	for _, test := range tests {
		t.Run(test.filename, func(t *testing.T) {
			input, err := os.Open(test.filename)
			require.NoError(t, err)
			require.Equal(t, test.isJPEG, isJPEG(input))
			require.Equal(t, test.isTIFF, isTIFF(input))
		})
	}
}
