package duoworkflow

import (
	"fmt"
	"io"
	"net/http"

	"gitlab.com/gitlab-org/gitlab/workhorse/internal/api"
	"gitlab.com/gitlab-org/gitlab/workhorse/internal/helper/fail"
	"gitlab.com/gitlab-org/gitlab/workhorse/internal/log"

	"github.com/gorilla/websocket"
)

var upgrader = websocket.Upgrader{}

// Handler creates an HTTP handler for Duo Workflow WebSocket connections.
func Handler(rails api.PreAuthorizer) http.Handler {
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
		defer func() { _ = wf.Close() }()

		errCh := make(chan error, 2)
		go fromWebsocketsToDuoWorkflowService(conn, wf, errCh)
		go fromDuoWorkflowServiceToWebsockets(conn, wf, errCh)

		if err := <-errCh; err != nil {
			log.WithRequest(r).WithError(err).Error()
		}
	}, "")
}

func fromWebsocketsToDuoWorkflowService(conn *websocket.Conn, wf WorkflowStream, errCh chan error) {
	for {
		_, message, err := conn.ReadMessage()
		if err != nil {
			errCh <- fmt.Errorf("failed to read a Duo Workflow WS message: %v", err)
			return
		}

		if err = wf.Send(message); err != nil {
			errCh <- fmt.Errorf("failed to write a grpc Duo Workflow message: %v", err)
			return
		}
	}
}

func fromDuoWorkflowServiceToWebsockets(conn *websocket.Conn, wf WorkflowStream, errCh chan error) {
	for {
		message, err := wf.Recv()
		if err != nil {
			if err == io.EOF { // Expected error when a workflow ends
				errCh <- nil
			} else {
				errCh <- fmt.Errorf("failed to read a grpc Duo Workflow message: %v", err)
			}
			return
		}

		if err = conn.WriteMessage(websocket.BinaryMessage, message); err != nil {
			errCh <- fmt.Errorf("failed to write a Duo Workflow WS message: %v", err)
			return
		}
	}
}
