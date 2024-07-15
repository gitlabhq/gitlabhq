package badgateway

import (
	"context"
	"errors"
	"io"
	"net/http"
	"net/http/httptest"
	"testing"

	"github.com/stretchr/testify/assert"
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

			body, err := io.ReadAll(response.Body)
			require.NoError(t, err)

			require.Equal(t, tc.contentType, response.Header.Get("content-type"), "content type")
			require.Equal(t, 502, response.StatusCode, "response status")
			require.Contains(t, string(body), tc.responseSnippet)
		})
	}
}

func TestClientDisconnect499(t *testing.T) {
	serverSync := make(chan struct{})
	ts := httptest.NewServer(http.HandlerFunc(func(http.ResponseWriter, *http.Request) {
		serverSync <- struct{}{}
		<-serverSync
	}))
	defer func() {
		close(serverSync)
		ts.Close()
	}()

	clientResponse := make(chan *http.Response)
	clientContext, clientCancel := context.WithCancel(context.Background())

	go func() {
		req, err := http.NewRequestWithContext(clientContext, "GET", ts.URL, nil)
		assert.NoError(t, err, "build request")

		rt := NewRoundTripper(false, http.DefaultTransport)
		response, err := rt.RoundTrip(req)
		assert.NoError(t, err, "perform roundtrip")
		assert.NoError(t, response.Body.Close())

		clientResponse <- response
	}()

	<-serverSync

	clientCancel()
	response := <-clientResponse
	require.Equal(t, 499, response.StatusCode, "response status")
}
