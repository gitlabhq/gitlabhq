package healthcheck

import (
	"context"
	"fmt"
	"net/http"
	"net/http/httptest"
	"testing"
	"time"

	"github.com/sirupsen/logrus"
	"github.com/stretchr/testify/assert"
	"github.com/stretchr/testify/require"
)

// Test helper functions and constants

// createTestLogger creates a logger for tests with reduced noise
func createTestLogger() *logrus.Logger {
	logger := logrus.New()
	logger.SetLevel(logrus.ErrorLevel) // Reduce noise in tests
	return logger
}

// testServerConfig holds configuration for creating test servers
type testServerConfig struct {
	readinessResponse string
	readinessStatus   int
	controlResponse   string
	controlStatus     int
	delay             time.Duration
}

// createTestServers creates readiness and control servers based on config
func createTestServers(config testServerConfig) (*httptest.Server, *httptest.Server) {
	var readinessServer, controlServer *httptest.Server

	if config.readinessResponse != "" {
		readinessServer = httptest.NewServer(http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
			if config.delay > 0 {
				time.Sleep(config.delay)
			}
			if r.URL.Path == "/-/readiness" {
				w.WriteHeader(config.readinessStatus)
				w.Write([]byte(config.readinessResponse))
			} else {
				w.WriteHeader(http.StatusNotFound)
			}
		}))
	}

	if config.controlResponse != "" {
		controlServer = httptest.NewServer(http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
			if config.delay > 0 {
				time.Sleep(config.delay)
			}
			if r.URL.Path == "/stats" {
				w.WriteHeader(config.controlStatus)
				w.Write([]byte(config.controlResponse))
			} else {
				w.WriteHeader(http.StatusNotFound)
			}
		}))
	}

	return readinessServer, controlServer
}

// createPumaWorkerJSON creates a JSON string for a Puma worker with given parameters
func createPumaWorkerJSON(pid, index int, booted bool, running, poolCapacity, requestsCount int) string {
	bootedStr := "false"
	lastCheckin := `""`
	if booted {
		bootedStr = "true"
		lastCheckin = `"2021-01-14T07:11:09Z"`
	}

	return fmt.Sprintf(`{
		"started_at": "2021-01-14T07:09:24Z",
		"pid": %d,
		"index": %d,
		"phase": 0,
		"booted": %s,
		"last_checkin": %s,
		"last_status": {
			"backlog": 0,
			"running": %d,
			"pool_capacity": %d,
			"max_threads": 5,
			"requests_count": %d
		}
	}`, pid, index, bootedStr, lastCheckin, running, poolCapacity, requestsCount)
}

// createPumaControlResponse creates a complete Puma control server response
func createPumaControlResponse(totalWorkers, bootedWorkers int, workers []string) string {
	workersJSON := ""
	if len(workers) > 0 {
		workersJSON = workers[0]
		for i := 1; i < len(workers); i++ {
			workersJSON += "," + workers[i]
		}
	}

	return fmt.Sprintf(`{
		"started_at": "2021-01-14T07:09:17Z",
		"workers": %d,
		"phase": 0,
		"booted_workers": %d,
		"old_workers": 0,
		"worker_status": [%s]
	}`, totalWorkers, bootedWorkers, workersJSON)
}

// testExpectation holds expected test results
type testExpectation struct {
	healthy           bool
	hasError          bool
	errorContains     string
	readinessEndpoint bool
	controlServer     *bool // nil means not checked
	hasDurationFields bool
}

