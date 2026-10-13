package duoworkflow

import (
	"context"
	"errors"
	"time"

	pb "gitlab.com/gitlab-org/modelops/applied-ml/code-suggestions/ai-assist/clients/gopb/contract"
)

// StopWorkflowRequest reasons reported to Duo Workflow Service. The values keep
// the historical WebSocket wording so DWS-side telemetry matching on them keeps
// working.
const (
	// reasonKeepaliveFailed is reported when the keepalive to the client fails.
	reasonKeepaliveFailed = "WORKHORSE_WEBSOCKET_PING_FAILED"

	// reasonPongTimeout is reported when the client stops answering pings.
	reasonPongTimeout = "WORKHORSE_WEBSOCKET_PONG_TIMEOUT"

	// reasonClosePrefix prefixes the reason reported when the client closes the
	// WebSocket with a normal code, e.g. WORKHORSE_WEBSOCKET_CLOSE_1000.
	reasonClosePrefix = "WORKHORSE_WEBSOCKET_CLOSE_"

	// reasonServerShutdown is reported when this workhorse instance is draining.
	reasonServerShutdown = "WORKHORSE_SERVER_SHUTDOWN"
)

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

	// SendGoingAway tells the client that the workflow stream is going away, either
	// because this workhorse instance is shutting down or because Duo Workflow
	// Service closed the stream, and that it should reconnect to resume the
	// workflow. The reason is forwarded to the client for diagnostics only.
	SendGoingAway(reason string) error

	// SendInvalidRequest tells the client that Duo Workflow Service rejected
	// the request as invalid, so it must not be retried unchanged.
	SendInvalidRequest(reason string) error

	// Close terminates the connection.
	Close() error
}
