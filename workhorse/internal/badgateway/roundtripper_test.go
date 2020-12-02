package badgateway

import (
	"errors"
	"io/ioutil"
	"net/http"
	"testing"

	"github.com/stretchr/testify/require"
)

type roundtrip502 struct{}

func (roundtrip502) RoundTrip(*http.Request) (*http.Response, error) {
	return nil, errors.New("something went wrong")
}

func TestErrorPage502(t *testing.T) {
	tests := []struct {
		name            string
		devMode         bool
		contentType     string
		responseSnippet string
	}{
		{
			name:            "production mode",
			contentType:     "text/plain",
			responseSnippet: "GitLab is not responding",
		},
		{
			name:            "development mode",
			devMode:         true,
			contentType:     "text/html",
			responseSnippet: "This page will automatically reload",
		},
	}

	for _, tc := range tests {
		t.Run(tc.name, func(t *testing.T) {
			req, err := http.NewRequest("GET", "/", nil)
			require.NoError(t, err, "build request")

			rt := NewRoundTripper(tc.devMode, roundtrip502{})
			response, err := rt.RoundTrip(req)
			require.NoError(t, err, "perform roundtrip")
			defer response.Body.Close()

			body, err := ioutil.ReadAll(response.Body)
			require.NoError(t, err)

			require.Equal(t, tc.contentType, response.Header.Get("content-type"), "content type")
			require.Equal(t, 502, response.StatusCode, "response status")
			require.Contains(t, string(body), tc.responseSnippet)
		})
	}
}
