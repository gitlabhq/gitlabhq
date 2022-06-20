package png

import (
	"bytes"
	"hash/crc64"
	"image"
	"io"
	"os"
	"testing"

	_ "image/jpeg" // registers JPEG format for image.Decode
	"image/png"    // registers PNG format for image.Decode

	"github.com/stretchr/testify/require"
)

const (
	goodPNG     = "../../../testdata/image.png"
	badPNG      = "../../../testdata/image_bad_iccp.png"
	strippedPNG = "../../../testdata/image_stripped_iccp.png"
	jpg         = "../../../testdata/image.jpg"
)

func TestReadImageUnchanged(t *testing.T) {
	testCases := []struct {
		desc      string
		imagePath string
		imageType string
	}{
		{
			desc:      "image is not a PNG",
			imagePath: jpg,
			imageType: "jpeg",
		},
		{
			desc:      "image is PNG without iCCP chunk",
			imagePath: goodPNG,
			imageType: "png",
		},
	}

	for _, tc := range testCases {
		t.Run(tc.desc, func(t *testing.T) {
			requireValidImage(t, pngReader(t, tc.imagePath), tc.imageType)
			requireStreamUnchanged(t, pngReader(t, tc.imagePath), rawImageReader(t, tc.imagePath))
		})
	}
}

func TestReadPNGWithBadICCPChunkDecodesAndReEncodesSuccessfully(t *testing.T) {
	badPNGBytes, fmt, err := image.Decode(pngReader(t, badPNG))
	require.NoError(t, err)
	require.Equal(t, "png", fmt)

	strippedPNGBytes, fmt, err := image.Decode(pngReader(t, strippedPNG))
	require.NoError(t, err)
	require.Equal(t, "png", fmt)

	buf1 := new(bytes.Buffer)
	buf2 := new(bytes.Buffer)

	require.NoError(t, png.Encode(buf1, badPNGBytes))
	require.NoError(t, png.Encode(buf2, strippedPNGBytes))

	requireStreamUnchanged(t, buf1, buf2)
}

func pngReader(t *testing.T, path string) io.Reader {
	r, err := NewReader(rawImageReader(t, path))
	require.NoError(t, err)
	return r
}

func rawImageReader(t *testing.T, path string) io.Reader {
	f, err := os.Open(path)
	require.NoError(t, err)
	return f
}

func requireValidImage(t *testing.T, r io.Reader, expected string) {
	_, fmt, err := image.Decode(r)
	require.NoError(t, err)
	require.Equal(t, expected, fmt)
}

func requireStreamUnchanged(t *testing.T, actual io.Reader, expected io.Reader) {
	actualBytes, err := io.ReadAll(actual)
	require.NoError(t, err)
	expectedBytes, err := io.ReadAll(expected)
	require.NoError(t, err)

	table := crc64.MakeTable(crc64.ISO)
	sumActual := crc64.Checksum(actualBytes, table)
	sumExpected := crc64.Checksum(expectedBytes, table)
	require.Equal(t, sumExpected, sumActual)
}
