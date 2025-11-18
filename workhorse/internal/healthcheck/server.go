package healthcheck

import (
	"context"
	"encoding/json"
	"fmt"
	"net/http"
	"strings"
	"sync"
	"sync/atomic"
	"time"

	"github.com/prometheus/client_golang/prometheus"
	"github.com/prometheus/client_golang/prometheus/promauto"
	"github.com/sirupsen/logrus"

	"gitlab.com/gitlab-org/gitlab/workhorse/internal/config"
)

// Server manages readiness checks
type Server struct {
	config   config.HealthCheckConfig
	logger   *logrus.Logger
	registry prometheus.Registerer

	// Readiness state
	readinessCheckers             []HealthChecker
	isReady                       atomic.Bool
	readinessConsecutiveFailures  atomic.Int64
	readinessConsecutiveSuccesses atomic.Int64

	// Shared state
	isShutdown atomic.Bool

	mu                 sync.RWMutex
	lastReadinessError error
	lastCheckResults   map[string]CheckResult

	// Success tracking for optimized readiness checks
	successTracker *SuccessTracker

	// Metrics
	readinessStatus    prometheus.Gauge
	readinessErrorRate prometheus.Counter
	checkDuration      prometheus.Histogram
	individualChecks   map[string]prometheus.Gauge
}

// NewServer creates a new health check server
func NewServer(cfg config.HealthCheckConfig, logger *logrus.Logger, reg prometheus.Registerer) *Server {
	promFactory := promauto.With(reg)

	hcs := &Server{
		config:            cfg,
		logger:            logger,
		registry:          reg,
		readinessCheckers: make([]HealthChecker, 0),
		individualChecks:  make(map[string]prometheus.Gauge),
		successTracker:    NewSuccessTracker(),
		readinessStatus: promFactory.NewGauge(prometheus.GaugeOpts{
			Name: "workhorse_readiness_status",
			Help: "Overall readiness status (1 = ready, 0 = not ready)",
		}),
		readinessErrorRate: promFactory.NewCounter(prometheus.CounterOpts{
			Name: "workhorse_readiness_errors_total",
			Help: "Total number of readiness check errors",
		}),
		checkDuration: promFactory.NewHistogram(prometheus.HistogramOpts{
			Name: "workhorse_health_check_duration_seconds",
			Help: "Duration of health checks in seconds",
		}),
	}

	hcs.isReady.Store(false)
	hcs.readinessStatus.Set(0)
	hcs.readinessConsecutiveSuccesses.Store(0)
	hcs.readinessConsecutiveFailures.Store(0)

	return hcs
}

// GetSuccessTracker returns the success tracker for use by routing middleware
func (hcs *Server) GetSuccessTracker() *SuccessTracker {
	return hcs.successTracker
}

// GetSuccessRecorder returns the success recorder interface
func (hcs *Server) GetSuccessRecorder() SuccessRecorder {
	return hcs.successTracker
}

// GetOptimizedReadinessChecker returns the optimized readiness checker interface
func (hcs *Server) GetOptimizedReadinessChecker() OptimizedReadinessChecker {
	return hcs.successTracker
}

// AddReadinessChecker adds a readiness checker
func (hcs *Server) AddReadinessChecker(checker HealthChecker) {
	hcs.readinessCheckers = append(hcs.readinessCheckers, checker)
	hcs.addIndividualMetric("readiness", checker.Name())
}

// addIndividualMetric creates metrics for individual checkers
func (hcs *Server) addIndividualMetric(checkType, checkerName string) {
	promFactory := promauto.With(hcs.registry)
	key := fmt.Sprintf("%s_%s", checkType, checkerName)
	hcs.individualChecks[key] = promFactory.NewGauge(prometheus.GaugeOpts{
		Name: fmt.Sprintf("workhorse_%s_%s_check", checkType, checkerName),
		Help: fmt.Sprintf("Status of %s %s check (1 = healthy, 0 = not healthy)", checkType, checkerName),
	})
}

// Start begins the health checking process
func (hcs *Server) Start(ctx context.Context) {
	if len(hcs.readinessCheckers) == 0 {
		hcs.logger.Warn("No health checkers configured")
		return
	}

	logFields := logrus.Fields{
		"check_interval_s":         hcs.config.CheckInterval.Seconds(),
		"readiness_checkers_count": len(hcs.readinessCheckers),
	}

	hcs.logger.WithFields(logFields).Info("healthcheck: starting server")

	for {
		select {
		case <-ctx.Done():
			hcs.logger.Info("Health check server stopped")
			return
		default:
			hcs.performHealthChecks(ctx)
			time.Sleep(hcs.config.CheckInterval.Duration)
		}
	}
}

// performHealthChecks runs all health checkers and updates status
func (hcs *Server) performHealthChecks(ctx context.Context) {
	start := time.Now()
	defer func() {
		hcs.checkDuration.Observe(time.Since(start).Seconds())
	}()

	hcs.performReadinessChecks(ctx)
}

