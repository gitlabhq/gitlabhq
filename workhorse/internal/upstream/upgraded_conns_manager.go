/*
Package upstream implements handlers for handling upstream requests.

This file provides functionality for managing upgraded long-running connections (like WebSockets)
*/
package upstream

import (
	"context"

	"gitlab.com/gitlab-org/gitlab/workhorse/internal/helper/shutdown"
)

// UpgradedConnsManager manages graceful shutdown of upgraded HTTP connections (e.g., WebSockets).
// It maintains a registry of handlers that manage long-lived upgraded connections and ensures
// they are properly terminated during server shutdown. This is critical for WebSocket handlers
// that need to send closing handshakes and clean up resources before the server terminates.
type UpgradedConnsManager struct {
	handlers []shutdown.GracefulCloser
}

// Register adds a handler to the manager's registry for graceful shutdown coordination.
// Handlers registered here will be notified during server shutdown to allow them to
// gracefully terminate their upgraded connections.
func (m *UpgradedConnsManager) Register(handler shutdown.GracefulCloser) {
	m.handlers = append(m.handlers, handler)
}

// Shutdown gracefully terminates all registered handlers within the provided context timeout.
// It delegates to the shutdown helper to coordinate the shutdown of all handlers concurrently.
// This ensures that upgraded connections (like WebSockets) receive proper closing handshakes
// before the server terminates.
func (m *UpgradedConnsManager) Shutdown(ctx context.Context) error {
	if m == nil {
		return nil
	}

	return shutdown.ShutdownAll(ctx, m.handlers...)
}
