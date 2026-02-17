package loadshedding

import (
	"github.com/prometheus/client_golang/prometheus"
	"github.com/sirupsen/logrus"

	"gitlab.com/gitlab-org/gitlab/workhorse/internal/config"
)

// NewLoadSheddingService creates and initializes a load shedding service from configuration
func NewLoadSheddingService(cfg *config.LoadSheddingConfig, logger *logrus.Logger) (*Service, *LoadShedder, error) {
	if cfg == nil || !cfg.Enabled {
		return nil, nil, nil
	}

	// Create the load shedder
	strategy := NewBacklogStrategy(cfg.Strategy)
	loadShedder := NewLoadShedder(
		cfg.BacklogThreshold,
		cfg.BacklogHysteresis,
		cfg.RetryAfterSeconds,
		logger,
		prometheus.DefaultRegisterer,
		strategy,
	)
	loadShedder.InitializeMetrics()

	// Create the service
	service := NewService(
		cfg.PumaControlURL,
		cfg.Timeout.Duration,
		cfg.CheckInterval.Duration,
		loadShedder,
		logger,
	)

	return service, loadShedder, nil
}
