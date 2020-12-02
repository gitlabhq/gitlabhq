package main

import (
	"io"
	"net/http"
	"net/http/httptest"
	"testing"
	"time"

	"github.com/stretchr/testify/require"
)

func startWorkhorseServerWithLongPolling(authBackend string, pollingDuration time.Duration) *httptest.Server {
	uc := newUpstreamConfig(authBackend)
	uc.APICILongPollingDuration = pollingDuration
	return startWorkhorseServerWithConfig(uc)
}

type requestJobFunction func(url string, body io.Reader) (*http.Response, error)

func requestJobV1(url string, body io.Reader) (*http.Response, error) {
	resource := `/ci/api/v1/builds/register.json`
	return http.Post(url+resource, `application/json`, body)
}

func requestJobV4(url string, body io.Reader) (*http.Response, error) {
	resource := `/api/v4/jobs/request`
	return http.Post(url+resource, `application/json`, body)
}

func testJobsLongPolling(t *testing.T, pollingDuration time.Duration, requestJob requestJobFunction) *http.Response {
	ws := startWorkhorseServerWithLongPolling("http://localhost/", pollingDuration)
	defer ws.Close()

	resp, err := requestJob(ws.URL, nil)
	require.NoError(t, err)
	defer resp.Body.Close()

	return resp
}

func testJobsLongPollingEndpointDisabled(t *testing.T, requestJob requestJobFunction) {
	resp := testJobsLongPolling(t, 0, requestJob)
	require.NotEqual(t, "yes", resp.Header.Get("Gitlab-Ci-Builds-Polling"))
}

func testJobsLongPollingEndpoint(t *testing.T, requestJob requestJobFunction) {
	resp := testJobsLongPolling(t, time.Minute, requestJob)
	require.Equal(t, "yes", resp.Header.Get("Gitlab-Ci-Builds-Polling"))
}

func TestJobsLongPollingEndpointDisabled(t *testing.T) {
	testJobsLongPollingEndpointDisabled(t, requestJobV1)
	testJobsLongPollingEndpointDisabled(t, requestJobV4)
}

func TestJobsLongPollingEndpoint(t *testing.T) {
	testJobsLongPollingEndpoint(t, requestJobV1)
	testJobsLongPollingEndpoint(t, requestJobV4)
}
