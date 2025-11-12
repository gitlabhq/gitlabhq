package duoworkflow

import (
	"context"
	"fmt"
	"net/http"
	"sync"
	"time"

	"gitlab.com/gitlab-org/gitlab/workhorse/internal/api"
	"gitlab.com/gitlab-org/gitlab/workhorse/internal/helper/fail"
	"gitlab.com/gitlab-org/gitlab/workhorse/internal/helper/shutdown"
	"gitlab.com/gitlab-org/gitlab/workhorse/internal/log"

	"github.com/gorilla/websocket"
)

// Handler manages Duo Workflow WebSocket connections and provides graceful shutdown
// for active workflow runners. It tracks all active runners to ensure they can be
// properly terminated during server shutdown.
type Handler struct {
	rails    *api.API
	upgrader websocket.Upgrader
	runners  sync.Map // map[*runner]bool
}

// NewHandler creates a new Handler for managing Duo Workflow WebSocket connections.
// The handler maintains a registry of active runners to support graceful shutdown
// of WebSocket connections during server termination.
func NewHandler(rails *api.API) *Handler {
	return &Handler{
		rails:    rails,
		upgrader: websocket.Upgrader{},
	}
}

// Shutdown gracefully terminates all active workflow runners within the provided context timeout.
// It collects all active runners and initiates shutdown concurrently for all of them.
func (h *Handler) Shutdown(ctx context.Context) error {
	var runners []shutdown.GracefulCloser

	h.runners.Range(func(key, _ interface{}) bool {
		if r, ok := key.(*runner); ok {
			runners = append(runners, r)
		}
		return true
	})

	return shutdown.ShutdownAll(ctx, runners...)
}

// Build returns an HTTP handler that processes Duo Workflow WebSocket connections.
// The handler performs pre-authorization checks, upgrades the connection to WebSocket,
// and manages the lifecycle of the workflow runner including registration and cleanup.
func (h *Handler) Build() http.Handler {
	return h.rails.PreAuthorizeHandler(func(w http.ResponseWriter, r *http.Request, a *api.Response) {
		conn, err := h.upgrader.Upgrade(w, r, nil)
		if err != nil {
			fail.Request(w, r, fmt.Errorf("failed to upgrade: %v", err))
			return
		}

		runner, err := newRunner(conn, h.rails, r, a.DuoWorkflow)
		if err != nil {
			fail.Request(w, r, fmt.Errorf("failed to initialize agent platform client: %v", err))
			if closeErr := conn.Close(); closeErr != nil {
				log.WithRequest(r).WithError(closeErr).Error("failed to close connection")
			}
			return
		}
		h.runners.Store(runner, true)
		defer func() {
			h.runners.Delete(runner)
			_ = runner.Close()
		}()

		start := time.Now()
		if err := runner.Execute(r.Context()); err != nil {
			log.WithRequest(r).WithError(err).WithFields(log.Fields{
				"duration_ms": time.Since(start).Milliseconds(),
			}).Error()
		}
	}, "")
}
