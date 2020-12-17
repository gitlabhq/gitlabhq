package api

import (
	"io/ioutil"
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
			out:         "Internal server error\n",
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
			require.Equal(t, len(upstreamBody), n, "bytes written")

			rw.Flush()

			body := rw.Result().Body
			data, err := ioutil.ReadAll(body)
			require.NoError(t, err)
			require.NoError(t, body.Close())

			require.Equal(t, tc.out, string(data))
		})
	}
}
