package sendfile

import (
	"io"
	"net/http"
	"net/http/httptest"
	"os"
	"testing"

	"github.com/stretchr/testify/require"

	"gitlab.com/gitlab-org/gitlab/workhorse/internal/headers"
)

const (
	fixturePath = "../../testdata/forgedfile.png"
)

func TestResponseWriter(t *testing.T) {
	upstreamResponse := "hello world"

	fixturePath := "testdata/sent-file.txt"
	fixtureContent, err := os.ReadFile(fixturePath)
	require.NoError(t, err)

	testCases := []struct {
		desc           string
		sendfileHeader string
		out            string
	}{
		{
			desc:           "send a file",
			sendfileHeader: fixturePath,
			out:            string(fixtureContent),
		},
		{
			desc:           "pass through unaltered",
			sendfileHeader: "",
			out:            upstreamResponse,
		},
	}

	for _, tc := range testCases {
		t.Run(tc.desc, func(t *testing.T) {
			r, err := http.NewRequest("GET", "/foo", nil)
			require.NoError(t, err)

			rw := httptest.NewRecorder()
			sf := &sendFileResponseWriter{rw: rw, req: r}
			sf.Header().Set(headers.XSendFileHeader, tc.sendfileHeader)

			upstreamBody := []byte(upstreamResponse)
			n, err := sf.Write(upstreamBody)
			require.NoError(t, err)
			require.Len(t, upstreamBody, n, "bytes written")

			rw.Flush()

			body := rw.Result().Body
			data, err := io.ReadAll(body)
			require.NoError(t, err)
			require.NoError(t, body.Close())

			require.Equal(t, tc.out, string(data))
		})
	}
}

func TestAllowExistentContentHeaders(t *testing.T) {
	httpHeaders := map[string]string{
		headers.ContentTypeHeader:        "image/png",
		headers.ContentDispositionHeader: "inline",
	}

	resp := makeRequest(t, fixturePath, httpHeaders)
	defer resp.Body.Close()
	require.Equal(t, "image/png", resp.Header.Get(headers.ContentTypeHeader))
	require.Equal(t, "inline", resp.Header.Get(headers.ContentDispositionHeader))
}

func TestSuccessOverrideContentHeadersFeatureEnabled(t *testing.T) {
	fixturePath := "../../testdata/forgedfile.png"

	httpHeaders := make(map[string]string)
	httpHeaders[headers.ContentTypeHeader] = "image/png"
	httpHeaders[headers.ContentDispositionHeader] = "inline"
	httpHeaders["Range"] = "bytes=1-2"

	resp := makeRequest(t, fixturePath, httpHeaders)
	defer resp.Body.Close()
	require.Equal(t, "image/png", resp.Header.Get(headers.ContentTypeHeader))
	require.Equal(t, "inline", resp.Header.Get(headers.ContentDispositionHeader))
}

func TestSuccessOverrideContentHeadersRangeRequestFeatureEnabled(t *testing.T) {
	fixtureContent, err := os.ReadFile(fixturePath)
	require.NoError(t, err)

	r, err := http.NewRequest("GET", "/foo", nil)
	r.Header.Set("Range", "bytes=1-2")
	require.NoError(t, err)

	rw := httptest.NewRecorder()
	sf := &sendFileResponseWriter{rw: rw, req: r}

	sf.Header().Set(headers.XSendFileHeader, fixturePath)
	sf.Header().Set(headers.ContentTypeHeader, "image/png")
	sf.Header().Set(headers.ContentDispositionHeader, "inline")
	sf.Header().Set(headers.GitlabWorkhorseDetectContentTypeHeader, "true")

	_, err = sf.Write(fixtureContent)
	require.NoError(t, err)

	rw.Flush()

	resp := rw.Result()
	body := resp.Body
	data, err := io.ReadAll(body)
	require.NoError(t, err)
	require.NoError(t, body.Close())

	require.Len(t, data, 2)

	require.Equal(t, "application/octet-stream", resp.Header.Get(headers.ContentTypeHeader))
	require.Equal(t, "attachment", resp.Header.Get(headers.ContentDispositionHeader))
}

func TestSuccessInlineWhitelistedTypesFeatureEnabled(t *testing.T) {
	fixtureImagePath := "../../testdata/image.png"

	httpHeaders := map[string]string{
		headers.ContentDispositionHeader:               "inline",
		headers.GitlabWorkhorseDetectContentTypeHeader: "true",
	}

	resp := makeRequest(t, fixtureImagePath, httpHeaders)
	defer resp.Body.Close()

	require.Equal(t, "image/png", resp.Header.Get(headers.ContentTypeHeader))
	require.Equal(t, "inline", resp.Header.Get(headers.ContentDispositionHeader))
}

func makeRequest(t *testing.T, fixturePath string, httpHeaders map[string]string) *http.Response {
	fixtureContent, err := os.ReadFile(fixturePath)
	require.NoError(t, err)

	r, err := http.NewRequest("GET", "/foo", nil)
	require.NoError(t, err)

	rw := httptest.NewRecorder()
	sf := &sendFileResponseWriter{rw: rw, req: r}

	sf.Header().Set(headers.XSendFileHeader, fixturePath)
	for name, value := range httpHeaders {
		sf.Header().Set(name, value)
	}

	upstreamBody := []byte("hello")
	n, err := sf.Write(upstreamBody)
	require.NoError(t, err)
	require.Len(t, upstreamBody, n, "bytes written")

	rw.Flush()

	resp := rw.Result()
	body := resp.Body
	data, err := io.ReadAll(body)
	require.NoError(t, err)
	require.NoError(t, body.Close())

	require.Equal(t, fixtureContent, data)

	return resp
}

func TestSendFileResponseWriterFlushable(t *testing.T) {
	rw := httptest.NewRecorder()
	sfrw := sendFileResponseWriter{rw: rw}

	rc := http.NewResponseController(&sfrw) //nolint:errcheck

	err := rc.Flush()
	require.NoError(t, err, "the underlying response writer is not flushable")
	require.True(t, rw.Flushed)
}
