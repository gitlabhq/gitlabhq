package imageresizer

import (
	"encoding/base64"
	"encoding/json"
	"image"
	"image/png"
	"io"
	"net/http"
	"net/http/httptest"
	"os"
	"testing"
	"time"

	"github.com/stretchr/testify/require"
	"gitlab.com/gitlab-org/labkit/log"

	"gitlab.com/gitlab-org/gitlab/workhorse/internal/config"
	"gitlab.com/gitlab-org/gitlab/workhorse/internal/testhelper"

	_ "image/jpeg" // need this for image.Decode with JPEG
)

const imagePath = "../../testdata/image.png"

func TestMain(m *testing.M) {
	if err := testhelper.BuildExecutables(); err != nil {
		log.WithError(err).Fatal()
	}

	os.Exit(m.Run())
}

func requestScaledImage(t *testing.T, httpHeaders http.Header, params resizeParams, cfg config.ImageResizerConfig) *http.Response {
	httpRequest := httptest.NewRequest("GET", "/image", nil)
	if httpHeaders != nil {
		httpRequest.Header = httpHeaders
	}
	responseWriter := httptest.NewRecorder()
	paramsJSON := encodeParams(t, &params)

	NewResizer(config.Config{ImageResizerConfig: cfg}).Inject(responseWriter, httpRequest, paramsJSON)

	return responseWriter.Result()
}

func TestRequestScaledImageFromPath(t *testing.T) {
	cfg := config.DefaultImageResizerConfig

	testCases := []struct {
		desc        string
		imagePath   string
		contentType string
	}{
		{
			desc:        "PNG",
			imagePath:   imagePath,
			contentType: "image/png",
		},
		{
			desc:        "JPEG",
			imagePath:   "../../testdata/image.jpg",
			contentType: "image/jpeg",
		},
		{
			desc:        "JPEG < 1kb",
			imagePath:   "../../testdata/image_single_pixel.jpg",
			contentType: "image/jpeg",
		},
	}

	for _, tc := range testCases {
		t.Run(tc.desc, func(t *testing.T) {
			params := resizeParams{Location: tc.imagePath, ContentType: tc.contentType, Width: 64}

			resp := requestScaledImage(t, nil, params, cfg)
			defer resp.Body.Close()
			require.Equal(t, http.StatusOK, resp.StatusCode)

			bounds := imageFromResponse(t, resp).Bounds()
			require.Equal(t, int(params.Width), bounds.Size().X, "wrong width after resizing")
		})
	}
}

func TestRequestScaledImageWithConditionalGetAndImageNotChanged(t *testing.T) {
	cfg := config.DefaultImageResizerConfig
	params := resizeParams{Location: imagePath, ContentType: "image/png", Width: 64}

	clientTime := testImageLastModified(t)
	header := http.Header{}
	header.Set("If-Modified-Since", httpTimeStr(clientTime))

	resp := requestScaledImage(t, header, params, cfg)
	defer resp.Body.Close()
	require.Equal(t, http.StatusNotModified, resp.StatusCode)
	require.Equal(t, httpTimeStr(testImageLastModified(t)), resp.Header.Get("Last-Modified"))
	require.Empty(t, resp.Header.Get("Content-Type"))
	require.Empty(t, resp.Header.Get("Content-Length"))
}

func TestRequestScaledImageWithConditionalGetAndImageChanged(t *testing.T) {
	cfg := config.DefaultImageResizerConfig
	params := resizeParams{Location: imagePath, ContentType: "image/png", Width: 64}

	clientTime := testImageLastModified(t).Add(-1 * time.Second)
	header := http.Header{}
	header.Set("If-Modified-Since", httpTimeStr(clientTime))

	resp := requestScaledImage(t, header, params, cfg)
	defer resp.Body.Close()
	require.Equal(t, http.StatusOK, resp.StatusCode)
	require.Equal(t, httpTimeStr(testImageLastModified(t)), resp.Header.Get("Last-Modified"))
}

func TestRequestScaledImageWithConditionalGetAndInvalidClientTime(t *testing.T) {
	cfg := config.DefaultImageResizerConfig
	params := resizeParams{Location: imagePath, ContentType: "image/png", Width: 64}

	header := http.Header{}
	header.Set("If-Modified-Since", "0")

	resp := requestScaledImage(t, header, params, cfg)
	defer resp.Body.Close()
	require.Equal(t, http.StatusOK, resp.StatusCode)
	require.Equal(t, httpTimeStr(testImageLastModified(t)), resp.Header.Get("Last-Modified"))
}

func TestServeOriginalImageWhenSourceImageTooLarge(t *testing.T) {
	originalImage := testImage(t)
	cfg := config.ImageResizerConfig{MaxScalerProcs: 1, MaxFilesize: 1}
	params := resizeParams{Location: imagePath, ContentType: "image/png", Width: 64}

	resp := requestScaledImage(t, nil, params, cfg)
	defer resp.Body.Close()
	require.Equal(t, http.StatusOK, resp.StatusCode)

	img := imageFromResponse(t, resp)
	require.Equal(t, originalImage.Bounds(), img.Bounds(), "expected original image size")
}

