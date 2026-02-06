package loadshedding

import (
	"sync/atomic"

	"github.com/prometheus/client_golang/prometheus"
	"github.com/prometheus/client_golang/prometheus/promauto"
	"github.com/sirupsen/logrus"

	"gitlab.com/gitlab-org/gitlab/workhorse/internal/puma"
)

// BacklogStrategy defines how to calculate the effective backlog from worker backlogs
type BacklogStrategy interface {
	// Calculate returns the effective backlog value based on the strategy
	Calculate(backlogs []int) int
	// Name returns the name of the strategy
	Name() string
}

// MaxBacklogStrategy returns the maximum backlog across all workers
type MaxBacklogStrategy struct{}

// Calculate returns the maximum backlog value
func (s *MaxBacklogStrategy) Calculate(backlogs []int) int {
	if len(backlogs) == 0 {
		return 0
	}

	maxBacklog := 0
	for _, backlog := range backlogs {
		if backlog > maxBacklog {
			maxBacklog = backlog
		}
	}
	return maxBacklog
}

// Name returns the name of the strategy
func (s *MaxBacklogStrategy) Name() string {
	return "max"
}

// SumBacklogStrategy returns the sum of all backlogs across workers
type SumBacklogStrategy struct{}

// Calculate returns the sum of all backlog values
func (s *SumBacklogStrategy) Calculate(backlogs []int) int {
	if len(backlogs) == 0 {
		return 0
	}

	sum := 0
	for _, backlog := range backlogs {
		sum += backlog
	}
	return sum
}

// Name returns the name of the strategy
func (s *SumBacklogStrategy) Name() string {
	return "sum"
}

// LoadShedder determines whether to shed load based on Puma backlog metrics
type LoadShedder struct {
	logger              *logrus.Logger
	backlogThreshold    int
	backlogHysteresis   float64 // Factor for deactivation (e.g., 0.8 means deactivate at 80% of threshold)
	retryAfterSeconds   int
	lastBacklogSnapshot atomic.Int64
	shouldShed          atomic.Bool
	strategy            BacklogStrategy

	// Prometheus metrics
	backlogGauge     prometheus.Gauge
	thresholdGauge   prometheus.Gauge
	shedLoadGauge    prometheus.Gauge
	shedLoadCounter  prometheus.Counter
	allowLoadCounter prometheus.Counter
}

// NewLoadShedder creates a new load shedder with the specified backlog threshold, hysteresis, and strategy
// If strategy is nil, MaxBacklogStrategy is used by default
// backlogHysteresis should be between 0 and 1 (e.g., 0.8 means deactivate at 80% of threshold)
func NewLoadShedder(backlogThreshold int, backlogHysteresis float64, retryAfterSeconds int, logger *logrus.Logger, reg prometheus.Registerer, strategy BacklogStrategy) *LoadShedder {
	if strategy == nil {
		strategy = &MaxBacklogStrategy{}
	}

	// Validate hysteresis (must be between 0 and 1, where 1.0 means no hysteresis effect)
	if backlogHysteresis <= 0 || backlogHysteresis > 1 {
		backlogHysteresis = 0.8
	}

	promFactory := promauto.With(reg)

	return &LoadShedder{
		logger:            logger,
		backlogThreshold:  backlogThreshold,
		backlogHysteresis: backlogHysteresis,
		retryAfterSeconds: retryAfterSeconds,
		strategy:          strategy,
		backlogGauge: promFactory.NewGauge(prometheus.GaugeOpts{
			Name: "workhorse_puma_backlog",
			Help: "Current maximum backlog across all Puma workers",
		}),
		thresholdGauge: promFactory.NewGauge(prometheus.GaugeOpts{
			Name: "workhorse_load_shedding_threshold",
			Help: "Configured backlog threshold for load shedding",
		}),
		shedLoadGauge: promFactory.NewGauge(prometheus.GaugeOpts{
			Name: "workhorse_load_shedding_active",
			Help: "Whether load shedding is currently active (1 = shedding, 0 = not shedding)",
		}),
		shedLoadCounter: promFactory.NewCounter(prometheus.CounterOpts{
			Name: "workhorse_load_shedding_total",
			Help: "Total number of times load shedding was activated",
		}),
		allowLoadCounter: promFactory.NewCounter(prometheus.CounterOpts{
			Name: "workhorse_load_shedding_disabled_total",
			Help: "Total number of times load shedding was deactivated",
		}),
	}
}

