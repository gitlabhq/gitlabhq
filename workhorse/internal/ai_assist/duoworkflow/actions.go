package duoworkflow

import (
	"bytes"
	"context"
	"errors"
	"fmt"
	"io"
	"net"
	"net/http"
	"strconv"
	"strings"
	"time"

	"gitlab.com/gitlab-org/gitlab/workhorse/internal/log"
	"gitlab.com/gitlab-org/gitlab/workhorse/internal/secret"
	"gitlab.com/gitlab-org/gitlab/workhorse/internal/version"

	pb "gitlab.com/gitlab-org/modelops/applied-ml/code-suggestions/ai-assist/clients/gopb/contract"

	"google.golang.org/protobuf/proto"
)

var (
	errResponseBodySizeLimitExceeded = errors.New("response body exceeded size limit")
	errRequestAborted                = errors.New("request aborted")
	errRequestTimedOut               = errors.New("request timed out")
)

const (
	httpActionErrorTypeTimeout      = "timeout"
	httpActionErrorTypeAborted      = "aborted"
	httpActionErrorTypeSizeExceeded = "size_limit_exceeded"
	httpActionErrorTypeOther        = "other"
)

// ActionResponseBodyLimit is the maximum size of response body that can be received.
// It's calculated from the MaxMessageSize the maximum size of messages that can be sent or received (4MB).
// With some extra space to wrap the body into a gRPC message.
const ActionResponseBodyLimit = MaxMessageSize - 4096

const httpRequestTimeout = 5 * time.Second

type runHTTPActionHandler struct {
	backend                   http.Handler
	token                     string
	originalReq               *http.Request
	shouldTimeoutHTTPRequests bool
	// relativeURLRoot is GitLab's URL prefix (e.g. "/gitlab/"), empty at the
	// domain root. DWS sends unprefixed action paths, so it must be prepended
	// before re-entering the upstream router.
	relativeURLRoot string
	// workflowID is set by the runner after StartWorkflowRequest is received
	// and is forwarded as the X-Gitlab-Duo-Workflow-Id header so the GitLab
	// API can correlate tool-originated traffic with the originating workflow.
	workflowID string
}

// applyRelativeURLRoot prepends the relative URL root to a DWS action path so
// it matches the upstream router's URL prefix. It is a no-op when the root is
// empty or the path already carries it.
func (a *runHTTPActionHandler) applyRelativeURLRoot(path string) string {
	root := strings.TrimSuffix(a.relativeURLRoot, "/")
	if root == "" {
		return path
	}

	if path == root || strings.HasPrefix(path, root+"/") {
		return path
	}

	return root + path
}

type nullResponseWriter struct {
	header       http.Header
	status       int
	body         bytes.Buffer
	logger       *log.Builder
	sizeLimitHit bool
}

func (w *nullResponseWriter) Write(p []byte) (int, error) {
	available := ActionResponseBodyLimit - w.body.Len()
	if available <= 0 {
		w.sizeLimitHit = true
		w.logger.WithFields(log.Fields{
			"current_size":    w.body.Len(),
			"limit":           ActionResponseBodyLimit,
			"attempted_write": len(p),
		}).Error("nullResponseWriter: response body limit exceeded, dropping data")
		return 0, io.ErrShortWrite
	}

	if len(p) > available {
		w.sizeLimitHit = true
		// Write only what fits within the limit
		w.logger.WithFields(log.Fields{
			"requested_bytes": len(p),
			"available_bytes": available,
			"total_written":   w.body.Len(),
			"limit":           ActionResponseBodyLimit,
		}).Error("nullResponseWriter: partial write due to size limit")
		n, _ := w.body.Write(p[:available])
		return n, io.ErrShortWrite
	}

	return w.body.Write(p)
}

func (w *nullResponseWriter) Header() http.Header {
	return w.header
}

func (w *nullResponseWriter) WriteHeader(status int) {
	if w.status == 0 {
		w.status = status
	}
}

// serveHTTPSafe calls h.ServeHTTP and recovers from http.ErrAbortHandler panics.
// httputil.ReverseProxy panics with http.ErrAbortHandler when the client disconnects
// or the request context is canceled. This is normally caught by net/http's own
// recovery in connection goroutines, but Execute is called from an agent goroutine
// that is outside of that managed context, so we must recover here explicitly.
func serveHTTPSafe(h http.Handler, w http.ResponseWriter, r *http.Request) (err error) {
	defer func() {
		if p := recover(); p != nil {
			if p == http.ErrAbortHandler {
				if nrw, ok := w.(*nullResponseWriter); ok && nrw.sizeLimitHit {
					err = fmt.Errorf("%w (%d bytes)", errResponseBodySizeLimitExceeded, ActionResponseBodyLimit)
				} else if ctxErr := r.Context().Err(); ctxErr != nil {
					err = fmt.Errorf("%w: %w", errRequestAborted, ctxErr)
				} else {
					err = errRequestAborted
				}
			} else {
				panic(p)
			}
		}
	}()
	h.ServeHTTP(w, r)
	return nil
}

