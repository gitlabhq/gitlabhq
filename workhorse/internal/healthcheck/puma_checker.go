package healthcheck

import (
	"context"
	"encoding/json"
	"fmt"
	"io"
	"net/http"
	"time"

	"github.com/sirupsen/logrus"
)

// PumaReadinessChecker checks Puma's readiness endpoint and optionally control server
type PumaReadinessChecker struct {
	name       string
	url        string
	controlURL string
	timeout    time.Duration
	client     *http.Client
	logger     *logrus.Logger
}

// PumaReadinessResponse represents the JSON response from Puma's readiness endpoint
type PumaReadinessResponse struct {
	Status string `json:"status"`
}

// PumaControlResponse represents the JSON response from Puma's control server
type PumaControlResponse struct {
	StartedAt     string       `json:"started_at"`
	Workers       int          `json:"workers"`
	Phase         int          `json:"phase"`
	BootedWorkers int          `json:"booted_workers"`
	OldWorkers    int          `json:"old_workers"`
	WorkerStatus  []PumaWorker `json:"worker_status"`
}

// PumaWorker represents a Puma worker's status
type PumaWorker struct {
	StartedAt   string           `json:"started_at"`
	PID         int              `json:"pid"`
	Index       int              `json:"index"`
	Phase       int              `json:"phase"`
	Booted      bool             `json:"booted"`
	LastCheckin string           `json:"last_checkin"`
	LastStatus  PumaWorkerStatus `json:"last_status"`
}

// PumaWorkerStatus represents the detailed status of a Puma worker
type PumaWorkerStatus struct {
	Backlog       int `json:"backlog"`
	Running       int `json:"running"`
	PoolCapacity  int `json:"pool_capacity"`
	MaxThreads    int `json:"max_threads"`
	RequestsCount int `json:"requests_count"`
}

// NewPumaReadinessChecker creates a new Puma readiness checker
func NewPumaReadinessChecker(readinessURL, controlURL string, timeout time.Duration, logger *logrus.Logger) *PumaReadinessChecker {
	return &PumaReadinessChecker{
		name:       "puma_readiness",
		url:        readinessURL,
		controlURL: controlURL,
		timeout:    timeout,
		client: &http.Client{
			Timeout: timeout,
		},
		logger: logger,
	}
}

// Name returns the name of check
func (p *PumaReadinessChecker) Name() string {
	return p.name
}

// Check performs the Puma readiness check
func (p *PumaReadinessChecker) Check(ctx context.Context) CheckResult {
	result := CheckResult{
		Name:    p.name,
		Healthy: true,
		Details: make(map[string]interface{}),
	}

	// Check Puma control server if configured
	if p.controlURL != "" {
		controlHealthy, controlDuration, controlErr := p.checkControlServer(ctx)
		result.Details["control_server"] = controlHealthy
		result.Details["control_duration_s"] = controlDuration.Seconds()
		result.Details["control_server_last_scrape_time"] = time.Now().UTC().Format(time.RFC3339)

		if controlErr != nil && result.Error == nil {
			result.Error = controlErr
		}

		if !controlHealthy {
			result.Healthy = false
		}
	}

	// Assume readiness endpoint is not available if control server is not healthy
	if !result.Healthy {
		result.Details["readiness_endpoint"] = false
		result.Details["readiness_duration_s"] = 0
		return result
	}

	// Check Puma readiness endpoint
	readinessHealthy, readinessDuration, readinessErr := p.checkReadinessEndpoint(ctx)
	result.Details["readiness_endpoint"] = readinessHealthy
	result.Details["readiness_duration_s"] = readinessDuration.Seconds()
	result.Details["readiness_last_scrape_time"] = time.Now().UTC().Format(time.RFC3339)

	if readinessErr != nil {
		result.Error = readinessErr
	}

	if !readinessHealthy {
		result.Healthy = false
		if result.Error == nil {
			result.Error = fmt.Errorf("puma readiness endpoint returned non-200 status or invalid response")
		}
	}

	return result
}

