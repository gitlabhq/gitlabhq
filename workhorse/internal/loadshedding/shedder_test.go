package loadshedding

import (
	"testing"

	"github.com/prometheus/client_golang/prometheus"
	"github.com/sirupsen/logrus"
	"github.com/stretchr/testify/assert"

	"gitlab.com/gitlab-org/gitlab/workhorse/internal/puma"
)

func TestLoadShedderThresholdExceeded(t *testing.T) {
	logger := logrus.New()
	reg := prometheus.NewRegistry()
	shedder := NewLoadShedder(100, 0.8, 0, logger, reg, nil)
	shedder.InitializeMetrics()

	// Initially should not shed
	assert.False(t, shedder.ShouldShedLoad())

	// Create a control response with backlog exceeding threshold
	controlResp := &puma.ControlResponse{
		Workers:       2,
		BootedWorkers: 2,
		WorkerStatus: []puma.Worker{
			{
				Index:  0,
				Booted: true,
				LastStatus: puma.WorkerStatus{
					Backlog: 150,
				},
			},
			{
				Index:  1,
				Booted: true,
				LastStatus: puma.WorkerStatus{
					Backlog: 50,
				},
			},
		},
	}

	shedder.UpdateBacklog(controlResp)

	// Should shed load now (max backlog is 150, threshold is 100)
	assert.True(t, shedder.ShouldShedLoad())
	assert.Equal(t, 150, shedder.GetLastBacklog())
}

func TestLoadShedderThresholdNotExceeded(t *testing.T) {
	logger := logrus.New()
	reg := prometheus.NewRegistry()
	shedder := NewLoadShedder(100, 0.8, 0, logger, reg, nil)
	shedder.InitializeMetrics()

	controlResp := &puma.ControlResponse{
		Workers:       2,
		BootedWorkers: 2,
		WorkerStatus: []puma.Worker{
			{
				Index:  0,
				Booted: true,
				LastStatus: puma.WorkerStatus{
					Backlog: 50,
				},
			},
			{
				Index:  1,
				Booted: true,
				LastStatus: puma.WorkerStatus{
					Backlog: 30,
				},
			},
		},
	}

	shedder.UpdateBacklog(controlResp)

	// Should not shed load (max backlog is 50, threshold is 100)
	assert.False(t, shedder.ShouldShedLoad())
	assert.Equal(t, 50, shedder.GetLastBacklog())
}

func TestLoadShedderTransition(t *testing.T) {
	logger := logrus.New()
	reg := prometheus.NewRegistry()
	shedder := NewLoadShedder(100, 0.8, 0, logger, reg, nil)
	shedder.InitializeMetrics()

	// Start below threshold
	controlResp := &puma.ControlResponse{
		Workers:       1,
		BootedWorkers: 1,
		WorkerStatus: []puma.Worker{
			{
				Index:  0,
				Booted: true,
				LastStatus: puma.WorkerStatus{
					Backlog: 50,
				},
			},
		},
	}

	shedder.UpdateBacklog(controlResp)
	assert.False(t, shedder.ShouldShedLoad())

	// Exceed threshold
	controlResp.WorkerStatus[0].LastStatus.Backlog = 150
	shedder.UpdateBacklog(controlResp)
	assert.True(t, shedder.ShouldShedLoad())

	// Drop back below threshold
	controlResp.WorkerStatus[0].LastStatus.Backlog = 50
	shedder.UpdateBacklog(controlResp)
	assert.False(t, shedder.ShouldShedLoad())
}

func TestLoadShedderNilResponse(t *testing.T) {
	logger := logrus.New()
	reg := prometheus.NewRegistry()
	shedder := NewLoadShedder(100, 0.8, 0, logger, reg, nil)
	shedder.InitializeMetrics()

	// Should handle nil response gracefully
	shedder.UpdateBacklog(nil)
	assert.False(t, shedder.ShouldShedLoad())
}

