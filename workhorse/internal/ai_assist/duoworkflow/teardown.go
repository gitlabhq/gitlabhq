package duoworkflow

import (
	"strings"
	"sync/atomic"
)

// teardownReason explains why an ExecuteWorkflow stream ended, so that
// sessionErrorsTotal can show what sits behind each gRPC code. Workhorse
// records it as soon as it learns the cause, which always happens before the
// resulting teardown reaches Recv.
type teardownReason int32

const (
	// teardownUnsolicited means nothing on the workhorse side asked for this
	// teardown: the stream ended on its own, so DWS closed it or the transport
	// between the two failed. This is the zero value, so a session where
	// workhorse never noticed anything reports it.
	teardownUnsolicited teardownReason = iota

	// teardownClientNormalClose means the client closed the WebSocket with a
	// normal code (1000 or 1001): the user closed the browser tab or the IDE
	// panel, or stopped the flow.
	teardownClientNormalClose

	// teardownClientPongTimeout means the client stopped answering pings.
	teardownClientPongTimeout

	// teardownClientKeepaliveFailed means writing a keepalive to the client
	// failed, so its connection was already gone.
	teardownClientKeepaliveFailed

	// teardownClientReadFailed means reading from the client failed in a way
	// ReadError does not treat as an orderly disconnect: an abnormal WebSocket
	// closure, a connection reset, or an unparsable message. No
	// StopWorkflowRequest is sent on this path; the stream is torn down
	// locally, which is why it must not be confused with teardownUnsolicited.
	teardownClientReadFailed

	// teardownWorkhorseShutdown means this workhorse instance is draining.
	teardownWorkhorseShutdown
)

// String returns the value used for the teardown_reason metric label.
func (t teardownReason) String() string {
	switch t {
	case teardownClientNormalClose:
		return "client_normal_close"
	case teardownClientPongTimeout:
		return "client_pong_timeout"
	case teardownClientKeepaliveFailed:
		return "client_keepalive_failed"
	case teardownClientReadFailed:
		return "client_read_failed"
	case teardownWorkhorseShutdown:
		return "workhorse_shutdown"
	default:
		return "unsolicited"
	}
}

// clientDisconnectReason maps a StopWorkflowRequest reason that ReadError
// produced onto its teardown category. ReadError only reports a reason for
// disconnects it considers orderly; anything else is teardownClientReadFailed.
func clientDisconnectReason(reason string) teardownReason {
	switch {
	case reason == reasonPongTimeout:
		return teardownClientPongTimeout
	case strings.HasPrefix(reason, reasonClosePrefix):
		return teardownClientNormalClose
	default:
		return teardownClientReadFailed
	}
}

// teardownTracker keeps the first teardownReason recorded for a session.
// Anything that fails afterwards is a consequence of it, not an independent
// cause.
type teardownTracker struct {
	reason atomic.Int32
}

func (t *teardownTracker) record(reason teardownReason) {
	t.reason.CompareAndSwap(int32(teardownUnsolicited), int32(reason))
}

// load reports the cause recorded for the teardown Recv is observing.
func (t *teardownTracker) load() teardownReason {
	return teardownReason(t.reason.Load())
}
