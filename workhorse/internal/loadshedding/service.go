package loadshedding

import (
	"context"
	"encoding/json"
	"io"
	"net/http"
	"time"

	"github.com/sirupsen/logrus"

	"gitlab.com/gitlab-org/gitlab/workhorse/internal/puma"
)

// Service manages load shedding independently from readiness checks
// It periodically samples the Puma control server to update backlog metrics
type Service struct {
	logger        *logrus.Logger
	loadShedder   *LoadShedder
	controlURL    string
	timeout       time.Duration
	checkInterval time.Duration
	client        *http.Client
}

// NewService creates a new load shedding service
func NewService(controlURL string, timeout time.Duration, checkInterval time.Duration, loadShedder *LoadShedder, logger *logrus.Logger) *Service {
	return &Service{
		logger:        logger,
		loadShedder:   loadShedder,
		controlURL:    controlURL,
		timeout:       timeout,
		checkInterval: checkInterval,
		client: &http.Client{
			Timeout: timeout,
		},
	}
}

// Start begins periodic backlog sampling
func (s *Service) Start(ctx context.Context) {
	ticker := time.NewTicker(s.checkInterval)
	defer ticker.Stop()

	s.logger.WithFields(logrus.Fields{
		"check_interval_s": s.checkInterval.Seconds(),
		"control_url":      s.controlURL,
	}).Info("load shedding service: starting")

	for {
		select {
		case <-ctx.Done():
			s.logger.Info("load shedding service: stopped")
			return
		case <-ticker.C:
			s.sampleBacklog(ctx)
		}
	}
}

// sampleBacklog fetches and updates backlog metrics from Puma control server
func (s *Service) sampleBacklog(ctx context.Context) {
	controlURL := s.controlURL + "/stats"
	req, err := http.NewRequestWithContext(ctx, "GET", controlURL, nil)
	if err != nil {
		s.logger.WithError(err).Warn("load shedding service: failed to create control server request")
		return
	}

	start := time.Now()
	resp, err := s.client.Do(req)
	duration := time.Since(start)

	if err != nil {
		s.logger.WithError(err).Warn("load shedding service: control server request failed")
		return
	}
	defer func() { _ = resp.Body.Close() }()

	// Log if response time exceeds 1 second
	if duration > time.Second {
		s.logger.WithFields(logrus.Fields{
			"control_url": controlURL,
			"duration_s":  duration.Seconds(),
			"status_code": resp.StatusCode,
		}).Warn("load shedding service: control server response time exceeded 1 second")
	}

	if resp.StatusCode != http.StatusOK {
		s.logger.WithFields(logrus.Fields{
			"status_code": resp.StatusCode,
			"control_url": controlURL,
		}).Warn("load shedding service: control server returned non-200 status")
		return
	}

	body, err := io.ReadAll(resp.Body)
	if err != nil {
		s.logger.WithError(err).Warn("load shedding service: failed to read control server response body")
		return
	}

	var controlResp puma.ControlResponse
	if err := json.Unmarshal(body, &controlResp); err != nil {
		s.logger.WithError(err).Warn("load shedding service: failed to parse control server response")
		return
	}

	// Update load shedder with latest backlog data
	s.loadShedder.UpdateBacklog(&controlResp)
}