// httpCheckResult represents the result of an HTTP check
type httpCheckResult struct {
	body     []byte
	duration time.Duration
}

// performHTTPCheck performs a generic HTTP check with common error handling and logging
func (p *PumaReadinessChecker) performHTTPCheck(ctx context.Context, url, checkType string) (*httpCheckResult, error) {
	result := httpCheckResult{}
	req, err := http.NewRequestWithContext(ctx, "GET", url, nil)
	if err != nil {
		return &result, fmt.Errorf("failed to create %s request: %w", checkType, err)
	}

	start := time.Now()
	resp, err := p.client.Do(req)
	duration := time.Since(start)
	result.duration = duration

	if err != nil {
		return &result, fmt.Errorf("puma %s check failed: %w", checkType, err)
	}
	defer func() { _ = resp.Body.Close() }()

	// Log if response time exceeds 1 second
	if duration > time.Second {
		logFields := logrus.Fields{
			checkType + "_url":         url,
			checkType + "_duration_s":  duration.Seconds(),
			checkType + "_status_code": resp.StatusCode,
		}
		p.logger.WithFields(logFields).Warnf("Puma %s response time exceeded 1 second", checkType)
	}

	if resp.StatusCode != http.StatusOK {
		return &result, fmt.Errorf("puma %s returned status %d", checkType, resp.StatusCode)
	}

	body, err := io.ReadAll(resp.Body)
	if err != nil {
		return &result, fmt.Errorf("failed to read %s response body: %w", checkType, err)
	}

	result.body = body

	return &result, nil
}

// checkReadinessEndpoint checks Puma's readiness endpoint and validates the JSON response
func (p *PumaReadinessChecker) checkReadinessEndpoint(ctx context.Context) (bool, time.Duration, error) {
	result, err := p.performHTTPCheck(ctx, p.url, "readiness")
	if err != nil {
		return false, result.duration, err
	}

	var readinessResp PumaReadinessResponse
	if err := json.Unmarshal(result.body, &readinessResp); err != nil {
		// If JSON parsing fails, log but don't fail the check - some endpoints might return plain text
		p.logger.WithFields(logrus.Fields{
			"url":   p.url,
			"body":  string(result.body),
			"error": err,
		}).Debug("Failed to parse Puma readiness response as JSON, treating as healthy")
		return true, result.duration, nil
	}

	// Validate the response
	if readinessResp.Status != "" && readinessResp.Status != "ok" {
		return false, result.duration, fmt.Errorf("puma readiness status is %s", readinessResp.Status)
	}

	return true, result.duration, nil
}

// checkControlServer checks Puma's control server and validates worker status
func (p *PumaReadinessChecker) checkControlServer(ctx context.Context) (bool, time.Duration, error) {
	controlURL := p.controlURL + "/stats"
	result, err := p.performHTTPCheck(ctx, controlURL, "control server")
	if err != nil {
		return false, result.duration, err
	}

	var controlResp PumaControlResponse
	if err := json.Unmarshal(result.body, &controlResp); err != nil {
		return false, result.duration, fmt.Errorf("unable to parse puma control response: %w", err)
	}

	return p.validateWorkerStatus(controlResp, result.duration)
}

// validateWorkerStatus validates that at least one worker is booted
func (p *PumaReadinessChecker) validateWorkerStatus(controlResp PumaControlResponse, duration time.Duration) (bool, time.Duration, error) {
	bootedWorkers := controlResp.BootedWorkers
	totalWorkers := controlResp.Workers

	// Also validate individual worker status for additional safety
	actualBootedWorkers := 0
	for _, worker := range controlResp.WorkerStatus {
		if worker.Booted {
			actualBootedWorkers++
		}
	}

	// Use the more conservative count (should match, but safety first)
	if actualBootedWorkers < bootedWorkers {
		bootedWorkers = actualBootedWorkers
	}

	// Ensure at least one worker is booted
	if totalWorkers > 0 && bootedWorkers == 0 {
		return false, duration, fmt.Errorf("no puma workers are booted (%d/%d)", bootedWorkers, totalWorkers)
	}

	return true, duration, nil
}