// assertCheckResult validates a CheckResult against expectations
func assertCheckResult(t *testing.T, result CheckResult, expected testExpectation) {
	t.Helper()

	assert.Equal(t, expected.healthy, result.Healthy)
	assert.Equal(t, "puma_readiness", result.Name)

	if expected.hasError {
		require.Error(t, result.Error)
		if expected.errorContains != "" {
			assert.Contains(t, result.Error.Error(), expected.errorContains)
		}
	} else {
		require.NoError(t, result.Error)
	}

	assert.Equal(t, expected.readinessEndpoint, result.Details["readiness_endpoint"].(bool))

	if expected.controlServer != nil {
		controlResult, hasControl := result.Details["control_server"]
		assert.True(t, hasControl)
		assert.Equal(t, *expected.controlServer, controlResult.(bool))
	} else {
		_, hasControl := result.Details["control_server"]
		assert.False(t, hasControl)
	}

	if expected.hasDurationFields {
		assert.Contains(t, result.Details, "readiness_duration_s")
		duration := result.Details["readiness_duration_s"].(float64)
		assert.GreaterOrEqual(t, duration, float64(0))

		if expected.controlServer != nil {
			assert.Contains(t, result.Details, "control_duration_s")
			controlDuration := result.Details["control_duration_s"].(float64)
			assert.GreaterOrEqual(t, controlDuration, float64(0))
		}
	}
}

// Test cases

func TestPumaReadinessChecker_Name(t *testing.T) {
	checker := NewPumaReadinessChecker("http://example.com/-/readiness", "", time.Second, createTestLogger())
	assert.Equal(t, "puma_readiness", checker.Name())
}

func TestPumaReadinessChecker_ReadinessEndpoint_Success(t *testing.T) {
	config := testServerConfig{
		readinessResponse: `{"status": "ok"}`,
		readinessStatus:   http.StatusOK,
	}
	readinessServer, _ := createTestServers(config)
	defer readinessServer.Close()

	checker := NewPumaReadinessChecker(readinessServer.URL+"/-/readiness", "", time.Second, createTestLogger())
	result := checker.Check(context.Background())

	expected := testExpectation{
		healthy:           true,
		hasError:          false,
		readinessEndpoint: true,
		hasDurationFields: true,
	}
	assertCheckResult(t, result, expected)
}

func TestPumaReadinessChecker_ReadinessEndpoint_PlainTextResponse(t *testing.T) {
	config := testServerConfig{
		readinessResponse: "OK",
		readinessStatus:   http.StatusOK,
	}
	readinessServer, _ := createTestServers(config)
	defer readinessServer.Close()

	checker := NewPumaReadinessChecker(readinessServer.URL+"/-/readiness", "", time.Second, createTestLogger())
	result := checker.Check(context.Background())

	expected := testExpectation{
		healthy:           true,
		hasError:          false,
		readinessEndpoint: true,
	}
	assertCheckResult(t, result, expected)
}

func TestPumaReadinessChecker_ReadinessEndpoint_JSONStatusNotOk(t *testing.T) {
	config := testServerConfig{
		readinessResponse: `{"status": "not_ready"}`,
		readinessStatus:   http.StatusOK,
	}
	readinessServer, _ := createTestServers(config)
	defer readinessServer.Close()

	checker := NewPumaReadinessChecker(readinessServer.URL+"/-/readiness", "", time.Second, createTestLogger())
	result := checker.Check(context.Background())

	expected := testExpectation{
		healthy:           false,
		hasError:          true,
		errorContains:     "puma readiness status is not_ready",
		readinessEndpoint: false,
	}
	assertCheckResult(t, result, expected)
}

func TestPumaReadinessChecker_ReadinessEndpoint_HTTPError(t *testing.T) {
	config := testServerConfig{
		readinessResponse: "Service Unavailable",
		readinessStatus:   http.StatusServiceUnavailable,
	}
	readinessServer, _ := createTestServers(config)
	defer readinessServer.Close()

	checker := NewPumaReadinessChecker(readinessServer.URL+"/-/readiness", "", time.Second, createTestLogger())
	result := checker.Check(context.Background())

	expected := testExpectation{
		healthy:           false,
		hasError:          true,
		errorContains:     "puma readiness returned status 503",
		readinessEndpoint: false,
	}
	assertCheckResult(t, result, expected)
}

func TestPumaReadinessChecker_ReadinessEndpoint_NetworkError(t *testing.T) {
	checker := NewPumaReadinessChecker("http://invalid-host:99999/-/readiness", "", time.Millisecond*100, createTestLogger())
	result := checker.Check(context.Background())

	expected := testExpectation{
		healthy:           false,
		hasError:          true,
		errorContains:     "puma readiness check failed",
		readinessEndpoint: false,
	}
	assertCheckResult(t, result, expected)
}

