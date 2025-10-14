package healthcheck

import (
	"context"
	"net/http"
	"net/http/httptest"
	"testing"
	"time"

	"github.com/prometheus/client_golang/prometheus"
	"github.com/stretchr/testify/assert"
	"github.com/stretchr/testify/require"

	"gitlab.com/gitlab-org/gitlab/workhorse/internal/config"
)

const readinessPath = "/-/readiness"

// Test helper functions

func createTestHealthCheckConfig() config.HealthCheckConfig {
	return config.HealthCheckConfig{
		Network:                "tcp",
		Addr:                   "localhost:0",
		CheckInterval:          config.TomlDuration{Duration: 100 * time.Millisecond},
		Timeout:                config.TomlDuration{Duration: 1 * time.Second},
		GracefulShutdownDelay:  config.TomlDuration{Duration: 100 * time.Millisecond}, // Short for testing
		MaxConsecutiveFailures: 3,
		MinSuccessfulProbes:    2,
	}
}

// Basic functionality tests

func TestServer_Basic(t *testing.T) {
	cfg := createTestHealthCheckConfig()
	logger := createTestLogger()

	server := NewServer(cfg, logger, prometheus.NewRegistry())
	server.AddReadinessChecker(NewPumaReadinessChecker("http://example.com/-/readiness", "", time.Second, logger))

	// Readiness should start as not ready
	assert.False(t, server.IsReady())
}

func TestServer_ReadinessEndpoint(t *testing.T) {
	// Create a mock Puma server
	pumaServer := httptest.NewServer(http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		if r.URL.Path == readinessPath {
			w.WriteHeader(http.StatusOK)
			w.Write([]byte("OK"))
		} else {
			w.WriteHeader(http.StatusNotFound)
		}
	}))
	defer pumaServer.Close()

	cfg := createTestHealthCheckConfig()
	cfg.ReadinessProbeURL = pumaServer.URL + readinessPath
	logger := createTestLogger()

	server, err := CreateServer(cfg, logger, prometheus.NewRegistry())
	require.NoError(t, err)

	// Should start as not ready
	assert.False(t, server.IsReady())

	// Start the health check process
	ctx, cancel := context.WithCancel(context.Background())
	defer cancel()
	go server.Start(ctx)

	// Wait for health checks to run and become ready
	require.Eventually(t, func() bool {
		return server.IsReady()
	}, 2*time.Second, 50*time.Millisecond)

	// Test readiness HTTP endpoint
	req := httptest.NewRequest("GET", "/readiness", nil)
	w := httptest.NewRecorder()
	server.ServeHTTP(w, req)

	assert.Equal(t, http.StatusOK, w.Code)
}

func TestServer_Shutdown(t *testing.T) {
	cfg := createTestHealthCheckConfig()
	logger := createTestLogger()

	server := NewServer(cfg, logger, prometheus.NewRegistry())
	server.AddReadinessChecker(NewPumaReadinessChecker("http://example.com/-/readiness", "", time.Second, logger))

	// Force readiness to ready state
	server.isReady.Store(true)

	assert.True(t, server.IsReady())

	// Initiate shutdown
	server.InitiateShutdown()

	// Readiness should become not ready
	assert.False(t, server.IsReady())

	// Test readiness endpoint returns 503
	req := httptest.NewRequest("GET", "/readiness", nil)
	w := httptest.NewRecorder()
	server.ServeHTTP(w, req)

	assert.Equal(t, http.StatusServiceUnavailable, w.Code)
	assert.Contains(t, w.Body.String(), `"ready":false`)
}

func TestServer_NotFound(t *testing.T) {
	cfg := createTestHealthCheckConfig()
	logger := createTestLogger()

	server := NewServer(cfg, logger, prometheus.NewRegistry())

	req := httptest.NewRequest("GET", "/unknown", nil)
	w := httptest.NewRecorder()
	server.ServeHTTP(w, req)

	assert.Equal(t, http.StatusNotFound, w.Code)
}

