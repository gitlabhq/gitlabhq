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

// TestPumaReadinessChecker_SuccessOptimization_ControlAlwaysScraped tests that
// the control server is always checked, but readiness endpoint can be skipped
func TestPumaReadinessChecker_SuccessOptimization_ControlAlwaysScraped(t *testing.T) {
	logger := logrus.New()
	logger.SetLevel(logrus.DebugLevel)

	// Track calls to each endpoint
	readinessCallCount := 0
	controlCallCount := 0

	// Create mock servers that count calls
	readinessServer := httptest.NewServer(http.HandlerFunc(func(w http.ResponseWriter, _ *http.Request) {
		readinessCallCount++
		w.Header().Set("Content-Type", "application/json")
		w.WriteHeader(http.StatusOK)
		w.Write([]byte(`{"status": "ok"}`))
	}))
	defer readinessServer.Close()

	controlServer := httptest.NewServer(http.HandlerFunc(func(w http.ResponseWriter, _ *http.Request) {
		controlCallCount++
		w.Header().Set("Content-Type", "application/json")
		w.WriteHeader(http.StatusOK)
		w.Write([]byte(`{
			"workers": 2,
			"booted_workers": 2,
			"worker_status": [
				{"booted": true, "index": 0},
				{"booted": true, "index": 1}
			]
		}`))
	}))
	defer controlServer.Close()

	successTracker := NewSuccessTracker()
	skipInterval := 100 * time.Millisecond

	checker := NewPumaReadinessChecker(
		readinessServer.URL+"/-/readiness",
		controlServer.URL,
		5*time.Second,
		logger,
		WithSuccessChecker(successTracker),
		WithSkipInterval(skipInterval),
	)

	ctx := context.Background()

	// Test 1: Initial check - both endpoints should be called
	initialReadinessCalls := readinessCallCount
	initialControlCalls := controlCallCount

	result := checker.Check(ctx)
	assert.True(t, result.Healthy, "Expected healthy result for initial check")
	assert.False(t, result.Details["skipped_due_to_recent_success"].(bool), "Should not skip initial check")
	assert.True(t, result.Details["readiness_endpoint"].(bool), "Should have checked readiness endpoint")
	assert.True(t, result.Details["control_server"].(bool), "Should have checked control server")
	assert.Greater(t, readinessCallCount, initialReadinessCalls, "Should have made readiness endpoint call")
	assert.Greater(t, controlCallCount, initialControlCalls, "Should have made control endpoint call")

	// Test 2: Record recent success - readiness should be skipped, control should still be checked
	successTracker.RecordSuccess()

	readinessCallsBeforeSkip := readinessCallCount
	controlCallsBeforeSkip := controlCallCount

	result = checker.Check(ctx)
	assert.True(t, result.Healthy, "Expected healthy result when skipping readiness")
	assert.True(t, result.Details["skipped_due_to_recent_success"].(bool), "Should skip readiness check due to recent success")
	assert.True(t, result.Details["readiness_endpoint"].(bool), "Should report readiness endpoint as healthy when skipping")
	assert.True(t, result.Details["control_server"].(bool), "Should report control server as healthy")

	// Critical assertions: readiness should be skipped, control should still be called
	assert.Equal(t, readinessCallsBeforeSkip, readinessCallCount, "Should NOT have made additional readiness calls when skipping")
	assert.Greater(t, controlCallCount, controlCallsBeforeSkip, "Should STILL have made control server call even when skipping readiness")

	// Test 3: Multiple checks with recent success - control should be called each time, readiness should not
	controlCallsAfterFirstSkip := controlCallCount

	// Make another check while success is still recent
	result = checker.Check(ctx)
	assert.True(t, result.Healthy, "Expected healthy result for second skip")
	assert.True(t, result.Details["skipped_due_to_recent_success"].(bool), "Should still skip readiness check")
	assert.Equal(t, readinessCallsBeforeSkip, readinessCallCount, "Should still NOT have made readiness calls")
	assert.Greater(t, controlCallCount, controlCallsAfterFirstSkip, "Should have made another control server call")

	t.Logf("Final counts - Readiness calls: %d, Control calls: %d", readinessCallCount, controlCallCount)
	t.Logf("Control server was called %d times while readiness was skipped", controlCallCount-controlCallsBeforeSkip)
}