func TestPumaReadinessChecker_ControlServer_Success(t *testing.T) {
	workers := []string{
		createPumaWorkerJSON(64136, 0, true, 5, 5, 2),
		createPumaWorkerJSON(64137, 1, true, 5, 5, 1),
	}
	controlResponse := createPumaControlResponse(2, 2, workers)

	config := testServerConfig{
		readinessResponse: `{"status": "ok"}`,
		readinessStatus:   http.StatusOK,
		controlResponse:   controlResponse,
		controlStatus:     http.StatusOK,
	}
	readinessServer, controlServer := createTestServers(config)
	defer readinessServer.Close()
	defer controlServer.Close()

	checker := NewPumaReadinessChecker(
		readinessServer.URL+"/-/readiness",
		controlServer.URL,
		time.Second,
		createTestLogger(),
	)
	result := checker.Check(context.Background())

	controlHealthy := true
	expected := testExpectation{
		healthy:           true,
		hasError:          false,
		readinessEndpoint: true,
		controlServer:     &controlHealthy,
		hasDurationFields: true,
	}
	assertCheckResult(t, result, expected)
}

func TestPumaReadinessChecker_ControlServer_NoWorkersBooted(t *testing.T) {
	workers := []string{
		createPumaWorkerJSON(64136, 0, false, 0, 0, 0),
	}
	controlResponse := createPumaControlResponse(2, 0, workers)

	config := testServerConfig{
		readinessResponse: `{"status": "ok"}`,
		readinessStatus:   http.StatusOK,
		controlResponse:   controlResponse,
		controlStatus:     http.StatusOK,
	}
	readinessServer, controlServer := createTestServers(config)
	defer readinessServer.Close()
	defer controlServer.Close()

	checker := NewPumaReadinessChecker(
		readinessServer.URL+"/-/readiness",
		controlServer.URL,
		time.Second,
		createTestLogger(),
	)
	result := checker.Check(context.Background())

	controlHealthy := false
	expected := testExpectation{
		healthy:           false,
		hasError:          true,
		errorContains:     "no puma workers are booted (0/2)",
		readinessEndpoint: false,
		controlServer:     &controlHealthy,
	}
	assertCheckResult(t, result, expected)
}

func TestPumaReadinessChecker_ControlServer_SingleWorkerBooted(t *testing.T) {
	workers := []string{
		createPumaWorkerJSON(64136, 0, true, 5, 5, 2),
	}
	controlResponse := createPumaControlResponse(1, 1, workers)

	config := testServerConfig{
		readinessResponse: `{"status": "ok"}`,
		readinessStatus:   http.StatusOK,
		controlResponse:   controlResponse,
		controlStatus:     http.StatusOK,
	}
	readinessServer, controlServer := createTestServers(config)
	defer readinessServer.Close()
	defer controlServer.Close()

	checker := NewPumaReadinessChecker(
		readinessServer.URL+"/-/readiness",
		controlServer.URL,
		time.Second,
		createTestLogger(),
	)
	result := checker.Check(context.Background())

	controlHealthy := true
	expected := testExpectation{
		healthy:           true,
		hasError:          false,
		readinessEndpoint: true,
		controlServer:     &controlHealthy,
	}
	assertCheckResult(t, result, expected)
}

func TestPumaReadinessChecker_ControlServer_WorkerNotYetBooted(t *testing.T) {
	workers := []string{
		createPumaWorkerJSON(64136, 0, true, 5, 5, 2),
		createPumaWorkerJSON(64137, 1, true, 3, 5, 1),
		createPumaWorkerJSON(64138, 2, false, 0, 0, 0),
	}
	controlResponse := createPumaControlResponse(3, 2, workers)

	config := testServerConfig{
		readinessResponse: `{"status": "ok"}`,
		readinessStatus:   http.StatusOK,
		controlResponse:   controlResponse,
		controlStatus:     http.StatusOK,
	}
	readinessServer, controlServer := createTestServers(config)
	defer readinessServer.Close()
	defer controlServer.Close()

	checker := NewPumaReadinessChecker(
		readinessServer.URL+"/-/readiness",
		controlServer.URL,
		time.Second,
		createTestLogger(),
	)
	result := checker.Check(context.Background())

	controlHealthy := true
	expected := testExpectation{
		healthy:           true,
		hasError:          false,
		readinessEndpoint: true,
		controlServer:     &controlHealthy,
	}
	assertCheckResult(t, result, expected)
}

