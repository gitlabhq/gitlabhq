package healthcheck

import (
	"sync/atomic"
	"time"
)

// SuccessRecorder defines the interface for recording successful requests
type SuccessRecorder interface {
	RecordSuccess()
}

// HasRecentSuccessChecker defines the interface for checking recent success
type HasRecentSuccessChecker interface {
	HasRecentSuccess(skipInterval time.Duration) bool
}

// OptimizedReadinessChecker combines success recording and checking capabilities
type OptimizedReadinessChecker interface {
	SuccessRecorder
	HasRecentSuccessChecker
}

// SuccessTracker tracks successful 20x responses from proxied routes
// to optimize readiness checks by only checking when no recent successful
// requests have been processed.
type SuccessTracker struct {
	// lastSuccessTime stores the Unix nanosecond timestamp of the last successful 20x response
	lastSuccessTime atomic.Int64
}

// NewSuccessTracker creates a new SuccessTracker
func NewSuccessTracker() *SuccessTracker {
	return &SuccessTracker{}
}

// RecordSuccess records a successful 20x response
func (st *SuccessTracker) RecordSuccess() {
	st.lastSuccessTime.Store(time.Now().UnixNano())
}

// HasRecentSuccess checks if there has been a successful 20x response
// within the specified duration
func (st *SuccessTracker) HasRecentSuccess(within time.Duration) bool {
	lastSuccess := st.lastSuccessTime.Load()
	if lastSuccess == 0 {
		return false // No success recorded yet
	}

	return time.Since(time.Unix(0, lastSuccess)) <= within
}

// GetLastSuccessTime returns the time of the last successful response
func (st *SuccessTracker) GetLastSuccessTime() time.Time {
	lastSuccess := st.lastSuccessTime.Load()
	if lastSuccess == 0 {
		return time.Time{} // Zero time if no success recorded
	}
	return time.Unix(0, lastSuccess)
}
