package upload

import (
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
			require.Less(t, m.TotalAlloc-start, uint64(50000), "must take reasonable amount of memory to recognize the type")
		})
	}
}

func TestParseAndNormalizeContentDisposition(t *testing.T) {
	tests := []struct {
		desc            string
		header          string
		name            string
		filename        string
		sanitizedHeader string
	}{
		{
			desc:            "without content disposition",
			header:          "",
			name:            "",
			filename:        "",
			sanitizedHeader: "",
		}, {
			desc:            "content disposition without filename",
			header:          `form-data; name="filename"`,
			name:            "filename",
			filename:        "",
			sanitizedHeader: `form-data; name=filename`,
		}, {
			desc:            "with filename",
			header:          `form-data; name="file"; filename=foobar`,
			name:            "file",
			filename:        "foobar",
			sanitizedHeader: `form-data; filename=foobar; name=file`,
		}, {
			desc:            "with filename*",
			header:          `form-data; name="file"; filename*=UTF-8''bar`,
			name:            "file",
			filename:        "bar",
			sanitizedHeader: `form-data; filename=bar; name=file`,
		}, {
			desc:            "filename and filename*",
			header:          `form-data; name="file"; filename=foobar; filename*=UTF-8''bar`,
			name:            "file",
			filename:        "bar",
			sanitizedHeader: `form-data; filename=bar; name=file`,
		}, {
			desc:            "with empty filename",
			header:          `form-data; name="file"; filename=""`,
			name:            "file",
			filename:        "",
			sanitizedHeader: `form-data; filename=""; name=file`,
		}, {
			desc:            "with complex filename*",
			header:          `form-data; name="file"; filename*=UTF-8''viel%20Spa%C3%9F`,
			name:            "file",
			filename:        "viel Spaß",
			sanitizedHeader: `form-data; filename*=utf-8''viel%20Spa%C3%9F; name=file`,
		}, {
			desc:            "with unsupported charset",
			header:          `form-data; name="file"; filename*=UTF-16''bar`,
			name:            "file",
			filename:        "",
			sanitizedHeader: `form-data; name=file`,
		}, {
			desc:            "with filename and filename* with unsupported charset",
			header:          `form-data; name="file"; filename=foobar; filename*=UTF-16''bar`,
			name:            "file",
			filename:        "foobar",
			sanitizedHeader: `form-data; filename=foobar; name=file`,
		},
	}

	for _, testCase := range tests {
		t.Run(testCase.desc, func(t *testing.T) {
			h := make(textproto.MIMEHeader)
			h.Set("Content-Disposition", testCase.header)
			h.Set("Content-Type", "application/octet-stream")

			name, filename := parseAndNormalizeContentDisposition(h)

			require.Equal(t, testCase.name, name)
			require.Equal(t, testCase.filename, filename)
			require.Equal(t, testCase.sanitizedHeader, h.Get("Content-Disposition"))
		})
	}
}
