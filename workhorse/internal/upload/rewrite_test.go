package upload

import (
	"os"
	"runtime"
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
		}, {
			filename: "exif/testdata/takes_lot_of_memory_to_decode.tiff", // File from https://gitlab.com/gitlab-org/gitlab/-/issues/341363
			isJPEG:   false,
			isTIFF:   true,
		},
	}

	for _, test := range tests {
		t.Run(test.filename, func(t *testing.T) {
			input, err := os.Open(test.filename)
			require.NoError(t, err)

			var m runtime.MemStats
			runtime.ReadMemStats(&m)
			start := m.TotalAlloc

			require.Equal(t, test.isJPEG, isJPEG(input))
			require.Equal(t, test.isTIFF, isTIFF(input))

			runtime.ReadMemStats(&m)
			require.Less(t, m.TotalAlloc-start, uint64(50000), "must take reasonable amount of memory to recognise the type")
		})
	}
}