// UpdateBacklog updates the current backlog metric from Puma control server data
// It uses the configured strategy to calculate the effective backlog and applies hysteresis logic
func (ls *LoadShedder) UpdateBacklog(controlResp *puma.ControlResponse) {
	if controlResp == nil || len(controlResp.WorkerStatus) == 0 {
		return
	}

	// Collect backlogs from all workers
	backlogs := make([]int, len(controlResp.WorkerStatus))
	for i, worker := range controlResp.WorkerStatus {
		backlogs[i] = worker.LastStatus.Backlog
	}

	// Calculate effective backlog using the configured strategy
	effectiveBacklog := ls.strategy.Calculate(backlogs)

	ls.lastBacklogSnapshot.Store(int64(effectiveBacklog))

	// Update backlog gauge
	ls.backlogGauge.Set(float64(effectiveBacklog))

	// Calculate hysteresis threshold once with proper rounding to avoid precision loss
	hysteresisThreshold := int(float64(ls.backlogThreshold)*ls.backlogHysteresis + 0.5)

	// Apply hysteresis logic to prevent oscillation
	wasShedding := ls.shouldShed.Load()
	shouldShed := wasShedding

	if !wasShedding && effectiveBacklog >= ls.backlogThreshold {
		// Activate shedding when backlog exceeds threshold
		shouldShed = true
	} else if wasShedding && effectiveBacklog < hysteresisThreshold {
		// Deactivate shedding when backlog drops below hysteresis threshold
		shouldShed = false
	}

	if shouldShed != wasShedding {
		ls.shouldShed.Store(shouldShed)
		if shouldShed {
			ls.logger.WithFields(map[string]interface{}{
				"effective_backlog":    effectiveBacklog,
				"backlog_threshold":    ls.backlogThreshold,
				"hysteresis_threshold": hysteresisThreshold,
				"strategy":             ls.strategy.Name(),
			}).Warn("Load shedding enabled: backlog threshold exceeded")
			ls.shedLoadGauge.Set(1)
			ls.shedLoadCounter.Inc()
		} else {
			ls.logger.WithFields(map[string]interface{}{
				"effective_backlog":    effectiveBacklog,
				"backlog_threshold":    ls.backlogThreshold,
				"hysteresis_threshold": hysteresisThreshold,
				"strategy":             ls.strategy.Name(),
			}).Info("Load shedding disabled: backlog below hysteresis threshold")
			ls.shedLoadGauge.Set(0)
			ls.allowLoadCounter.Inc()
		}
	}
}

// ShouldShedLoad returns whether load should be shed
func (ls *LoadShedder) ShouldShedLoad() bool {
	return ls.shouldShed.Load()
}

// GetLastBacklog returns the last recorded maximum backlog value
func (ls *LoadShedder) GetLastBacklog() int {
	return int(ls.lastBacklogSnapshot.Load())
}

// GetThreshold returns the configured backlog threshold
func (ls *LoadShedder) GetThreshold() int {
	return ls.backlogThreshold
}

// GetRetryAfterSeconds returns the configured Retry-After header value in seconds
func (ls *LoadShedder) GetRetryAfterSeconds() int {
	return ls.retryAfterSeconds
}

// InitializeMetrics sets the threshold gauge (should be called once after creation)
func (ls *LoadShedder) InitializeMetrics() {
	ls.thresholdGauge.Set(float64(ls.backlogThreshold))
	ls.shedLoadGauge.Set(0)
}

// NewBacklogStrategy creates a BacklogStrategy based on the strategy name
// Valid names are "max" and "sum". Defaults to MaxBacklogStrategy if name is empty or unknown.
func NewBacklogStrategy(strategyName string) BacklogStrategy {
	switch strategyName {
	case "sum":
		return &SumBacklogStrategy{}
	case "max", "":
		return &MaxBacklogStrategy{}
	default:
		return &MaxBacklogStrategy{}
	}
}
