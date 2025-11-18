/*
Package upstream implements handlers for handling upstream requests.

This file provides functionality for managing upgraded long-running connections (like WebSockets)
*/
package upstream

import (
	"context"
	"time"

	"gitlab.com/gitlab-org/labkit/log"

	"gitlab.com/gitlab-org/gitlab/workhorse/internal/helper/shutdown"
)

// When a connection fails to stop naturally, we forcefully stop the connection.
// This value defines how much time we give the connection to stop once it was forcefully terminated.
const stopTimeoutSeconds = 10

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

// Shutdown gracefully terminates all registered handlers within the provided delay value.
// It delegates to the shutdown helper to coordinate the shutdown of all handlers concurrently.
// This ensures that upgraded connections (like WebSockets) receive proper closing handshakes
// before the server terminates.
func (m *UpgradedConnsManager) Shutdown(period time.Duration) {
	timeoutSeconds := period.Seconds() - stopTimeoutSeconds
	if timeoutSeconds < 0 {
		timeoutSeconds = 0
	}
	log.WithFields(log.Fields{"shutdown_timeout_s": timeoutSeconds}).Infof("upgraded connections: shutdown initiated")

	ctx, cancel := context.WithTimeout(context.Background(), time.Duration(timeoutSeconds)*time.Second) // lint:allow context.Background
	defer cancel()

	if err := shutdown.ShutdownAll(ctx, m.handlers...); err != nil {
		log.WithError(err).Errorf("upgraded connections: failed to shut down gracefully %v", err)
	}

	log.Info("upgraded connections: shutting down")
}
