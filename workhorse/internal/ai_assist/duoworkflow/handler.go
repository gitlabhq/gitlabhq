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

		dw := a.DuoWorkflow
		client, err := NewClient(dw.ServiceURI, dw.Headers, dw.Secure)
		if err != nil {
			fail.Request(w, r, fmt.Errorf("failed to create a Duo Workflow client: %v", err))
			return
		}
		defer func() { _ = client.Close() }()

		wf, err := client.ExecuteWorkflow(r.Context())
		if err != nil {
			fail.Request(w, r, fmt.Errorf("failed to execute a Duo Workflow: %v", err))
			return
		}
		defer func() { _ = wf.CloseSend() }()

		runner := &runner{
			rails:       rails,
			token:       dw.Headers["x-gitlab-oauth-token"],
			originalReq: r,
			conn:        conn,
			wf:          wf,
		}

		if err := runner.Execute(r.Context()); err != nil {
			log.WithRequest(r).WithError(err).Error()
		}
	}, "")
}