// TestPumaReadinessChecker_SuccessOptimization_ControlFailurePreventsReadinessSkip tests that
// if the control server fails, readiness endpoint is not skipped regardless of recent success
func TestPumaReadinessChecker_SuccessOptimization_ControlFailurePreventsReadinessSkip(t *testing.T) {
	logger := logrus.New()
	logger.SetLevel(logrus.DebugLevel)

	readinessCallCount := 0
	controlCallCount := 0

	// Create a readiness server that works
	readinessServer := httptest.NewServer(http.HandlerFunc(func(w http.ResponseWriter, _ *http.Request) {
		readinessCallCount++
		w.Header().Set("Content-Type", "application/json")
		w.WriteHeader(http.StatusOK)
		w.Write([]byte(`{"status": "ok"}`))
	}))
	defer readinessServer.Close()

	// Create a control server that fails
	controlServer := httptest.NewServer(http.HandlerFunc(func(w http.ResponseWriter, _ *http.Request) {
		controlCallCount++
		w.WriteHeader(http.StatusInternalServerError)
		w.Write([]byte("Internal Server Error"))
	}))
	defer controlServer.Close()

	successTracker := NewSuccessTracker()
	skipInterval := 100 * time.Millisecond

	checker := NewPumaReadinessChecker(
		readinessServer.URL+"/-/readiness",
		controlServer.URL,
		5*time.Second,
		logger,
		WithSuccessChecker(successTracker),
		WithSkipInterval(skipInterval),
	)

	ctx := context.Background()

	// Record recent success
	successTracker.RecordSuccess()

	// Even with recent success, if control server fails, readiness should not be skipped
	result := checker.Check(ctx)

	assert.False(t, result.Healthy, "Expected unhealthy result when control server fails")
	assert.False(t, result.Details["skipped_due_to_recent_success"].(bool), "Should not skip when control server fails")
	assert.False(t, result.Details["readiness_endpoint"].(bool), "Should not check readiness when control fails")
	assert.False(t, result.Details["control_server"].(bool), "Should report control server as unhealthy")
	assert.Positive(t, controlCallCount, "Should have attempted control server call")
	assert.Equal(t, 0, readinessCallCount, "Should not have called readiness when control fails")
}

// TestPumaReadinessChecker_SuccessOptimization_NoControlServer tests that
// when no control server is configured, readiness optimization still works
func TestPumaReadinessChecker_SuccessOptimization_NoControlServer(t *testing.T) {
	logger := logrus.New()
	logger.SetLevel(logrus.DebugLevel)

	readinessCallCount := 0

	readinessServer := httptest.NewServer(http.HandlerFunc(func(w http.ResponseWriter, _ *http.Request) {
		readinessCallCount++
		w.Header().Set("Content-Type", "application/json")
		w.WriteHeader(http.StatusOK)
		w.Write([]byte(`{"status": "ok"}`))
	}))
	defer readinessServer.Close()

	successTracker := NewSuccessTracker()
	skipInterval := 100 * time.Millisecond

	// No control server configured
	checker := NewPumaReadinessChecker(
		readinessServer.URL+"/-/readiness",
		"", // No control URL
		5*time.Second,
		logger,
		WithSuccessChecker(successTracker),
		WithSkipInterval(skipInterval),
	)

	ctx := context.Background()

	// Test 1: Initial check should call readiness endpoint
	result := checker.Check(ctx)
	assert.True(t, result.Healthy, "Expected healthy result for initial check")
	assert.False(t, result.Details["skipped_due_to_recent_success"].(bool), "Should not skip initial check")
	assert.True(t, result.Details["readiness_endpoint"].(bool), "Should have checked readiness endpoint")
	assert.Equal(t, 1, readinessCallCount, "Should have made one readiness call")

	// Test 2: Record success and verify readiness is skipped
	successTracker.RecordSuccess()

	result = checker.Check(ctx)
	assert.True(t, result.Healthy, "Expected healthy result when skipping")
	assert.True(t, result.Details["skipped_due_to_recent_success"].(bool), "Should skip readiness check")
	assert.True(t, result.Details["readiness_endpoint"].(bool), "Should report readiness as healthy when skipping")
	assert.Equal(t, 1, readinessCallCount, "Should not have made additional readiness calls")

	// Test 3: Wait for skip interval to expire
	time.Sleep(skipInterval + 10*time.Millisecond)

	result = checker.Check(ctx)
	assert.True(t, result.Healthy, "Expected healthy result after skip expires")
	assert.False(t, result.Details["skipped_due_to_recent_success"].(bool), "Should not skip after interval expires")
	assert.True(t, result.Details["readiness_endpoint"].(bool), "Should have checked readiness endpoint")
	assert.Equal(t, 2, readinessCallCount, "Should have made another readiness call")
}

