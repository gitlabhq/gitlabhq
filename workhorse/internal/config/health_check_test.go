package config

import (
	"net/url"
	"testing"
	"time"

	"github.com/stretchr/testify/assert"
	"github.com/stretchr/testify/require"
)

func TestApplyHealthCheckDefaults(t *testing.T) {
	tests := []struct {
		name     string
		config   *Config
		expected *HealthCheckConfig
	}{
		{
			name: "applies all defaults when config is empty",
			config: &Config{
				HealthCheckListener: &HealthCheckConfig{},
			},
			expected: &HealthCheckConfig{
				CheckInterval:          TomlDuration{Duration: 10 * time.Second},
				Timeout:                TomlDuration{Duration: 5 * time.Second},
				GracefulShutdownDelay:  TomlDuration{Duration: 10 * time.Second},
				MaxConsecutiveFailures: 1,
				MinSuccessfulProbes:    1,
				ReadinessProbeURL:      "http://localhost:8080/-/readiness",
				RailsSkipInterval:      TomlDuration{Duration: 0},
			},
		},
		{
			name: "applies defaults with backend URL",
			config: &Config{
				Backend: &url.URL{
					Scheme: "http",
					Host:   "example.com:3000",
				},
				HealthCheckListener: &HealthCheckConfig{},
			},
			expected: &HealthCheckConfig{
				CheckInterval:          TomlDuration{Duration: 10 * time.Second},
				Timeout:                TomlDuration{Duration: 5 * time.Second},
				GracefulShutdownDelay:  TomlDuration{Duration: 10 * time.Second},
				MaxConsecutiveFailures: 1,
				MinSuccessfulProbes:    1,
				ReadinessProbeURL:      "http://example.com:3000/-/readiness",
				RailsSkipInterval:      TomlDuration{Duration: 0},
			},
		},
		{
			name: "preserves existing values",
			config: &Config{
				HealthCheckListener: &HealthCheckConfig{
					CheckInterval:          TomlDuration{Duration: 5 * time.Second},
					Timeout:                TomlDuration{Duration: 3 * time.Second},
					GracefulShutdownDelay:  TomlDuration{Duration: 15 * time.Second},
					MaxConsecutiveFailures: 5,
					MinSuccessfulProbes:    3,
					ReadinessProbeURL:      "http://custom.com/-/readiness",
					RailsSkipInterval:      TomlDuration{Duration: 60 * time.Second},
				},
			},
			expected: &HealthCheckConfig{
				CheckInterval:          TomlDuration{Duration: 5 * time.Second},
				Timeout:                TomlDuration{Duration: 3 * time.Second},
				GracefulShutdownDelay:  TomlDuration{Duration: 15 * time.Second},
				MaxConsecutiveFailures: 5,
				MinSuccessfulProbes:    3,
				ReadinessProbeURL:      "http://custom.com/-/readiness",
				RailsSkipInterval:      TomlDuration{Duration: 60 * time.Second},
			},
		},
		{
			name: "applies partial defaults",
			config: &Config{
				HealthCheckListener: &HealthCheckConfig{
					CheckInterval:       TomlDuration{Duration: 3 * time.Second},
					ReadinessProbeURL:   "http://custom.com/-/readiness",
					MinSuccessfulProbes: 4,
				},
			},
			expected: &HealthCheckConfig{
				CheckInterval:          TomlDuration{Duration: 3 * time.Second},  // preserved
				Timeout:                TomlDuration{Duration: 5 * time.Second},  // default
				GracefulShutdownDelay:  TomlDuration{Duration: 10 * time.Second}, // default
				MaxConsecutiveFailures: 1,                                        // default
				MinSuccessfulProbes:    4,                                        // preserved
				ReadinessProbeURL:      "http://custom.com/-/readiness",          // preserved
				RailsSkipInterval:      TomlDuration{Duration: 0},                // default
			},
		},
	}

	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			tt.config.ApplyHealthCheckDefaults()

			if tt.config.HealthCheckListener != nil {
				assert.Equal(t, tt.expected.CheckInterval, tt.config.HealthCheckListener.CheckInterval)
				assert.Equal(t, tt.expected.Timeout, tt.config.HealthCheckListener.Timeout)
				assert.Equal(t, tt.expected.GracefulShutdownDelay, tt.config.HealthCheckListener.GracefulShutdownDelay)
				assert.Equal(t, tt.expected.MaxConsecutiveFailures, tt.config.HealthCheckListener.MaxConsecutiveFailures)
				assert.Equal(t, tt.expected.MinSuccessfulProbes, tt.config.HealthCheckListener.MinSuccessfulProbes)
				assert.Equal(t, tt.expected.ReadinessProbeURL, tt.config.HealthCheckListener.ReadinessProbeURL)
				assert.Equal(t, tt.expected.RailsSkipInterval, tt.config.HealthCheckListener.RailsSkipInterval)
			}
		})
	}
}

func TestApplyHealthCheckDefaults_NoHealthCheckListener(t *testing.T) {
	cfg := &Config{
		HealthCheckListener: nil,
	}

	// Should not panic when HealthCheckListener is nil
	cfg.ApplyHealthCheckDefaults()

	assert.Nil(t, cfg.HealthCheckListener)
}

func TestApplyHealthCheckDefaults_WithBackendURL(t *testing.T) {
	backend, err := url.Parse("https://gitlab.example.com:8080")
	require.NoError(t, err)

	cfg := &Config{
		Backend: backend,
		HealthCheckListener: &HealthCheckConfig{
			CheckInterval: TomlDuration{Duration: 1 * time.Second}, // Custom value
		},
	}

	cfg.ApplyHealthCheckDefaults()

	assert.Equal(t, "https://gitlab.example.com:8080/-/readiness", cfg.HealthCheckListener.ReadinessProbeURL)
	assert.Equal(t, TomlDuration{Duration: 1 * time.Second}, cfg.HealthCheckListener.CheckInterval) // Preserved
	assert.Equal(t, TomlDuration{Duration: 5 * time.Second}, cfg.HealthCheckListener.Timeout)       // Default applied
	assert.Equal(t, TomlDuration{Duration: 0}, cfg.HealthCheckListener.RailsSkipInterval)           // Default applied
}
