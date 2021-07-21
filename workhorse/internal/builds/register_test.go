package builds

import (
	"bytes"
	"errors"
	"io"
	"net/http"
	"net/http/httptest"
	"strings"
	"testing"
	"time"

	"github.com/stretchr/testify/require"

	"gitlab.com/gitlab-org/gitlab/workhorse/internal/redis"
)

const upstreamResponseCode = 999

func echoRequest(rw http.ResponseWriter, req *http.Request) {
	rw.WriteHeader(upstreamResponseCode)
	io.Copy(rw, req.Body)
}

var echoRequestFunc = http.HandlerFunc(echoRequest)

func expectHandlerWithWatcher(t *testing.T, watchHandler WatchKeyHandler, data string, contentType string, expectedHttpStatus int, msgAndArgs ...interface{}) {
	h := RegisterHandler(echoRequestFunc, watchHandler, time.Second)

	rw := httptest.NewRecorder()
	req, _ := http.NewRequest("POST", "/", bytes.NewBufferString(data))
	req.Header.Set("Content-Type", contentType)

	h.ServeHTTP(rw, req)

	require.Equal(t, expectedHttpStatus, rw.Code, msgAndArgs...)
}

func expectHandler(t *testing.T, data string, contentType string, expectedHttpStatus int, msgAndArgs ...interface{}) {
	expectHandlerWithWatcher(t, nil, data, contentType, expectedHttpStatus, msgAndArgs...)
}

func TestRegisterHandlerLargeBody(t *testing.T) {
	data := strings.Repeat(".", maxRegisterBodySize+5)
	expectHandler(t, data, "application/json", http.StatusRequestEntityTooLarge,
		"rejects body with entity too large")
}

func TestRegisterHandlerInvalidRunnerRequest(t *testing.T) {
	expectHandler(t, "invalid content", "text/plain", upstreamResponseCode,
		"proxies request to upstream")
}

func TestRegisterHandlerInvalidJsonPayload(t *testing.T) {
	expectHandler(t, `{[`, "application/json", upstreamResponseCode,
		"fails on parsing body and proxies request to upstream")
}

func TestRegisterHandlerMissingData(t *testing.T) {
	testCases := []string{
		`{"token":"token"}`,
		`{"last_update":"data"}`,
	}

	for _, testCase := range testCases {
		expectHandler(t, testCase, "application/json", upstreamResponseCode,
			"fails on argument validation and proxies request to upstream")
	}
}

func expectWatcherToBeExecuted(t *testing.T, watchKeyStatus redis.WatchKeyStatus, watchKeyError error,
	httpStatus int, msgAndArgs ...interface{}) {
	executed := false
	watchKeyHandler := func(key, value string, timeout time.Duration) (redis.WatchKeyStatus, error) {
		executed = true
		return watchKeyStatus, watchKeyError
	}

	parsableData := `{"token":"token","last_update":"last_update"}`

	expectHandlerWithWatcher(t, watchKeyHandler, parsableData, "application/json", httpStatus, msgAndArgs...)
	require.True(t, executed, msgAndArgs...)
}

func TestRegisterHandlerWatcherError(t *testing.T) {
	expectWatcherToBeExecuted(t, redis.WatchKeyStatusNoChange, errors.New("redis connection"),
		upstreamResponseCode, "proxies data to upstream")
}

func TestRegisterHandlerWatcherAlreadyChanged(t *testing.T) {
	expectWatcherToBeExecuted(t, redis.WatchKeyStatusAlreadyChanged, nil,
		upstreamResponseCode, "proxies data to upstream")
}

func TestRegisterHandlerWatcherSeenChange(t *testing.T) {
	expectWatcherToBeExecuted(t, redis.WatchKeyStatusSeenChange, nil,
		http.StatusNoContent)
}

func TestRegisterHandlerWatcherTimeout(t *testing.T) {
	expectWatcherToBeExecuted(t, redis.WatchKeyStatusTimeout, nil,
		http.StatusNoContent)
}

func TestRegisterHandlerWatcherNoChange(t *testing.T) {
	expectWatcherToBeExecuted(t, redis.WatchKeyStatusNoChange, nil,
		http.StatusNoContent)
}
