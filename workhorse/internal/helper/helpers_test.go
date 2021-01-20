package helper

import (
	"bytes"
	"io"
	"net/http"
	"net/http/httptest"
	"testing"

	"github.com/stretchr/testify/require"
)

func TestFixRemoteAddr(t *testing.T) {
	testCases := []struct {
		initial   string
		forwarded string
		expected  string
	}{
		{initial: "@", forwarded: "", expected: "127.0.0.1:0"},
		{initial: "@", forwarded: "18.245.0.1", expected: "18.245.0.1:0"},
		{initial: "@", forwarded: "127.0.0.1", expected: "127.0.0.1:0"},
		{initial: "@", forwarded: "192.168.0.1", expected: "127.0.0.1:0"},
		{initial: "192.168.1.1:0", forwarded: "", expected: "192.168.1.1:0"},
		{initial: "192.168.1.1:0", forwarded: "18.245.0.1", expected: "18.245.0.1:0"},
	}

	for _, tc := range testCases {
		req, err := http.NewRequest("POST", "unix:///tmp/test.socket/info/refs", nil)
		require.NoError(t, err)

		req.RemoteAddr = tc.initial

		if tc.forwarded != "" {
			req.Header.Add("X-Forwarded-For", tc.forwarded)
		}

		FixRemoteAddr(req)

		require.Equal(t, tc.expected, req.RemoteAddr)
	}
}

func TestSetForwardedForGeneratesHeader(t *testing.T) {
	testCases := []struct {
		remoteAddr           string
		previousForwardedFor []string
		expected             string
	}{
		{
			"8.8.8.8:3000",
			nil,
			"8.8.8.8",
		},
		{
			"8.8.8.8:3000",
			[]string{"138.124.33.63, 151.146.211.237"},
			"138.124.33.63, 151.146.211.237, 8.8.8.8",
		},
		{
			"8.8.8.8:3000",
			[]string{"8.154.76.107", "115.206.118.179"},
			"8.154.76.107, 115.206.118.179, 8.8.8.8",
		},
	}
	for _, tc := range testCases {
		headers := http.Header{}
		originalRequest := http.Request{
			RemoteAddr: tc.remoteAddr,
		}

		if tc.previousForwardedFor != nil {
			originalRequest.Header = http.Header{
				"X-Forwarded-For": tc.previousForwardedFor,
			}
		}

		SetForwardedFor(&headers, &originalRequest)

		result := headers.Get("X-Forwarded-For")
		if result != tc.expected {
			t.Fatalf("Expected %v, got %v", tc.expected, result)
		}
	}
}

func TestReadRequestBody(t *testing.T) {
	data := []byte("123456")
	rw := httptest.NewRecorder()
	req, _ := http.NewRequest("POST", "/test", bytes.NewBuffer(data))

	result, err := ReadRequestBody(rw, req, 1000)
	require.NoError(t, err)
	require.Equal(t, data, result)
}

func TestReadRequestBodyLimit(t *testing.T) {
	data := []byte("123456")
	rw := httptest.NewRecorder()
	req, _ := http.NewRequest("POST", "/test", bytes.NewBuffer(data))

	_, err := ReadRequestBody(rw, req, 2)
	require.Error(t, err)
}

func TestCloneRequestWithBody(t *testing.T) {
	input := []byte("test")
	newInput := []byte("new body")
	req, _ := http.NewRequest("POST", "/test", bytes.NewBuffer(input))
	newReq := CloneRequestWithNewBody(req, newInput)

	require.NotEqual(t, req, newReq)
	require.NotEqual(t, req.Body, newReq.Body)
	require.NotEqual(t, len(newInput), newReq.ContentLength)

	var buffer bytes.Buffer
	io.Copy(&buffer, newReq.Body)
	require.Equal(t, newInput, buffer.Bytes())
}

func TestApplicationJson(t *testing.T) {
	req, _ := http.NewRequest("POST", "/test", nil)
	req.Header.Set("Content-Type", "application/json")

	require.True(t, IsApplicationJson(req), "expected to match 'application/json' as 'application/json'")

	req.Header.Set("Content-Type", "application/json; charset=utf-8")
	require.True(t, IsApplicationJson(req), "expected to match 'application/json; charset=utf-8' as 'application/json'")

	req.Header.Set("Content-Type", "text/plain")
	require.False(t, IsApplicationJson(req), "expected not to match 'text/plain' as 'application/json'")
}

func TestFail500WorksWithNils(t *testing.T) {
	body := bytes.NewBuffer(nil)
	w := httptest.NewRecorder()
	w.Body = body

	Fail500(w, nil, nil)

	require.Equal(t, http.StatusInternalServerError, w.Code)
	require.Equal(t, "Internal server error\n", body.String())
}
