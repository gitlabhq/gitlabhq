package duoworkflow

import (
	"context"
	"errors"
	"fmt"
	"net/http"
	"sync"
	"time"

	pb "gitlab.com/gitlab-org/modelops/applied-ml/code-suggestions/ai-assist/clients/gopb/contract"

	"gitlab.com/gitlab-org/gitlab/workhorse/internal/log"
)

// httpKeepaliveInterval is how often an empty line is written to an otherwise
// idle response. A flow can spend a minute inside a single model call without
// producing a checkpoint, and intermediate proxies close a response that
// produces no bytes (nginx proxy_read_timeout defaults to 60s).
const httpKeepaliveInterval = 20 * time.Second

// ndjsonContentType is newline-delimited JSON: one protojson-encoded Action per
// line. Empty lines are keepalives and carry no action.
const ndjsonContentType = "application/x-ndjson"

// errClientGone is returned by ReadClientEvent once the request context is
// canceled, which is how net/http reports that the caller went away.
var errClientGone = errors.New("ndjsonTransport: client is gone")

// errTransportClosed is returned by ReadClientEvent after Close, so the read
// loop unwinds without asking Duo Workflow Service to stop a workflow that has
// already ended.
var errTransportClosed = errors.New("ndjsonTransport: transport is closed")

// ndjsonTransport is the clientTransport used when workhorse executes a flow
// itself, with no client in the loop. It reports a single client event, the
// StartWorkflowRequest the handler built from the request body, and streams
// the actions Duo Workflow Service sends back as newline-delimited JSON over
// one chunked response.
//
// Actions are not offered to the caller for execution: a caller of this
// endpoint has no filesystem, no shell, and no way to answer. Only
// NewCheckpoint is written out, so the caller can follow the flow's progress;
// every other action is rejected with errActionUnsupported and runner answers
// Duo Workflow Service on the caller's behalf.
type ndjsonTransport struct {
	w          http.ResponseWriter
	rc         *http.ResponseController
	req        *http.Request
	startEvent *pb.ClientEvent

	// closed is closed by Close, to release a ReadClientEvent that is still
	// waiting for a client event that will never come.
	closed    chan struct{}
	closeOnce sync.Once

	// writeMu serializes the keepalive goroutine against the goroutine
	// forwarding actions. Both write to w, and it guards the fields below.
	writeMu sync.Mutex
	// headerWritten records whether the response status line has been
	// committed. Until it has, a failure can still be reported as an HTTP
	// status code instead of an empty 200 response.
	headerWritten bool
	buf           []byte

	// invalidRequestMu guards invalidRequestReason, which is set from the
	// goroutine reading from Duo Workflow Service and read by the handler
	// after the runner has finished.
	invalidRequestMu     sync.Mutex
	invalidRequestReason string

	startRead bool
}

func newNdjsonTransport(w http.ResponseWriter, r *http.Request, startEvent *pb.ClientEvent) *ndjsonTransport {
	return &ndjsonTransport{
		w: w,
		// w is wrapped by middleware that implements Unwrap but not
		// http.Flusher, so a plain w.(http.Flusher) assertion fails even
		// though the underlying writer can flush. ResponseController follows
		// the Unwrap chain.
		rc:         http.NewResponseController(w), //nolint:bodyclose // false-positive https://github.com/timakin/bodyclose/issues/52
		req:        r,
		startEvent: startEvent,
		closed:     make(chan struct{}),
	}
}

// Start reports nothing to the caller yet. The response header is committed on
// the first write instead, so that a lock conflict or a Duo Workflow Service
// rejection, neither of which can happen after the first action, is still
// reported as an HTTP status code.
func (t *ndjsonTransport) Start() error { return nil }

// KeepaliveInterval returns how often an empty line should be written to an
// idle response.
func (t *ndjsonTransport) KeepaliveInterval() time.Duration { return httpKeepaliveInterval }

// Keepalive writes an empty line, which ndjson readers skip. It keeps proxies
// from closing an idle response and surfaces a caller that stopped reading.
func (t *ndjsonTransport) Keepalive() error {
	t.writeMu.Lock()
	defer t.writeMu.Unlock()

	t.buf = t.buf[:0]

	return t.flushLineLocked()
}