// performReadinessChecks handles readiness checking logic
func (hcs *Server) performReadinessChecks(ctx context.Context) {
	// If we're in shutdown mode, remain not ready
	if hcs.isShutdown.Load() {
		hcs.isReady.Store(false)
		hcs.readinessStatus.Set(0)
		return
	}

	allHealthy := true
	var lastError error
	checkResults := make(map[string]CheckResult)

	for _, checker := range hcs.readinessCheckers {
		checkCtx, cancel := context.WithTimeout(ctx, hcs.config.Timeout.Duration)
		result := checker.Check(checkCtx)
		cancel()

		// Store the full result for later use in the response
		checkResults[checker.Name()] = result

		// Update individual check metrics
		key := fmt.Sprintf("readiness_%s", checker.Name())
		if gauge, exists := hcs.individualChecks[key]; exists {
			if result.Healthy {
				gauge.Set(1)
			} else {
				gauge.Set(0)
			}
		}

		if !result.Healthy {
			allHealthy = false
			if result.Error != nil {
				lastError = result.Error
			}
		}
	}

	// Store check results for use in HTTP response
	hcs.mu.Lock()
	hcs.lastCheckResults = checkResults
	hcs.mu.Unlock()

	// Record error if any check failed
	if !allHealthy && lastError != nil {
		hcs.recordReadinessError(lastError)
	} else {
		hcs.clearReadinessError()
	}

	// Update readiness with consecutive failure/success logic
	finalReady := hcs.updateReadinessCounters(allHealthy)

	if finalReady {
		hcs.isReady.Store(true)
		hcs.readinessStatus.Set(1)
	} else {
		hcs.isReady.Store(false)
		hcs.readinessStatus.Set(0)
	}
}

// updateReadinessCounters applies consecutive failure/success logic for readiness
func (hcs *Server) updateReadinessCounters(currentCheckPassed bool) bool {
	currentReady := hcs.isReady.Load()

	if currentCheckPassed {
		// Reset failure counter and increment success counter
		hcs.readinessConsecutiveFailures.Store(0)
		successes := hcs.readinessConsecutiveSuccesses.Add(1)

		// If we're already ready, stay ready
		if currentReady {
			return true
		}

		// If we're not ready, need minimum successful probes to become ready
		return int(successes) >= hcs.config.MinSuccessfulProbes
	}

	// Reset success counter and increment failure counter
	hcs.readinessConsecutiveSuccesses.Store(0)
	failures := hcs.readinessConsecutiveFailures.Add(1)

	// If we exceed max consecutive failures, mark as not ready
	if int(failures) >= hcs.config.MaxConsecutiveFailures {
		return false
	}

	// If we haven't exceeded max failures yet, maintain current ready state
	return currentReady
}

// recordReadinessError records a readiness error
func (hcs *Server) recordReadinessError(err error) {
	hcs.mu.Lock()
	hcs.lastReadinessError = err
	hcs.mu.Unlock()

	hcs.readinessErrorRate.Inc()
	hcs.logger.WithError(err).Warn("Readiness check error")
}

// clearReadinessError clears the state of the last readiness error
func (hcs *Server) clearReadinessError() {
	hcs.mu.Lock()
	hcs.lastReadinessError = nil
	hcs.mu.Unlock()
}

// IsReady returns the current readiness status
func (hcs *Server) IsReady() bool {
	return hcs.isReady.Load()
}

// InitiateShutdown marks the service as shutting down
func (hcs *Server) InitiateShutdown() {
	hcs.isShutdown.Store(true)
	hcs.isReady.Store(false)
	hcs.readinessStatus.Set(0)
}

// GetGracefulShutdownDelay returns the graceful shutdown delay
func (hcs *Server) GetGracefulShutdownDelay() time.Duration {
	return hcs.config.GracefulShutdownDelay.Duration
}

// ServeHTTP handles health check endpoint requests
func (hcs *Server) ServeHTTP(w http.ResponseWriter, r *http.Request) {
	if r.Method != http.MethodGet {
		http.Error(w, "Method not allowed", http.StatusMethodNotAllowed)
		return
	}

	path := strings.TrimPrefix(r.URL.Path, "/")

	switch path {
	case "readiness":
		hcs.serveReadiness(w, r)
	default:
		http.NotFound(w, r)
	}
}

// serveReadiness handles readiness endpoint requests
func (hcs *Server) serveReadiness(w http.ResponseWriter, _ *http.Request) {
	ready := hcs.IsReady()

	hcs.mu.RLock()
	lastError := hcs.lastReadinessError
	checkResults := hcs.lastCheckResults
	hcs.mu.RUnlock()

	// Build individual check status with duration information
	checks := make(map[string]interface{})
	for _, checker := range hcs.readinessCheckers {
		checkerInfo := make(map[string]interface{})

		// Get health status and duration information from the last check result
		if result, exists := checkResults[checker.Name()]; exists {
			checkerInfo["healthy"] = result.Healthy

			// Store all keys from result.Details into checkerInfo
			for key, value := range result.Details {
				checkerInfo[key] = value
			}
		} else {
			// Fallback if no recent check result is available
			checkerInfo["healthy"] = false
		}

		checks[checker.Name()] = checkerInfo
	}

	response := map[string]interface{}{
		"ready":  ready,
		"checks": checks,
		"metrics": map[string]interface{}{
			"consecutive_failures":  hcs.readinessConsecutiveFailures.Load(),
			"consecutive_successes": hcs.readinessConsecutiveSuccesses.Load(),
		},
		"health_thresholds": map[string]interface{}{
			"max_consecutive_failures": hcs.config.MaxConsecutiveFailures,
			"min_successful_probes":    hcs.config.MinSuccessfulProbes,
		},
	}

	if lastError != nil {
		response["last_error"] = lastError.Error()
	}

	w.Header().Set("Content-Type", "application/json")

	if ready {
		w.WriteHeader(http.StatusOK)
	} else {
		w.WriteHeader(http.StatusServiceUnavailable)
	}

	err := json.NewEncoder(w).Encode(response)
	if err != nil {
		hcs.logger.WithError(err).Error("healthcheck: error encoding JSON response")
	}
}
