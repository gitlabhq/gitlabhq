package duoworkflow

import (
	"fmt"
	"net/http"

	"gitlab.com/gitlab-org/gitlab/workhorse/internal/api"
	"gitlab.com/gitlab-org/gitlab/workhorse/internal/helper/fail"
	"gitlab.com/gitlab-org/gitlab/workhorse/internal/log"

	"github.com/gorilla/websocket"
)

var upgrader = websocket.Upgrader{}

// Handler creates an HTTP handler for Duo Workflow WebSocket connections.
func Handler(rails *api.API) http.Handler {
	return rails.PreAuthorizeHandler(func(w http.ResponseWriter, r *http.Request, a *api.Response) {
		conn, err := upgrader.Upgrade(w, r, nil)
		if err != nil {
			fail.Request(w, r, fmt.Errorf("failed to upgrade: %v", err))
			return
		}
		defer func() { _ = conn.Close() }()

		runner, err := newRunner(conn, rails, r, a.DuoWorkflow)
		if err != nil {
			fail.Request(w, r, fmt.Errorf("failed to initialize agent platform client: %v", err))
			return
		}
		defer func() { _ = runner.Close() }()

		if err := runner.Execute(r.Context()); err != nil {
			log.WithRequest(r).WithError(err).Error()
		}
	}, "")
}