// ReadClientEvent reports the StartWorkflowRequest the handler built from the
// request body, then blocks: this transport's caller sends nothing else. The
// wait ends when the caller goes away or the transport is closed, which runner
// tells apart through ReadError.
func (t *ndjsonTransport) ReadClientEvent() (*pb.ClientEvent, error) {
	if !t.startRead {
		t.startRead = true
		return t.startEvent, nil
	}

	select {
	case <-t.req.Context().Done():
		return nil, errClientGone
	case <-t.closed:
		return nil, errTransportClosed
	}
}

// ReadError never asks for a StopWorkflowRequest.
//
// A caller going away cancels the request context, and the gRPC stream to Duo
// Workflow Service is derived from that same context, so by the time this is
// called the stream is already gone and nothing can be sent on it. Duo Workflow
// Service sees the canceled stream and treats it as a disconnect, exactly as it
// does when a WebSocket client vanishes, leaving the workflow resumable from its
// last checkpoint.
//
// A stop request is still sent on the paths where the stream is intact, most
// importantly a workhorse shutdown while the caller is still connected.
func (t *ndjsonTransport) ReadError(_ error) (reason string, ok bool) {
	return "", false
}

// WriteAction writes an action to the response, or rejects it with
// errActionUnsupported when the caller of this endpoint cannot execute it.
func (t *ndjsonTransport) WriteAction(_ context.Context, action *pb.Action) error {
	if _, ok := action.Action.(*pb.Action_NewCheckpoint); !ok {
		return fmt.Errorf("%w: %T", errActionUnsupported, action.Action)
	}

	t.writeMu.Lock()
	defer t.writeMu.Unlock()

	var err error
	if t.buf, err = marshaler.MarshalAppend(t.buf[:0], action); err != nil {
		return fmt.Errorf("WriteAction: failed to marshal action: %w", err)
	}

	return t.flushLineLocked()
}

// SendGoingAway has nothing to send: the response carries actions only, so a
// shutdown just ends the stream. The caller tells a stopped flow apart from a
// finished one through the workflow's status, which Duo Workflow Service keeps
// up to date.
func (t *ndjsonTransport) SendGoingAway() error { return nil }

// SendInvalidRequest records the reason for the handler rather than sending it,
// for the same reason as SendGoingAway. The handler reports it as a 400 when
// the response has not been committed yet, which is the case whenever Duo
// Workflow Service rejects the start request itself.
func (t *ndjsonTransport) SendInvalidRequest(reason string) error {
	t.invalidRequestMu.Lock()
	defer t.invalidRequestMu.Unlock()

	t.invalidRequestReason = reason

	return nil
}

// InvalidRequestReason returns the reason Duo Workflow Service gave for
// rejecting the request as invalid, or an empty string if it did not.
func (t *ndjsonTransport) InvalidRequestReason() string {
	t.invalidRequestMu.Lock()
	defer t.invalidRequestMu.Unlock()

	return t.invalidRequestReason
}

// Close releases a pending ReadClientEvent. The response itself is finished by
// net/http once the handler returns.
func (t *ndjsonTransport) Close() error {
	t.closeOnce.Do(func() { close(t.closed) })

	return nil
}

// HeaderWritten reports whether the response status line has been committed.
// The handler uses it to decide whether a failure can still be reported as an
// HTTP status code.
func (t *ndjsonTransport) HeaderWritten() bool {
	t.writeMu.Lock()
	defer t.writeMu.Unlock()

	return t.headerWritten
}

// flushLineLocked terminates buf with a newline, writes it and flushes,
// committing the response header on the first call.
func (t *ndjsonTransport) flushLineLocked() error {
	if !t.headerWritten {
		t.w.Header().Set("Content-Type", ndjsonContentType)
		t.w.WriteHeader(http.StatusOK)
		t.headerWritten = true

		log.WithRequest(t.req).Info("ndjsonTransport: streaming actions to the caller")
	}

	t.buf = append(t.buf, '\n')

	//nolint:gosec // G705: the payload is protojson workhorse marshaled itself, served as application/x-ndjson
	if _, err := t.w.Write(t.buf); err != nil {
		return fmt.Errorf("ndjsonTransport: failed to write to response: %w", err)
	}

	if err := t.rc.Flush(); err != nil {
		return fmt.Errorf("ndjsonTransport: failed to flush response: %w", err)
	}

	return nil
}
