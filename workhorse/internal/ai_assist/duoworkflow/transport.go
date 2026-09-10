package duoworkflow

import (
	"context"
	"errors"
	"time"

	pb "gitlab.com/gitlab-org/modelops/applied-ml/code-suggestions/ai-assist/clients/gopb/contract"
)

// reasonKeepaliveFailed is the StopWorkflowRequest reason reported to Duo
// Workflow Service when the keepalive to the client fails. The value keeps the
// historical WebSocket wording so DWS-side telemetry matching on it keeps
// working.
const reasonKeepaliveFailed = "WORKHORSE_WEBSOCKET_PING_FAILED"

// errActionUnsupported is returned by WriteAction when the client on the other
// end cannot execute the action. Duo Workflow Service blocks until every action
// it emits is answered, so runner turns this into an error ActionResponse
// rather than dropping the action.
var errActionUnsupported = errors.New("action cannot be executed by this client")

// clientTransport is the connection to whoever started the workflow. runner
// orchestrates a workflow purely through this interface, so the gRPC stream
// handling, MCP tool execution, locking and shutdown behavior are shared by
// every transport. wsManager is the WebSocket implementation.
type clientTransport interface {
	// Start prepares the transport for reading and writing. It is called once,
	// before runner spawns any goroutine.
	Start() error

	// KeepaliveInterval is how often Keepalive should be called to keep the
	// connection alive through intermediate idle timeouts.
	KeepaliveInterval() time.Duration

	// Keepalive performs a single liveness signal towards the client.
	Keepalive() error

	// ReadClientEvent blocks until the client sends the next event.
	ReadClientEvent() (*pb.ClientEvent, error)

	// ReadError classifies an error returned by ReadClientEvent into a
	// StopWorkflowRequest reason. It returns ok=false for errors that are not
	// an orderly disconnect and should be propagated as-is.
	ReadError(err error) (reason string, ok bool)

	// WriteAction forwards an action from Duo Workflow Service to the client
	// for execution. It returns errActionUnsupported when this client cannot
	// execute the action, so that runner can answer Duo Workflow Service on
	// its behalf.
	WriteAction(ctx context.Context, action *pb.Action) error

	// SendGoingAway tells the client that this workhorse instance is shutting
	// down and that it should reconnect to resume the workflow.
	SendGoingAway() error

	// SendInvalidRequest tells the client that Duo Workflow Service rejected
	// the request as invalid, so it must not be retried unchanged.
	SendInvalidRequest(reason string) error

	// Close terminates the connection.
	Close() error
}