func TestPumaReadinessChecker_ControlServer_AllWorkersNotYetBooted(t *testing.T) {
	workers := []string{
		createPumaWorkerJSON(64136, 0, false, 0, 0, 0),
		createPumaWorkerJSON(64137, 1, false, 0, 0, 0),
	}
	controlResponse := createPumaControlResponse(2, 0, workers)

	config := testServerConfig{
		readinessResponse: `{"status": "ok"}`,
		readinessStatus:   http.StatusOK,
		controlResponse:   controlResponse,
		controlStatus:     http.StatusOK,
	}
	readinessServer, controlServer := createTestServers(config)
	defer readinessServer.Close()
	defer controlServer.Close()

	checker := NewPumaReadinessChecker(
		readinessServer.URL+"/-/readiness",
		controlServer.URL,
		time.Second,
		createTestLogger(),
	)
	result := checker.Check(context.Background())

	controlHealthy := false
	expected := testExpectation{
		healthy:           false,
		hasError:          true,
		errorContains:     "no puma workers are booted (0/2)",
		readinessEndpoint: false,
		controlServer:     &controlHealthy,
	}
	assertCheckResult(t, result, expected)
}

func TestPumaReadinessChecker_ControlServer_PartiallyBooted(t *testing.T) {
	workers := []string{
		createPumaWorkerJSON(64136, 0, true, 5, 5, 2),
		createPumaWorkerJSON(64137, 1, false, 0, 0, 0),
	}
	controlResponse := createPumaControlResponse(2, 1, workers)

	config := testServerConfig{
		readinessResponse: `{"status": "ok"}`,
		readinessStatus:   http.StatusOK,
		controlResponse:   controlResponse,
		controlStatus:     http.StatusOK,
	}
	readinessServer, controlServer := createTestServers(config)
	defer readinessServer.Close()
	defer controlServer.Close()

	checker := NewPumaReadinessChecker(
		readinessServer.URL+"/-/readiness",
		controlServer.URL,
		time.Second,
		createTestLogger(),
	)
	result := checker.Check(context.Background())

	controlHealthy := true
	expected := testExpectation{
		healthy:           true,
		hasError:          false,
		readinessEndpoint: true,
		controlServer:     &controlHealthy,
	}
	assertCheckResult(t, result, expected)
}

func TestPumaReadinessChecker_ControlServer_HTTPError(t *testing.T) {
	config := testServerConfig{
		readinessResponse: `{"status": "ok"}`,
		readinessStatus:   http.StatusOK,
		controlResponse:   "Internal Server Error",
		controlStatus:     http.StatusInternalServerError,
	}
	readinessServer, controlServer := createTestServers(config)
	defer readinessServer.Close()
	defer controlServer.Close()

	checker := NewPumaReadinessChecker(
		readinessServer.URL+"/-/readiness",
		controlServer.URL,
		time.Second,
		createTestLogger(),
	)
	result := checker.Check(context.Background())

	controlHealthy := false
	expected := testExpectation{
		healthy:           false,
		hasError:          true,
		errorContains:     "puma control server returned status 500",
		readinessEndpoint: false,
		controlServer:     &controlHealthy,
	}
	assertCheckResult(t, result, expected)
}

func TestPumaReadinessChecker_ControlServer_InvalidJSON(t *testing.T) {
	config := testServerConfig{
		readinessResponse: `{"status": "ok"}`,
		readinessStatus:   http.StatusOK,
		controlResponse:   "invalid json",
		controlStatus:     http.StatusOK,
	}
	readinessServer, controlServer := createTestServers(config)
	defer readinessServer.Close()
	defer controlServer.Close()

	checker := NewPumaReadinessChecker(
		readinessServer.URL+"/-/readiness",
		controlServer.URL,
		time.Second,
		createTestLogger(),
	)
	result := checker.Check(context.Background())

	controlHealthy := false
	expected := testExpectation{
		healthy:           false,
		hasError:          true,
		readinessEndpoint: false,
		controlServer:     &controlHealthy,
	}
	assertCheckResult(t, result, expected)
}

