package healthcheck

import (
	"net/http"
	"net/http/httptest"
	"testing"

	"github.com/prometheus/client_golang/prometheus"
	"github.com/sirupsen/logrus"
	"github.com/stretchr/testify/assert"
)

func TestLoadSheddingMiddlewareSheds(t *testing.T) {
	logger := logrus.New()
	reg := prometheus.NewRegistry()
	shedder := NewLoadShedder(100, 0, logger, reg, nil)

	// Set up shedder to shed load
	controlResp := &PumaControlResponse{
		Workers:       1,
		BootedWorkers: 1,
		WorkerStatus: []PumaWorker{
			{
				Index:  0,
				Booted: true,
				LastStatus: PumaWorkerStatus{
					Backlog: 150,
				},
			},
		},
	}
	shedder.UpdateBacklog(controlResp)

	// Create a simple handler that would normally succeed
	nextHandler := http.HandlerFunc(func(w http.ResponseWriter, _ *http.Request) {
		w.WriteHeader(http.StatusOK)
		w.Write([]byte("OK"))
	})

	middleware := LoadSheddingMiddleware(shedder, logger)
	handler := middleware(nextHandler)

	// Make request
	req := httptest.NewRequest("GET", "/api/test", nil)
	w := httptest.NewRecorder()

	handler.ServeHTTP(w, req)

	// Should return 503
	assert.Equal(t, http.StatusServiceUnavailable, w.Code)
	assert.Equal(t, "0", w.Header().Get("Retry-After"))
}

func TestLoadSheddingMiddlewareAllows(t *testing.T) {
	logger := logrus.New()
	reg := prometheus.NewRegistry()
	shedder := NewLoadShedder(100, 0, logger, reg, nil)

	// Set up shedder to NOT shed load
	controlResp := &PumaControlResponse{
		Workers:       1,
		BootedWorkers: 1,
		WorkerStatus: []PumaWorker{
			{
				Index:  0,
				Booted: true,
				LastStatus: PumaWorkerStatus{
					Backlog: 50,
				},
			},
		},
	}
	shedder.UpdateBacklog(controlResp)

	// Create a simple handler
	nextHandler := http.HandlerFunc(func(w http.ResponseWriter, _ *http.Request) {
		w.WriteHeader(http.StatusOK)
		w.Write([]byte("OK"))
	})

	middleware := LoadSheddingMiddleware(shedder, logger)
	handler := middleware(nextHandler)

	// Make request
	req := httptest.NewRequest("GET", "/api/test", nil)
	w := httptest.NewRecorder()

	handler.ServeHTTP(w, req)

	// Should return 200 from next handler
	assert.Equal(t, http.StatusOK, w.Code)
	assert.Equal(t, "OK", w.Body.String())
}

func TestLoadSheddingMiddlewareNilShedder(t *testing.T) {
	logger := logrus.New()

	// Create a simple handler
	nextHandler := http.HandlerFunc(func(w http.ResponseWriter, _ *http.Request) {
		w.WriteHeader(http.StatusOK)
		w.Write([]byte("OK"))
	})

	middleware := LoadSheddingMiddleware(nil, logger)
	handler := middleware(nextHandler)

	// Make request
	req := httptest.NewRequest("GET", "/api/test", nil)
	w := httptest.NewRecorder()

	handler.ServeHTTP(w, req)

	// Should pass through to next handler
	assert.Equal(t, http.StatusOK, w.Code)
	assert.Equal(t, "OK", w.Body.String())
}
