package duoworkflow

import (
	"bytes"
	"context"
	"fmt"
	"net"
	"net/http"
	"net/url"
	"strings"

	pb "gitlab.com/gitlab-org/modelops/applied-ml/code-suggestions/ai-assist/clients/gopb/contract"

	"gitlab.com/gitlab-org/gitlab/workhorse/internal/api"
)

// ActionResponseBodyLimit is the maximum size of response body that can be received.
// It's calculated from the MaxMessageSize the maximum size of messages that can be sent or received (4MB).
// With some extra space to wrap the body into a gRPC message.
const ActionResponseBodyLimit = MaxMessageSize - 4096

type runHTTPActionHandler struct {
	rails       *api.API
	backend     http.Handler
	token       string
	originalReq *http.Request
	action      *pb.Action
}

type nullResponseWriter struct {
	header http.Header
	status int
	body   bytes.Buffer
}

func (w *nullResponseWriter) Write(p []byte) (int, error) {
	available := ActionResponseBodyLimit - w.body.Len()
	if available <= 0 {
		return 0, nil
	}

	if len(p) > available {
		// Write only what fits within the limit
		n, _ := w.body.Write(p[:available])
		return n, nil
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

func (a *runHTTPActionHandler) Execute(ctx context.Context) (*pb.ClientEvent, error) {
	action := a.action.GetRunHTTPRequest()

	var bodyBuffer bytes.Buffer
	if action.Body != nil {
		bodyBuffer.WriteString(*action.Body)
	}

	actionURL, err := url.Parse(action.Path)
	if err != nil {
		return nil, err
	}

	reqURL := a.rails.URL.ResolveReference(actionURL).String()
	req, err := http.NewRequestWithContext(ctx, action.Method, reqURL, &bodyBuffer)
	if err != nil {
		return nil, err
	}
	req.Header.Set("Authorization", fmt.Sprintf("Bearer %v", a.token))
	req.Header.Set("Content-Type", "application/json")
	req.Header.Set("User-Agent", "Agent-Flow-via-GitLab-Workhorse")

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

	nrw := &nullResponseWriter{header: make(http.Header)}
	a.backend.ServeHTTP(nrw, req)

	clientEvent := &pb.ClientEvent{
		Response: &pb.ClientEvent_ActionResponse{
			ActionResponse: &pb.ActionResponse{
				RequestID: a.action.RequestID,
				ResponseType: &pb.ActionResponse_HttpResponse{
					HttpResponse: &pb.HttpResponse{
						Body:       nrw.body.String(),
						StatusCode: int32(nrw.status),
					},
				},
			},
		},
	}

	return clientEvent, nil
}