func TestLoadShedderEmptyWorkers(t *testing.T) {
	logger := logrus.New()
	reg := prometheus.NewRegistry()
	shedder := NewLoadShedder(100, 0.8, 0, logger, reg, nil)
	shedder.InitializeMetrics()

	controlResp := &puma.ControlResponse{
		Workers:       0,
		BootedWorkers: 0,
		WorkerStatus:  []puma.Worker{},
	}

	shedder.UpdateBacklog(controlResp)
	assert.False(t, shedder.ShouldShedLoad())
}

func TestLoadShedderGetThreshold(t *testing.T) {
	logger := logrus.New()
	reg := prometheus.NewRegistry()
	shedder := NewLoadShedder(250, 0.8, 0, logger, reg, nil)
	shedder.InitializeMetrics()

	assert.Equal(t, 250, shedder.GetThreshold())
}

func TestMaxBacklogStrategy(t *testing.T) {
	strategy := &MaxBacklogStrategy{}

	tests := []struct {
		name     string
		backlogs []int
		want     int
	}{
		{
			name:     "empty backlogs",
			backlogs: []int{},
			want:     0,
		},
		{
			name:     "single backlog",
			backlogs: []int{50},
			want:     50,
		},
		{
			name:     "multiple backlogs",
			backlogs: []int{50, 150, 75},
			want:     150,
		},
		{
			name:     "all same",
			backlogs: []int{100, 100, 100},
			want:     100,
		},
		{
			name:     "max at start",
			backlogs: []int{200, 50, 75},
			want:     200,
		},
		{
			name:     "max at end",
			backlogs: []int{50, 75, 200},
			want:     200,
		},
	}

	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			got := strategy.Calculate(tt.backlogs)
			assert.Equal(t, tt.want, got)
		})
	}
}

func TestMaxBacklogStrategyName(t *testing.T) {
	strategy := &MaxBacklogStrategy{}
	assert.Equal(t, "max", strategy.Name())
}

func TestLoadShedderWithCustomStrategy(t *testing.T) {
	logger := logrus.New()
	reg := prometheus.NewRegistry()
	strategy := &MaxBacklogStrategy{}
	shedder := NewLoadShedder(100, 0.8, 0, logger, reg, strategy)
	shedder.InitializeMetrics()

	controlResp := &puma.ControlResponse{
		Workers:       2,
		BootedWorkers: 2,
		WorkerStatus: []puma.Worker{
			{
				Index:  0,
				Booted: true,
				LastStatus: puma.WorkerStatus{
					Backlog: 150,
				},
			},
			{
				Index:  1,
				Booted: true,
				LastStatus: puma.WorkerStatus{
					Backlog: 50,
				},
			},
		},
	}

	shedder.UpdateBacklog(controlResp)

	// Should shed load (max backlog is 150, threshold is 100)
	assert.True(t, shedder.ShouldShedLoad())
	assert.Equal(t, 150, shedder.GetLastBacklog())
}

func TestSumBacklogStrategy(t *testing.T) {
	strategy := &SumBacklogStrategy{}

	tests := []struct {
		name     string
		backlogs []int
		want     int
	}{
		{
			name:     "empty backlogs",
			backlogs: []int{},
			want:     0,
		},
		{
			name:     "single backlog",
			backlogs: []int{50},
			want:     50,
		},
		{
			name:     "multiple backlogs",
			backlogs: []int{50, 150, 75},
			want:     275,
		},
		{
			name:     "all same",
			backlogs: []int{100, 100, 100},
			want:     300,
		},
		{
			name:     "large sum",
			backlogs: []int{1000, 2000, 3000},
			want:     6000,
		},
	}

	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			got := strategy.Calculate(tt.backlogs)
			assert.Equal(t, tt.want, got)
		})
	}
}

func TestSumBacklogStrategyName(t *testing.T) {
	strategy := &SumBacklogStrategy{}
	assert.Equal(t, "sum", strategy.Name())
}

