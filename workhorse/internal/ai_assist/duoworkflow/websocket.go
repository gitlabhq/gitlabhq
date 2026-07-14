package duoworkflow

import (
	"context"
	"errors"
	"fmt"
	"net"
	"slices"
	"sync/atomic"
	"time"
	"unicode/utf8"

	pb "gitlab.com/gitlab-org/modelops/applied-ml/code-suggestions/ai-assist/clients/gopb/contract"

	"gitlab.com/gitlab-org/gitlab/workhorse/internal/log"

	"github.com/gorilla/websocket"
	"google.golang.org/protobuf/encoding/protojson"
)

const wsWriteDeadline = 60 * time.Second
const wsCloseTimeout = 5 * time.Second
const wsStopWorkflowTimeout = 10 * time.Second

// wsPingInterval controls how often the server sends WebSocket ping frames to
// the client. This keeps the connection alive through load-balancer idle
// timeouts and provides early detection of silently-dropped TCP connections.
// The value must be less than any intermediate idle-connection timeout (GKE's
// default is 30s for HTTP/1.1 upgrades).
const wsPingInterval = 20 * time.Second

// wsPongTimeout is the read deadline set after each pong (or at startup before
// the first ping). If no pong arrives within this window, ReadMessage returns a
// timeout error and the connection is treated as dead. It is longer than
// wsPingInterval to tolerate one missed pong before declaring the connection
// broken.
const wsPongTimeout = wsPingInterval + 10*time.Second

var normalClosureErrCodes = []int{websocket.CloseGoingAway, websocket.CloseNormalClosure}

var marshaler = protojson.MarshalOptions{
	UseProtoNames:   true,
	EmitUnpopulated: true,
}

var unmarshaler = protojson.UnmarshalOptions{
	DiscardUnknown: true,
}

type websocketConn interface {
	ReadMessage() (int, []byte, error)
	WriteMessage(int, []byte) error
	WriteControl(int, []byte, time.Time) error
	SetReadDeadline(time.Time) error
	SetWriteDeadline(time.Time) error
	SetPongHandler(h func(appData string) error)
	Close() error
}

type capability string

const (
	// Client capabilities
	capabilityIncrementalStreaming capability = "incremental_streaming"
	capabilityShellCommand         capability = "shell_command"
	capabilityReadFileChunked      capability = "read_file_chunked"
	capabilityCommandTimeout       capability = "command_timeout"
	capabilityWebSearch            capability = "web_search"

	// Server capabilities
	capabilityAdvancedSearch          capability = "advanced_search"
	capabilityToolCallApproval        capability = "tool_call_approval"
	capabilityToolCallPatternApproval capability = "tool_call_pattern_approval"
	capabilityJobTracePagination      capability = "job_trace_pagination"
	capabilityIncrementalCheckpoints  capability = "incremental_checkpoints"
)

// ClientCapabilities is how gitlab-lsp -> workhorse -> Duo Workflow Service communicates
// capabilities that can be used by Duo Workflow Service without breaking
// backwards compatibility. We intersect the capabilities of all parties and
// then new behavior can only depend on that behavior if it makes it all the
// way through. Whenever you add to this list you must also update the gitlab-lsp and
// either updates the constant in ee/app/assets/javascripts/ai/constants.js or
// conditionally add to the capabilities in passed to buildStartRequest in
// ee/app/assets/javascripts/ai/duo_agentic_chat/components/duo_agentic_chat.vue.
var ClientCapabilities = []capability{
	capabilityIncrementalStreaming,
	capabilityShellCommand,
	capabilityReadFileChunked,
	capabilityCommandTimeout,
	capabilityWebSearch,
}

// ServerCapabilities defines the list of allowed server capabilities that
// can be communicated to Duo Workflow Service. This allowlist ensures only
// explicitly approved capabilities are sent.
//
// To add a new server capability:
// 1. Add a constant above (e.g., capabilityNewFeature capability = "new_feature")
// 2. Add it to this ServerCapabilities list
// 3. Update compute_server_capabilities in ee/lib/api/ai/duo_workflows/workflows.rb
var ServerCapabilities = []capability{
	capabilityAdvancedSearch,
	capabilityToolCallApproval,
	capabilityToolCallPatternApproval,
	capabilityJobTracePagination,
	capabilityIncrementalCheckpoints,
}