func TestPumaReadinessChecker_WithSuccessTracking(t *testing.T) {
	logger := logrus.New()
	logger.SetLevel(logrus.DebugLevel)

	// Create a mock server for readiness endpoint
	readinessServer := httptest.NewServer(http.HandlerFunc(func(w http.ResponseWriter, _ *http.Request) {
		w.Header().Set("Content-Type", "application/json")
		w.WriteHeader(http.StatusOK)
		w.Write([]byte(`{"status": "ok"}`))
	}))
	defer readinessServer.Close()

	// Create a mock server for control endpoint
	controlServer := httptest.NewServer(http.HandlerFunc(func(w http.ResponseWriter, _ *http.Request) {
		w.Header().Set("Content-Type", "application/json")
		w.WriteHeader(http.StatusOK)
		w.Write([]byte(`{
			"workers": 2,
			"booted_workers": 2,
			"worker_status": [
				{"booted": true, "index": 0},
				{"booted": true, "index": 1}
			]
		}`))
	}))
	defer controlServer.Close()

	successTracker := NewSuccessTracker()
	skipInterval := 100 * time.Millisecond

	checker := NewPumaReadinessChecker(
		readinessServer.URL,
		controlServer.URL,
		5*time.Second,
		logger,
		WithSuccessChecker(successTracker),
		WithSkipInterval(skipInterval),
	)

	ctx := context.Background()

	// Test 1: No recent success - should perform actual checks
	result := checker.Check(ctx)
	if !result.Healthy {
		t.Error("Expected healthy result when no recent success")
	}
	if result.Details["skipped_due_to_recent_success"] == true {
		t.Error("Should not skip checks when no recent success")
	}
	if result.Details["readiness_endpoint"] != true {
		t.Error("Should have checked readiness endpoint")
	}
	if result.Details["control_server"] != true {
		t.Error("Should have checked control server")
	}

	// Test 2: Record a recent success - should skip checks
	successTracker.RecordSuccess()
	result = checker.Check(ctx)
	if !result.Healthy {
		t.Error("Expected healthy result when skipping due to recent success")
	}
	if result.Details["skipped_due_to_recent_success"] != true {
		t.Error("Should skip checks when there's recent success")
	}
	if result.Details["control_server"] != true {
		t.Error("Should report control server as healthy when skipping")
	}

	// Test 3: Wait for skip interval to expire - should perform checks again
	time.Sleep(skipInterval + 10*time.Millisecond)
	result = checker.Check(ctx)
	if !result.Healthy {
		t.Error("Expected healthy result after skip interval expires")
	}
	if result.Details["skipped_due_to_recent_success"] == true {
		t.Error("Should not skip checks after skip interval expires")
	}
	if result.Details["readiness_endpoint"] != true {
		t.Error("Should have checked readiness endpoint after skip interval expires")
	}
}

func TestPumaReadinessChecker_WithoutSuccessTracking(t *testing.T) {
	logger := logrus.New()

	// Create a mock server for readiness endpoint
	readinessServer := httptest.NewServer(http.HandlerFunc(func(w http.ResponseWriter, _ *http.Request) {
		w.Header().Set("Content-Type", "application/json")
		w.WriteHeader(http.StatusOK)
		w.Write([]byte(`{"status": "ok"}`))
	}))
	defer readinessServer.Close()

	// Create checker without success tracking (no options)
	checker := NewPumaReadinessChecker(
		readinessServer.URL,
		"",
		5*time.Second,
		logger,
	)

	ctx := context.Background()

	// Should always perform checks when no success tracking is configured
	result := checker.Check(ctx)
	if !result.Healthy {
		t.Error("Expected healthy result")
	}
	if result.Details["skipped_due_to_recent_success"] == true {
		t.Error("Should never skip checks when success tracking is not configured")
	}
	if result.Details["readiness_endpoint"] != true {
		t.Error("Should have checked readiness endpoint")
	}
}

func TestPumaReadinessChecker_FunctionalOptions(t *testing.T) {
	logger := logrus.New()
	successTracker := NewSuccessTracker()

	// Test different option combinations
	testCases := []struct {
		name       string
		opts       []PumaReadinessCheckerOption
		hasChecker bool
		interval   time.Duration
	}{
		{
			name:       "no options",
			opts:       nil,
			hasChecker: false,
		},
		{
			name:       "with success checker only",
			opts:       []PumaReadinessCheckerOption{WithSuccessChecker(successTracker)},
			hasChecker: true,
		},
		{
			name:       "with custom skip interval only",
			opts:       []PumaReadinessCheckerOption{WithSkipInterval(60 * time.Second)},
			hasChecker: false,
			interval:   60 * time.Second,
		},
		{
			name: "with both options",
			opts: []PumaReadinessCheckerOption{
				WithSuccessChecker(successTracker),
				WithSkipInterval(45 * time.Second),
			},
			hasChecker: true,
			interval:   45 * time.Second,
		},
	}

	for _, tc := range testCases {
		t.Run(tc.name, func(t *testing.T) {
			checker := NewPumaReadinessChecker(
				"http://localhost:8080",
				"",
				5*time.Second,
				logger,
				tc.opts...,
			)

			if (checker.successChecker != nil) != tc.hasChecker {
				t.Errorf("Expected hasChecker=%v, got %v", tc.hasChecker, checker.successChecker != nil)
			}

			if checker.skipInterval != tc.interval {
				t.Errorf("Expected interval=%v, got %v", tc.interval, checker.skipInterval)
			}
		})
	}
}
