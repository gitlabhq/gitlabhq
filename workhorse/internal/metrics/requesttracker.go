// Package metrics is used to track various metrics and flags for incoming requests in GitLab Workhorse.
// This package provides utilities to manage request metadata, such as setting and retrieving arbitrary flags.
package metrics

import (
	"context"
)

const (
	// KeyFetchedExternalURL is a flag key used to track whether the request fetched an external URL.
	KeyFetchedExternalURL = "fetched_external_url"
)

// RequestTracker is a simple container for request metadata and flags
type RequestTracker struct {
	// Flags stores arbitrary string values for the request
	Flags map[string]string
}

// NewRequestTracker creates a new RequestTracker
func NewRequestTracker() *RequestTracker {
	return &RequestTracker{
		Flags: make(map[string]string),
	}
}

// SetFlag sets a flag value
func (rt *RequestTracker) SetFlag(key, value string) {
	rt.Flags[key] = value
}

// GetFlag gets a flag value
func (rt *RequestTracker) GetFlag(key string) (string, bool) {
	val, ok := rt.Flags[key]
	return val, ok
}

// HasFlag returns true if the flag exists and equals the given value
func (rt *RequestTracker) HasFlag(key, value string) bool {
	if val, ok := rt.Flags[key]; ok {
		return val == value
	}
	return false
}

// Context key for storing the request tracker
type contextKey string

// TrackerKey is the key used to store the RequestTracker in context
const TrackerKey contextKey = "requestTracker"

// FromContext retrieves the RequestTracker from context
func FromContext(ctx context.Context) (*RequestTracker, bool) {
	rt, ok := ctx.Value(TrackerKey).(*RequestTracker)
	return rt, ok
}

// NewContext creates a new context with the RequestTracker
func NewContext(ctx context.Context, rt *RequestTracker) context.Context {
	return context.WithValue(ctx, TrackerKey, rt)
}