// intersectClientCapabilities returns the intersection of what gitlab-lsp passed in and what workhorse
// supports.
func intersectClientCapabilities(fromClient []string) []string {
	result := []string{}

	for _, cap := range ClientCapabilities {
		if slices.Contains(fromClient, string(cap)) {
			result = append(result, string(cap))
		}
	}

	return result
}

// intersectServerCapabilities returns the intersection of what is passed from server and what workhorse
// supports.
func intersectServerCapabilities(fromServer []string) []string {
	result := []string{}

	for _, cap := range ServerCapabilities {
		if slices.Contains(fromServer, string(cap)) {
			result = append(result, string(cap))
		}
	}

	return result
}

// wsManager owns the WebSocket connection and all state needed to read from and
// write to it. It mirrors the role of streamManager for the gRPC side.
type wsManager struct {
	conn   websocketConn
	closed atomic.Bool
	buf    []byte
}

func newWsManager(conn websocketConn) *wsManager {
	return &wsManager{
		conn: conn,
		buf:  make([]byte, ActionResponseBodyLimit),
	}
}

// SetPongHandler registers the pong callback on the underlying connection.
// The callback resets the read deadline so a missing pong eventually causes
// ReadClientEvent to time out and terminate the read loop.
func (w *wsManager) SetPongHandler(h func(string) error) {
	w.conn.SetPongHandler(h)
}

// SetReadDeadline sets the read deadline on the underlying connection.
func (w *wsManager) SetReadDeadline(t time.Time) error {
	return w.conn.SetReadDeadline(t)
}

// Ping sends a single WebSocket ping control frame. It marks the connection as
// closed if the write fails so that subsequent WriteAction calls are skipped.
func (w *wsManager) Ping() error {
	if err := w.conn.WriteControl(websocket.PingMessage, nil, time.Now().Add(wsWriteDeadline)); err != nil {
		w.closed.Store(true)
		return err
	}
	return nil
}

// ReadClientEvent reads the next raw WebSocket message and unmarshals it into a
// ClientEvent.
func (w *wsManager) ReadClientEvent() (*pb.ClientEvent, error) {
	_, message, err := w.conn.ReadMessage()
	if err != nil {
		w.closed.Store(true)
		return nil, err
	}

	event := &pb.ClientEvent{}
	if err := unmarshaler.Unmarshal(message, event); err != nil {
		return nil, fmt.Errorf("ReadClientEvent: failed to unmarshal WS message: %v", err)
	}

	return event, nil
}

// WriteAction marshals a proto Action and writes it to the WebSocket connection.
// It is a no-op when the connection is already closed. It handles ErrCloseSent
// silently since that indicates the connection is already closing normally.
func (w *wsManager) WriteAction(ctx context.Context, action *pb.Action) error {
	if w.closed.Load() {
		log.WithContextFields(ctx, log.Fields{}).Info("WriteAction: skipping sending WS message because websocket already closed")
		return nil
	}

	var err error
	w.buf, err = marshaler.MarshalAppend(w.buf[:0], action)
	if err != nil {
		return fmt.Errorf("WriteAction: failed to marshal action: %v", err)
	}

	deadline := time.Now().Add(wsWriteDeadline)
	if deadlineErr := w.conn.SetWriteDeadline(deadline); deadlineErr != nil {
		return fmt.Errorf("WriteAction: failed to set write deadline: %v", deadlineErr)
	}

	if err = w.conn.WriteMessage(websocket.BinaryMessage, w.buf); err != nil {
		if err == websocket.ErrCloseSent {
			log.WithContextFields(ctx, log.Fields{}).Info("WriteAction: websocket already closed, skipping write")
			return nil
		}
		return fmt.Errorf("WriteAction: failed to send WS message: %v", err)
	}

	// Clear the write deadline after a successful write so it does not affect
	// subsequent operations (including reads on the same net.Conn).
	if deadlineErr := w.conn.SetWriteDeadline(time.Time{}); deadlineErr != nil {
		return fmt.Errorf("WriteAction: failed to clear write deadline: %v", deadlineErr)
	}

	return nil
}

// ReadError classifies a WebSocket read error into a reason string suitable for
// a StopWorkflowRequest, or returns ("", err) for unexpected errors that should
// be propagated directly.
func (w *wsManager) ReadError(err error) (reason string, ok bool) {
	if e, ok := err.(*websocket.CloseError); ok && slices.Contains(normalClosureErrCodes, e.Code) {
		return fmt.Sprintf("WORKHORSE_WEBSOCKET_CLOSE_%d", e.Code), true
	}

	var netErr net.Error
	if errors.As(err, &netErr) && netErr.Timeout() {
		return "WORKHORSE_WEBSOCKET_PONG_TIMEOUT", true
	}

	return "", false
}

