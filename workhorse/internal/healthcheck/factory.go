// Package healthcheck support for a readiness probe in GitLab Workhorse.
package healthcheck

import (
	"context"
	"fmt"
	"net/http"
	"time"

	"github.com/prometheus/client_golang/prometheus"
	"github.com/sirupsen/logrus"
	"gitlab.com/gitlab-org/labkit/log"

	"gitlab.com/gitlab-org/gitlab/workhorse/internal/config"
	"gitlab.com/gitlab-org/gitlab/workhorse/internal/listener"
)

// CheckResult represents the result of a health check
type CheckResult struct {
	Name    string
	Healthy bool
	Error   error
	Details map[string]interface{}
}

// HealthChecker interface defines the contract for individual health checkers
type HealthChecker interface {
	// Name returns the name of this health checker
	Name() string
	// Check performs the health check and returns the result
	Check(ctx context.Context) CheckResult
}

// CreateServer creates a health check server from configuration
func CreateServer(cfg config.HealthCheckConfig, logger *logrus.Logger, reg prometheus.Registerer) (*Server, error) {
	server := NewServer(cfg, logger, reg)

	// Add readiness checkers
	if cfg.ReadinessProbeURL != "" {
		pumaReadinessChecker := NewPumaReadinessChecker(
			cfg.ReadinessProbeURL,
			cfg.PumaControlURL,
			cfg.Timeout.Duration,
			logger,
		)
		server.AddReadinessChecker(pumaReadinessChecker)
	}

	return server, nil
}

// InitializeAndStart creates and starts the health check server if configured
func InitializeAndStart(cfg config.Config, accessLogger *logrus.Logger, errors chan error) (*Server, context.CancelFunc, error) {
	if cfg.HealthCheckListener == nil {
		return nil, nil, nil
	}

	healthCheckServer, err := CreateServer(*cfg.HealthCheckListener, accessLogger, prometheus.DefaultRegisterer)
	if err != nil {
		return nil, nil, fmt.Errorf("failed to create health check server: %v", err)
	}

	// Start health check server in background
	healthCtx, healthCancel := context.WithCancel(context.Background()) // lint:allow context.Background
	go healthCheckServer.Start(healthCtx)

	// Start health check HTTP server
	healthListener, err := listener.New("health check", config.ListenerConfig{
		Network: cfg.HealthCheckListener.Network,
		Addr:    cfg.HealthCheckListener.Addr,
	})
	if err != nil {
		healthCancel()
		return nil, nil, fmt.Errorf("health check listener: %v", err)
	}

	healthServer := &http.Server{
		Handler:      healthCheckServer,
		ReadTimeout:  10 * time.Second,
		WriteTimeout: 10 * time.Second,
		IdleTimeout:  10 * time.Second,
	}

	go func() {
		log.WithField("address", cfg.HealthCheckListener.Addr).Info("healthcheck: listening for requests")
		errors <- healthServer.Serve(healthListener)
	}()

	return healthCheckServer, healthCancel, nil
}