func TestPumaReadinessChecker_ControlServer_MismatchedWorkerCounts(t *testing.T) {
	// booted_workers reports 2, but only 1 worker is actually booted
	workers := []string{
		createPumaWorkerJSON(64136, 0, true, 5, 5, 2),
		createPumaWorkerJSON(64137, 1, false, 0, 0, 0),
	}
	controlResponse := createPumaControlResponse(2, 2, workers) // Reports 2 booted but only 1 actually is

	config := testServerConfig{
		readinessResponse: `{"status": "ok"}`,
		readinessStatus:   http.StatusOK,
		controlResponse:   controlResponse,
		controlStatus:     http.StatusOK,
	}
	readinessServer, controlServer := createTestServers(config)
	defer readinessServer.Close()
	defer controlServer.Close()

	checker := NewPumaReadinessChecker(
		readinessServer.URL+"/-/readiness",
		controlServer.URL,
		time.Second,
		createTestLogger(),
	)
	result := checker.Check(context.Background())

	controlHealthy := true
	expected := testExpectation{
		healthy:           true,
		hasError:          false,
		readinessEndpoint: true,
		controlServer:     &controlHealthy,
	}
	assertCheckResult(t, result, expected)
}

func TestPumaReadinessChecker_OnlyReadinessEndpoint(t *testing.T) {
	config := testServerConfig{
		readinessResponse: `{"status": "ok"}`,
		readinessStatus:   http.StatusOK,
	}
	readinessServer, _ := createTestServers(config)
	defer readinessServer.Close()

	checker := NewPumaReadinessChecker(readinessServer.URL+"/-/readiness", "", time.Second, createTestLogger())
	result := checker.Check(context.Background())

	expected := testExpectation{
		healthy:           true,
		hasError:          false,
		readinessEndpoint: true,
		controlServer:     nil, // Should not be present
	}
	assertCheckResult(t, result, expected)
}

func TestPumaReadinessChecker_ContextTimeout(t *testing.T) {
	config := testServerConfig{
		readinessResponse: `{"status": "ok"}`,
		readinessStatus:   http.StatusOK,
		delay:             200 * time.Millisecond,
	}
	readinessServer, _ := createTestServers(config)
	defer readinessServer.Close()

	checker := NewPumaReadinessChecker(readinessServer.URL+"/-/readiness", "", time.Second, createTestLogger())

	// Create a context that times out quickly
	ctx, cancel := context.WithTimeout(context.Background(), 50*time.Millisecond)
	defer cancel()

	result := checker.Check(ctx)

	expected := testExpectation{
		healthy:           false,
		hasError:          true,
		errorContains:     "puma readiness check failed",
		readinessEndpoint: false,
	}
	assertCheckResult(t, result, expected)
}

func TestPumaReadinessChecker_ReadinessFailsButControlSucceeds(t *testing.T) {
	workers := []string{
		createPumaWorkerJSON(64136, 0, true, 5, 5, 2),
	}
	controlResponse := createPumaControlResponse(1, 1, workers)

	config := testServerConfig{
		readinessResponse: "Service Unavailable",
		readinessStatus:   http.StatusServiceUnavailable,
		controlResponse:   controlResponse,
		controlStatus:     http.StatusOK,
	}
	readinessServer, controlServer := createTestServers(config)
	defer readinessServer.Close()
	defer controlServer.Close()

	checker := NewPumaReadinessChecker(
		readinessServer.URL+"/-/readiness",
		controlServer.URL,
		time.Second,
		createTestLogger(),
	)
	result := checker.Check(context.Background())

	controlHealthy := true
	expected := testExpectation{
		healthy:           false,
		hasError:          true,
		errorContains:     "puma readiness returned status 503",
		readinessEndpoint: false,
		controlServer:     &controlHealthy,
	}
	assertCheckResult(t, result, expected)
}
