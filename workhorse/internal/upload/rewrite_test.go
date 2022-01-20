package upload

import (
	"mime/multipart"
	"net/textproto"
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

func TestVerifyContentDisposition(t *testing.T) {
	tests := []struct {
		desc               string
		contentDisposition string
		error              error
	}{
		{
			desc:               "without content disposition",
			contentDisposition: "",
			error:              nil,
		}, {
			desc:               "content disposition without filename",
			contentDisposition: `form-data; name="filename"`,
			error:              nil,
		}, {
			desc:               "with filename",
			contentDisposition: `form-data; name="file"; filename=foobar`,
			error:              ErrUnexpectedFilePart,
		}, {
			desc:               "with filename*",
			contentDisposition: `form-data; name="file"; filename*=UTF-8''foobar`,
			error:              ErrUnexpectedFilePart,
		}, {
			desc:               "filename and filename*",
			contentDisposition: `form-data; name="file"; filename=foobar; filename*=UTF-8''foobar`,
			error:              ErrUnexpectedFilePart,
		},
	}

	for _, testCase := range tests {
		t.Run(testCase.desc, func(t *testing.T) {
			h := make(textproto.MIMEHeader)

			if testCase.contentDisposition != "" {
				h.Set("Content-Disposition", testCase.contentDisposition)
				h.Set("Content-Type", "application/octet-stream")
			}

			require.Equal(t, testCase.error, verifyContentDisposition(&multipart.Part{Header: h}))
		})
	}

}