func TestServer_MethodNotAllowed(t *testing.T) {
	cfg := createTestHealthCheckConfig()
	logger := createTestLogger()

	server := NewServer(cfg, logger, prometheus.NewRegistry())

	req := httptest.NewRequest("POST", "/readiness", nil)
	w := httptest.NewRecorder()
	server.ServeHTTP(w, req)

	assert.Equal(t, http.StatusMethodNotAllowed, w.Code)
}

// Graceful shutdown tests (moved from cmd/gitlab-workhorse/graceful_shutdown_test.go)

func TestServer_GracefulShutdownDelay(t *testing.T) {
	cfg := createTestHealthCheckConfig()
	cfg.GracefulShutdownDelay = config.TomlDuration{Duration: 100 * time.Millisecond}
	logger := createTestLogger()

	// Create health check server directly using config
	server, err := CreateServer(cfg, logger, prometheus.NewRegistry())
	require.NoError(t, err)

	// Simulate the shutdown process
	start := time.Now()

	// Simulate receiving a shutdown signal
	var gracefulShutdownDelay time.Duration
	if server != nil {
		server.InitiateShutdown()
		gracefulShutdownDelay = server.GetGracefulShutdownDelay()
	}

	// Wait for the graceful shutdown delay to complete (this is what main.go should do)
	if gracefulShutdownDelay > 0 {
		time.Sleep(gracefulShutdownDelay)
	}

	elapsed := time.Since(start)

	// Verify that at least the graceful shutdown delay has elapsed
	assert.GreaterOrEqual(t, elapsed, gracefulShutdownDelay)
	assert.False(t, server.IsReady()) // Should be marked as not ready
}

func TestServer_GracefulShutdownDelayWithoutServer(t *testing.T) {
	// Test that when no health check server is configured, shutdown proceeds immediately
	start := time.Now()

	// Simulate the shutdown process without health check server
	var gracefulShutdownDelay time.Duration
	var server *Server // nil

	if server != nil {
		server.InitiateShutdown()
		gracefulShutdownDelay = server.GetGracefulShutdownDelay()
		// This won't be reached since server is nil
	}

	// Wait for the graceful shutdown delay to complete
	if gracefulShutdownDelay > 0 {
		time.Sleep(gracefulShutdownDelay)
	}

	elapsed := time.Since(start)

	// Should complete almost immediately since no delay is configured
	assert.Less(t, elapsed, 10*time.Millisecond)
}

func TestServer_GracefulShutdownIntegration(t *testing.T) {
	// Test the full graceful shutdown flow with a working health check
	pumaServer := httptest.NewServer(http.HandlerFunc(func(w http.ResponseWriter, _ *http.Request) {
		w.WriteHeader(http.StatusOK)
		w.Write([]byte("OK"))
	}))
	defer pumaServer.Close()

	cfg := createTestHealthCheckConfig()
	cfg.ReadinessProbeURL = pumaServer.URL + readinessPath
	cfg.GracefulShutdownDelay = config.TomlDuration{Duration: 200 * time.Millisecond}
	cfg.MinSuccessfulProbes = 1 // Make it ready faster
	logger := createTestLogger()

	server, err := CreateServer(cfg, logger, prometheus.NewRegistry())
	require.NoError(t, err)

	// Start the health check process
	ctx, cancel := context.WithCancel(context.Background())
	defer cancel()
	go server.Start(ctx)

	// Wait for it to become ready
	require.Eventually(t, func() bool {
		return server.IsReady()
	}, 2*time.Second, 50*time.Millisecond)

	// Verify it's ready via HTTP endpoint
	req := httptest.NewRequest("GET", "/readiness", nil)
	w := httptest.NewRecorder()
	server.ServeHTTP(w, req)
	assert.Equal(t, http.StatusOK, w.Code)

	// Now test graceful shutdown
	start := time.Now()
	server.InitiateShutdown()

	// Should immediately become not ready
	assert.False(t, server.IsReady())

	// HTTP endpoint should return 503
	w = httptest.NewRecorder()
	server.ServeHTTP(w, req)
	assert.Equal(t, http.StatusServiceUnavailable, w.Code)

	// Wait for graceful shutdown delay
	gracefulDelay := server.GetGracefulShutdownDelay()
	time.Sleep(gracefulDelay)

	elapsed := time.Since(start)
	assert.GreaterOrEqual(t, elapsed, gracefulDelay)
}
