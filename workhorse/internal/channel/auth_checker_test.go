package channel

import (
	"testing"
	"time"

	"gitlab.com/gitlab-org/gitlab/workhorse/internal/api"
)

func checkerSeries(values ...*api.ChannelSettings) AuthCheckerFunc {
	return func() *api.ChannelSettings {
		if len(values) == 0 {
			return nil
		}
		out := values[0]
		values = values[1:]
		return out
	}
}

func TestAuthCheckerStopsWhenAuthFails(t *testing.T) {
	template := &api.ChannelSettings{Url: "ws://example.com"}
	stopCh := make(chan error)
	series := checkerSeries(template, template, template)
	ac := NewAuthChecker(series, template, stopCh)

	go ac.Loop(1 * time.Millisecond)
	if err := <-stopCh; err != ErrAuthChanged {
		t.Fatalf("Expected ErrAuthChanged, got %v", err)
	}

	if ac.Count != 3 {
		t.Fatalf("Expected 3 successful checks, got %v", ac.Count)
	}
}

func TestAuthCheckerStopsWhenAuthChanges(t *testing.T) {
	template := &api.ChannelSettings{Url: "ws://example.com"}
	changed := template.Clone()
	changed.Url = "wss://example.com"
	stopCh := make(chan error)
	series := checkerSeries(template, changed, template)
	ac := NewAuthChecker(series, template, stopCh)

	go ac.Loop(1 * time.Millisecond)
	if err := <-stopCh; err != ErrAuthChanged {
		t.Fatalf("Expected ErrAuthChanged, got %v", err)
	}

	if ac.Count != 1 {
		t.Fatalf("Expected 1 successful check, got %v", ac.Count)
	}
}
