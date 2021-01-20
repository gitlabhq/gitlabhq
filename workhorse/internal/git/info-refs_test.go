package git

import (
	"net/http"
	"net/url"
	"testing"

	"github.com/stretchr/testify/require"
)

func TestIsSmartInfoRefs(t *testing.T) {
	testCases := []struct {
		method string
		url    string
		match  bool
	}{
		{"GET", "?service=git-upload-pack", true},
		{"GET", "?service=git-receive-pack", true},
		{"GET", "", false},
		{"GET", "?service=", false},
		{"GET", "?service=foo", false},
		{"POST", "?service=git-upload-pack", false},
		{"POST", "?service=git-receive-pack", false},
	}

	for _, tc := range testCases {
		url, err := url.Parse(tc.url)
		require.NoError(t, err)

		r := http.Request{Method: tc.method, URL: url}
		require.Equal(t, tc.match, IsSmartInfoRefs(&r))
	}
}
