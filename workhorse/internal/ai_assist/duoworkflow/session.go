package duoworkflow

import (
	"context"
	"net"
	"net/http"
	"strings"
	"sync"

	"gitlab.com/gitlab-org/gitlab/workhorse/internal/log"
)

// session is what every part of one workflow run shares: the request that
// started it, the context the run lives on, and the workflow it runs.
type session struct {
	req    *http.Request
	ctx    context.Context
	cancel context.CancelFunc

	// forwardedFor is the X-Forwarded-For value for requests made on behalf
	// of the client, computed once from the original request.
	forwardedFor string

	mu         sync.RWMutex
	workflowID string
}

// newSession derives the run's context from the request, so the run ends when
// the request does or when the session is closed.
func newSession(r *http.Request) *session {
	ctx, cancel := context.WithCancel(r.Context())

	return &session{
		req:          r,
		ctx:          ctx,
		cancel:       cancel,
		forwardedFor: forwardedFor(r),
	}
}

// Context returns the context the run lives on. It keeps the request's values,
// such as the correlation ID.
func (s *session) Context() context.Context {
	return s.ctx
}

// Close ends the run's context, stopping anything still running on it once
// the runner has closed its streams.
func (s *session) Close() {
	s.cancel()
}

// WorkflowID returns the workflow the session runs, or an empty string until
// the start request has been received.
func (s *session) WorkflowID() string {
	s.mu.RLock()
	defer s.mu.RUnlock()

	return s.workflowID
}

func (s *session) setWorkflowID(id string) {
	s.mu.Lock()
	defer s.mu.Unlock()

	s.workflowID = id
}

// logger returns a log builder carrying the request fields and, once known,
// the workflow ID.
func (s *session) logger() *log.Builder {
	b := log.WithRequest(s.req)
	if id := s.WorkflowID(); id != "" {
		b = b.WithFields(log.Fields{"workflow_id": id})
	}

	return b
}

// forwardedFor appends the client IP to the X-Forwarded-For chain of r,
// folding multiple headers into one. It is empty when RemoteAddr has no port.
func forwardedFor(r *http.Request) string {
	clientIP, _, err := net.SplitHostPort(r.RemoteAddr)
	if err != nil {
		return ""
	}

	if prior, ok := r.Header["X-Forwarded-For"]; ok {
		return strings.Join(prior, ", ") + ", " + clientIP
	}

	return clientIP
}
