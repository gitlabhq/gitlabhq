package healthcheck

import (
	"net/http"
	"net/http/httptest"
	"testing"
	"time"
)

func TestBackendSuccessTrackingMiddleware(t *testing.T) {
	// Create a test handler that returns different status codes
	testHandler := http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		switch r.URL.Path {
		case "/success":
			w.WriteHeader(http.StatusOK)
		case "/created":
			w.WriteHeader(http.StatusCreated)
		case "/error":
			w.WriteHeader(http.StatusInternalServerError)
		case "/notfound":
			w.WriteHeader(http.StatusNotFound)
		default:
			w.WriteHeader(http.StatusOK)
		}
	})

	// Test successful responses (20x)
	testCases := []struct {
		path            string
		expectedTracked bool
		description     string
	}{
		{"/success", true, "200 OK should be tracked"},
		{"/created", true, "201 Created should be tracked"},
		{"/error", false, "500 Internal Server Error should not be tracked"},
		{"/notfound", false, "404 Not Found should not be tracked"},
	}

	for _, tc := range testCases {
		t.Run(tc.description, func(t *testing.T) {
			// Reset tracker
			tracker := NewSuccessTracker()
			middleware := BackendSuccessTrackingMiddleware(tracker)
			handler := middleware(testHandler)

			// Make request
			req := httptest.NewRequest("GET", tc.path, nil)
			w := httptest.NewRecorder()
			handler.ServeHTTP(w, req)

			// Check if success was tracked
			hasRecentSuccess := tracker.HasRecentSuccess(time.Second)
			if hasRecentSuccess != tc.expectedTracked {
				t.Errorf("Expected tracked=%v, got tracked=%v for path %s",
					tc.expectedTracked, hasRecentSuccess, tc.path)
			}
		})
	}
}

func TestResponseTracker(t *testing.T) {
	w := httptest.NewRecorder()
	tracker := NewResponseTracker(w)

	// Default should be 200
	if tracker.StatusCode() != http.StatusOK {
		t.Errorf("Expected default status code 200, got %d", tracker.StatusCode())
	}

	// Write a different status code
	tracker.WriteHeader(http.StatusCreated)
	if tracker.StatusCode() != http.StatusCreated {
		t.Errorf("Expected status code 201, got %d", tracker.StatusCode())
	}

	// Check that the underlying response writer got the status code
	if w.Code != http.StatusCreated {
		t.Errorf("Expected underlying response writer to have status code 201, got %d", w.Code)
	}
}
