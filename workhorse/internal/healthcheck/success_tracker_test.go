package healthcheck

import (
	"testing"
	"time"
)

func TestSuccessTracker(t *testing.T) {
	tracker := NewSuccessTracker()

	// Initially should have no recent success
	if tracker.HasRecentSuccess(time.Second) {
		t.Error("Expected no recent success initially")
	}

	// Record a success
	tracker.RecordSuccess()

	// Should now have recent success
	if !tracker.HasRecentSuccess(time.Second) {
		t.Error("Expected recent success after recording")
	}

	// Emulate expiration
	tracker.lastSuccessTime.Store(time.Now().UnixNano() - int64(6*time.Millisecond))
	if tracker.HasRecentSuccess(5 * time.Millisecond) {
		t.Error("Expected success to expire after timeout")
	}

	// But should still be recent for longer duration
	if !tracker.HasRecentSuccess(time.Second) {
		t.Error("Expected success to still be recent for longer duration")
	}
}

func TestSuccessTrackerGetLastSuccessTime(t *testing.T) {
	tracker := NewSuccessTracker()

	// Initially should return zero time
	if !tracker.GetLastSuccessTime().IsZero() {
		t.Error("Expected zero time initially")
	}

	// Record success and check time
	before := time.Now()
	tracker.RecordSuccess()
	after := time.Now()

	lastSuccess := tracker.GetLastSuccessTime()
	if lastSuccess.Before(before) || lastSuccess.After(after.Add(time.Millisecond)) {
		t.Errorf("Last success time %v should be between %v and %v", lastSuccess, before, after)
	}
}
