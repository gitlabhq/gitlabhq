package api

import (
	"io"
	"net/http"
	"net/http/httptest"
	"testing"

	"github.com/stretchr/testify/require"
)

func TestBlocker(t *testing.T) {
	upstreamResponse := "hello world"

	testCases := []struct {
		desc        string
		contentType string
		out         string
	}{
		{
			desc:        "blocked",
			contentType: ResponseContentType,
			out:         "Internal Server Error\n",
		},
		{
			desc:        "pass",
			contentType: "text/plain",
			out:         upstreamResponse,
		},
	}

	for _, tc := range testCases {
		t.Run(tc.desc, func(t *testing.T) {
			r, err := http.NewRequest("GET", "/foo", nil)
			require.NoError(t, err)

			rw := httptest.NewRecorder()
			bl := &blocker{rw: rw, r: r}
			bl.Header().Set("Content-Type", tc.contentType)

			upstreamBody := []byte(upstreamResponse)
			n, err := bl.Write(upstreamBody)
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

func TestBlockerFlushable(t *testing.T) {
	rw := httptest.NewRecorder()
	b := blocker{rw: rw}
	rc := http.NewResponseController(&b) //nolint:bodyclose

	err := rc.Flush()
	require.NoError(t, err, "the underlying response writer is not flushable")
	require.True(t, rw.Flushed)
}