func TestFailFastOnOpenStreamFailure(t *testing.T) {
	cfg := config.DefaultImageResizerConfig
	params := resizeParams{Location: "does_not_exist.png", ContentType: "image/png", Width: 64}
	resp := requestScaledImage(t, nil, params, cfg)
	defer resp.Body.Close()

	require.Equal(t, http.StatusInternalServerError, resp.StatusCode)
}

func TestIgnoreContentTypeMismatchIfImageFormatIsAllowed(t *testing.T) {
	cfg := config.DefaultImageResizerConfig
	params := resizeParams{Location: imagePath, ContentType: "image/jpeg", Width: 64}
	resp := requestScaledImage(t, nil, params, cfg)
	defer resp.Body.Close()
	require.Equal(t, http.StatusOK, resp.StatusCode)

	bounds := imageFromResponse(t, resp).Bounds()
	require.Equal(t, int(params.Width), bounds.Size().X, "wrong width after resizing")
}

func TestUnpackParametersReturnsParamsInstanceForValidInput(t *testing.T) {
	r := Resizer{}
	inParams := resizeParams{Location: imagePath, Width: 64, ContentType: "image/png"}

	outParams, err := r.unpackParameters(encodeParams(t, &inParams))

	require.NoError(t, err, "unexpected error when unpacking params")
	require.Equal(t, inParams, *outParams)
}

func TestUnpackParametersReturnsErrorWhenLocationBlank(t *testing.T) {
	r := Resizer{}
	inParams := resizeParams{Location: "", Width: 64, ContentType: "image/jpg"}

	_, err := r.unpackParameters(encodeParams(t, &inParams))

	require.Error(t, err, "expected error when Location is blank")
}

func TestUnpackParametersReturnsErrorWhenContentTypeBlank(t *testing.T) {
	r := Resizer{}
	inParams := resizeParams{Location: imagePath, Width: 64, ContentType: ""}

	_, err := r.unpackParameters(encodeParams(t, &inParams))

	require.Error(t, err, "expected error when ContentType is blank")
}

func TestServeOriginalImageWhenSourceImageFormatIsNotAllowed(t *testing.T) {
	cfg := config.DefaultImageResizerConfig
	// SVG images are not allowed to be resized
	svgImagePath := "../../testdata/image.svg"
	svgImage, err := os.ReadFile(svgImagePath)
	require.NoError(t, err)
	// ContentType is no longer used to perform the format validation.
	// To make the test more strict, we'll use allowed, but incorrect ContentType.
	params := resizeParams{Location: svgImagePath, ContentType: "image/png", Width: 64}

	resp := requestScaledImage(t, nil, params, cfg)
	defer resp.Body.Close()
	require.Equal(t, http.StatusOK, resp.StatusCode)

	responseData, err := io.ReadAll(resp.Body)
	require.NoError(t, err)
	require.Equal(t, svgImage, responseData, "expected original image")
}

func TestServeOriginalImageWhenSourceImageIsTooSmall(t *testing.T) {
	content := []byte("PNG") // 3 bytes only, invalid as PNG/JPEG image

	img, err := os.CreateTemp("", "*.png")
	require.NoError(t, err)

	defer img.Close()
	defer os.Remove(img.Name())

	_, err = img.Write(content)
	require.NoError(t, err)

	cfg := config.DefaultImageResizerConfig
	params := resizeParams{Location: img.Name(), ContentType: "image/png", Width: 64}

	resp := requestScaledImage(t, nil, params, cfg)
	defer resp.Body.Close()
	require.Equal(t, http.StatusOK, resp.StatusCode)

	responseData, err := io.ReadAll(resp.Body)
	require.NoError(t, err)
	require.Equal(t, content, responseData, "expected original image")
}

// The Rails applications sends a Base64 encoded JSON string carrying
// these parameters in an HTTP response header
func encodeParams(t *testing.T, p *resizeParams) string {
	json, err := json.Marshal(*p)
	if err != nil {
		require.NoError(t, err, "JSON encoder encountered unexpected error")
	}
	return base64.StdEncoding.EncodeToString(json)
}

func testImage(t *testing.T) image.Image {
	f, err := os.Open(imagePath)
	require.NoError(t, err)

	image, err := png.Decode(f)
	require.NoError(t, err, "decode original image")

	return image
}

func testImageLastModified(t *testing.T) time.Time {
	fi, err := os.Stat(imagePath)
	require.NoError(t, err)

	return fi.ModTime()
}

func imageFromResponse(t *testing.T, resp *http.Response) image.Image {
	img, _, err := image.Decode(resp.Body)
	require.NoError(t, err, "decode resized image")
	return img
}

func httpTimeStr(time time.Time) string {
	return time.UTC().Format(http.TimeFormat)
}