func TestSumBacklogStrategyLargeValues(t *testing.T) {
	strategy := &SumBacklogStrategy{}

	// Test with large values
	backlogs := []int{1000000, 2000000, 3000000}
	got := strategy.Calculate(backlogs)

	// Should sum correctly without overflow
	assert.Equal(t, 6000000, got)
}

func TestLoadShedderWithSumStrategy(t *testing.T) {
	logger := logrus.New()
	reg := prometheus.NewRegistry()
	strategy := &SumBacklogStrategy{}
	shedder := NewLoadShedder(200, 0.8, 0, logger, reg, strategy)
	shedder.InitializeMetrics()

	controlResp := &puma.ControlResponse{
		Workers:       2,
		BootedWorkers: 2,
		WorkerStatus: []puma.Worker{
			{
				Index:  0,
				Booted: true,
				LastStatus: puma.WorkerStatus{
					Backlog: 150,
				},
			},
			{
				Index:  1,
				Booted: true,
				LastStatus: puma.WorkerStatus{
					Backlog: 100,
				},
			},
		},
	}

	shedder.UpdateBacklog(controlResp)

	// Should shed load (sum is 250, threshold is 200)
	assert.True(t, shedder.ShouldShedLoad())
	assert.Equal(t, 250, shedder.GetLastBacklog())
}

func TestNewBacklogStrategy(t *testing.T) {
	tests := []struct {
		name         string
		strategyName string
		want         BacklogStrategy
	}{
		{
			name:         "max strategy",
			strategyName: "max",
			want:         &MaxBacklogStrategy{},
		},
		{
			name:         "sum strategy",
			strategyName: "sum",
			want:         &SumBacklogStrategy{},
		},
		{
			name:         "empty defaults to max",
			strategyName: "",
			want:         &MaxBacklogStrategy{},
		},
		{
			name:         "unknown defaults to max",
			strategyName: "unknown",
			want:         &MaxBacklogStrategy{},
		},
	}

	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			got := NewBacklogStrategy(tt.strategyName)
			assert.Equal(t, tt.want, got)
		})
	}
}

func TestLoadShedderHysteresis(t *testing.T) {
	logger := logrus.New()
	reg := prometheus.NewRegistry()
	// Threshold 100, hysteresis 0.8 (deactivate at 80)
	shedder := NewLoadShedder(100, 0.8, 0, logger, reg, nil)
	shedder.InitializeMetrics()

	// Start below threshold
	controlResp := &puma.ControlResponse{
		Workers:       1,
		BootedWorkers: 1,
		WorkerStatus: []puma.Worker{
			{
				Index:  0,
				Booted: true,
				LastStatus: puma.WorkerStatus{
					Backlog: 50,
				},
			},
		},
	}

	shedder.UpdateBacklog(controlResp)
	assert.False(t, shedder.ShouldShedLoad())

	// Exceed threshold - should activate shedding
	controlResp.WorkerStatus[0].LastStatus.Backlog = 150
	shedder.UpdateBacklog(controlResp)
	assert.True(t, shedder.ShouldShedLoad())

	// Drop to 90 (above hysteresis threshold of 80) - should still shed
	controlResp.WorkerStatus[0].LastStatus.Backlog = 90
	shedder.UpdateBacklog(controlResp)
	assert.True(t, shedder.ShouldShedLoad())

	// Drop to 79 (below hysteresis threshold of 80) - should deactivate shedding
	controlResp.WorkerStatus[0].LastStatus.Backlog = 79
	shedder.UpdateBacklog(controlResp)
	assert.False(t, shedder.ShouldShedLoad())

	// Go back up to 100 - should activate shedding again
	controlResp.WorkerStatus[0].LastStatus.Backlog = 100
	shedder.UpdateBacklog(controlResp)
	assert.True(t, shedder.ShouldShedLoad())
}
