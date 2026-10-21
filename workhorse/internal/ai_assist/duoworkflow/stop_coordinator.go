package duoworkflow

import (
	"errors"
	"sync"
	"sync/atomic"
	"time"
)

// stopCoordinator manages the graceful stop handshake between workhorse and DWS.
// When workhorse needs to stop a workflow (client disconnect, keepalive failure,
// server shutdown), it sends a StopWorkflowRequest and waits for DWS to
// acknowledge by closing the gRPC stream with an Unavailable status code.
type stopCoordinator struct {
	// requested is set to true when stopWorkflow sends a StopWorkflowRequest
	// to DWS. It gates whether an Unavailable gRPC error from DWS should be
	// treated as a stop acknowledgment.
	requested atomic.Bool

	// requestedAt is when the stop request was sent, in Unix nanoseconds.
	// Close waits for DWS to end the stream only until one stop timeout after
	// it, so the lock is not held for a second timeout.
	requestedAt atomic.Int64

	// sendOnce guards sending the StopWorkflowRequest, and sendErr is its
	// outcome, which every caller of request reports.
	sendOnce sync.Once
	sendErr  error

	// acked is closed when DWS acknowledges a stop request by returning a
	// gRPC Unavailable error on the Recv stream. stopWorkflow selects on this
	// channel so it can return immediately instead of waiting for the full
	// timeout.
	acked chan struct{}

	// agentDone tracks the lifetime of handleAgentMessages. Close waits on
	// this before tearing down the gRPC stream so that a pending Recv can
	// observe the DWS stop acknowledgment before the connection is destroyed.
	agentDone sync.WaitGroup

	// workflowEnded is set to true when handleAgentMessages receives io.EOF,
	// meaning DWS finished the workflow naturally, or an unsolicited Unavailable,
	// meaning DWS closed the stream while draining. When this is set,
	// handleClientEvents should not attempt to send a StopWorkflowRequest
	workflowEnded atomic.Bool

	// shutdownStarted is set to true at the start of Shutdown. Close only
	// waits on shutdownDone when this is set, since Shutdown is only invoked
	// during server shutdown and never in the normal request path.
	shutdownStarted atomic.Bool

	// shutdownDone is closed by Shutdown when it finishes. Close waits on
	// this before closing the client transport so that Shutdown always gets to
	// send its going-away signal before Close terminates the connection.
	shutdownDone chan struct{}
}

var errStopTimedOut = errors.New("workflow didn't stop on time")

// request sends the StopWorkflowRequest once, however many callers stop the
// workflow at the same time. Every caller gets the outcome of that one send,
// then waits for the same acknowledgment.
func (s *stopCoordinator) request(send func() error, timeout time.Duration) error {
	s.sendOnce.Do(func() {
		s.requestedAt.Store(time.Now().UnixNano())
		s.requested.Store(true)
		s.sendErr = send()
	})

	if s.sendErr != nil {
		return s.sendErr
	}

	return s.waitForAck(timeout)
}

// remaining returns what is left of timeout since the stop request, which
// stopWorkflow has usually spent waiting for the acknowledgment.
func (s *stopCoordinator) remaining(timeout time.Duration) time.Duration {
	if at := s.requestedAt.Load(); at != 0 {
		return time.Until(time.Unix(0, at).Add(timeout))
	}
	return timeout
}

// acknowledge records that DWS ended the stream in response to a stop request.
func (s *stopCoordinator) acknowledge() {
	close(s.acked)
}

func (s *stopCoordinator) waitForAck(timeout time.Duration) error {
	select {
	case <-s.acked:
		return nil
	case <-time.After(timeout):
		return errStopTimedOut
	}
}

// waitForAgent waits for handleAgentMessages to end, for at most timeout, and
// reports whether it did.
func (s *stopCoordinator) waitForAgent(timeout time.Duration) bool {
	done := make(chan struct{})
	go func() {
		s.agentDone.Wait()
		close(done)
	}()

	select {
	case <-done:
		return true
	case <-time.After(timeout):
		return false
	}
}