// SendGoingAway sends a CloseGoingAway (1001) frame to signal the client to
// reconnect, and marks the connection as closed on success.
func (w *wsManager) SendGoingAway() error {
	deadline := time.Now().Add(wsCloseTimeout)
	closeMsg := websocket.FormatCloseMessage(websocket.CloseGoingAway, "server shutdown")
	if err := w.conn.WriteControl(websocket.CloseMessage, closeMsg, deadline); err != nil {
		return err
	}
	w.closed.Store(true)
	return nil
}

// closeInvalidRequest is a private-use WebSocket close code (RFC 6455 §7.4.2
// reserves 4000–4999 for private use). It maps to HTTP 400 Bad Request
// semantics: the client sent invalid input (e.g. an empty goal on resume) and
// must not retry with the same request.
const closeInvalidRequest = 4400

// wsCloseMaxReasonBytes is the maximum byte length of a WebSocket close frame
// reason string. RFC 6455 limits control frame payloads to 125 bytes; the
// first 2 bytes are the status code, leaving 123 bytes for the reason text.
const wsCloseMaxReasonBytes = 123

// truncateCloseReason truncates s to at most wsCloseMaxReasonBytes bytes,
// cutting on a valid UTF-8 rune boundary so the resulting string is valid.
// It uses utf8.ValidString to confirm the result rather than hand-rolling
// byte-pattern logic.
func truncateCloseReason(s string) string {
	if len(s) <= wsCloseMaxReasonBytes {
		return s
	}
	t := s[:wsCloseMaxReasonBytes]
	// Walk back one byte at a time until the truncated string is valid UTF-8.
	// In the worst case (all 4-byte runes) we walk back at most 3 bytes.
	for len(t) > 0 && !utf8.ValidString(t) {
		t = t[:len(t)-1]
	}
	return t
}

// SendInvalidRequest sends a close frame with code 4400 (private-use, Bad
// Request) to signal that the server rejected the reconnect because the
// request was invalid (e.g. an empty goal sent to a workflow paused waiting
// for user input). The reason string is forwarded from the DWS gRPC status
// message so the client sees the exact cause rather than a hardcoded string.
// The connection is marked as closed on success. WebSocket control frames cap
// the payload at 125 bytes, so the close reason must be at most 123 bytes after
// the 2-byte status code. FormatCloseMessage does NOT truncate, and WriteControl
// rejects an oversized frame ("websocket: invalid control frame"), which would
// silently drop the 4400 close and make the client fall back to 1000. Truncate
// defensively on a UTF-8 boundary to guarantee the frame is sent.
func (w *wsManager) SendInvalidRequest(reason string) error {
	deadline := time.Now().Add(wsCloseTimeout)
	reason = truncateCloseReason(reason)
	closeMsg := websocket.FormatCloseMessage(closeInvalidRequest, reason)
	if err := w.conn.WriteControl(websocket.CloseMessage, closeMsg, deadline); err != nil {
		return err
	}
	w.closed.Store(true)
	return nil
}

// Close sends CloseNormalClosure (1000) and closes the underlying connection.
// It is a no-op if the connection is already marked closed.
func (w *wsManager) Close() error {
	if w.closed.Load() {
		return nil
	}

	deadline := time.Now().Add(wsCloseTimeout)
	if err := w.conn.WriteControl(websocket.CloseMessage, websocket.FormatCloseMessage(websocket.CloseNormalClosure, ""), deadline); err != nil {
		closeErr := w.conn.Close()
		if closeErr != nil {
			return fmt.Errorf("failed to send close message and failed to close connection: %w", closeErr)
		}
		return fmt.Errorf("failed to send close message: %w", err)
	}

	if err := w.conn.SetReadDeadline(deadline); err != nil {
		closeErr := w.conn.Close()
		if closeErr != nil {
			return fmt.Errorf("failed to set read deadline and failed to close connection: %w", closeErr)
		}
		return fmt.Errorf("failed to set read deadline: %w", err)
	}

	if err := w.conn.Close(); err != nil {
		return fmt.Errorf("failed to close connection: %w", err)
	}

	return nil
}