func (a *runHTTPActionHandler) Execute(ctx context.Context, action *pb.Action) (*pb.ClientEvent, error) {
	req, err := a.buildRequest(ctx, action)
	if err != nil {
		return nil, err
	}

	method := action.GetRunHTTPRequest().Method

	logger := log.WithContextFields(a.originalReq.Context(), log.Fields{
		"path":       action.GetRunHTTPRequest().Path,
		"method":     method,
		"request_id": action.GetRequestID(),
	})

	logger.Info("Executing HTTP request")

	if a.shouldTimeoutHTTPRequests {
		timeoutCtx, cancel := context.WithTimeout(req.Context(), httpRequestTimeout)
		defer cancel()
		req = req.WithContext(timeoutCtx)
	}

	start := time.Now()
	nrw := &nullResponseWriter{header: make(http.Header), logger: logger}
	err = serveHTTPSafe(a.backend, nrw, req)

	// check if there is context deadline because the roundtripper converts such errors
	// to a 502 status bad gateway. We want to provide a more descriptive error to DWS.
	if a.shouldTimeoutHTTPRequests && errors.Is(req.Context().Err(), context.DeadlineExceeded) {
		err = errRequestTimedOut
	}

	httpActionDurationSeconds.WithLabelValues(method).Observe(time.Since(start).Seconds())

	if err != nil {
		httpActionErrorsTotal.WithLabelValues(httpActionErrorType(err)).Inc()
		httpActionsTotal.WithLabelValues(method, "0").Inc()
	} else {
		httpActionsTotal.WithLabelValues(method, strconv.Itoa(nrw.status)).Inc()
	}

	clientEvent := a.buildClientEvent(nrw, err, action)

	logger.WithFields(log.Fields{
		"status_code":          nrw.status,
		"error":                clientEvent.GetActionResponse().GetHttpResponse().Error,
		"payload_size":         proto.Size(clientEvent),
		"event_type":           fmt.Sprintf("%T", clientEvent.Response),
		"action_response_type": fmt.Sprintf("%T", clientEvent.GetActionResponse().GetResponseType()),
	}).Info("Sending HTTP response event")

	return clientEvent, nil
}

// httpActionErrorType maps a transport-level error to a label value for
// httpActionErrorsTotal.
func httpActionErrorType(err error) string {
	switch {
	case errors.Is(err, errRequestTimedOut):
		return httpActionErrorTypeTimeout
	case errors.Is(err, errRequestAborted):
		return httpActionErrorTypeAborted
	case errors.Is(err, errResponseBodySizeLimitExceeded):
		return httpActionErrorTypeSizeExceeded
	default:
		return httpActionErrorTypeOther
	}
}

func (a *runHTTPActionHandler) buildClientEvent(nrw *nullResponseWriter, err error, action *pb.Action) *pb.ClientEvent {
	headers := make(map[string]string, len(nrw.Header()))
	for k, v := range nrw.Header() {
		headers[k] = strings.Join(v, ", ")
	}

	ce := &pb.ClientEvent{
		Response: &pb.ClientEvent_ActionResponse{
			ActionResponse: &pb.ActionResponse{
				RequestID: action.RequestID,
				ResponseType: &pb.ActionResponse_HttpResponse{
					HttpResponse: &pb.HttpResponse{
						Body:       nrw.body.String(),
						StatusCode: int32(nrw.status), //nolint:gosec
						Headers:    headers,
					},
				},
			},
		},
	}

	if err != nil {
		ce.GetActionResponse().GetHttpResponse().Error = err.Error()
	}

	return ce
}

func (a *runHTTPActionHandler) buildRequest(ctx context.Context, action *pb.Action) (*http.Request, error) {
	actionRequest := action.GetRunHTTPRequest()

	var bodyBuffer bytes.Buffer
	if actionRequest.Body != nil {
		bodyBuffer.WriteString(*actionRequest.Body)
	}

	// #nosec G704 -- The request is dispatched in-process to the upstream
	// GitLab router (serveHTTPSafe), not sent to an attacker-chosen network
	// host, so the DWS-supplied path cannot cause SSRF.
	req, err := http.NewRequestWithContext(ctx, actionRequest.Method, a.applyRelativeURLRoot(actionRequest.Path), &bodyBuffer)
	if err != nil {
		return nil, err
	}
	req.Header.Set("Authorization", fmt.Sprintf("Bearer %v", a.token))
	req.Header.Set("Content-Type", "application/json")
	req.Header.Set("User-Agent", "Agent-Flow-via-GitLab-Workhorse")

	tokenString, err := secret.JWTTokenString(secret.DefaultClaims)
	if err != nil {
		return nil, fmt.Errorf("buildRequest: failed to generate JWT token: %w", err)
	}
	req.Header.Set("Gitlab-Workhorse", version.GetApplicationVersion())
	req.Header.Set(secret.RequestHeader, tokenString)

	if a.workflowID != "" {
		req.Header.Set("X-Gitlab-Duo-Workflow-Id", a.workflowID)
	}

	if clientIP, _, splitHostErr := net.SplitHostPort(a.originalReq.RemoteAddr); splitHostErr == nil {
		// If we aren't the first proxy retain prior X-Forwarded-For information as a comma+space separated list and fold multiple headers into one.
		var header string
		if prior, ok := a.originalReq.Header["X-Forwarded-For"]; ok {
			header = strings.Join(prior, ", ") + ", " + clientIP
		} else {
			header = clientIP
		}
		req.Header.Set("X-Forwarded-For", header)
	}

	return req, nil
}
