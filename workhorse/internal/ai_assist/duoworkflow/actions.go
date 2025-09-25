package duoworkflow

import (
	"bytes"
	"context"
	"fmt"
	"io"
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
	token       string
	originalReq *http.Request
	action      *pb.Action
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

	response, err := a.rails.Client.Do(req)
	if err != nil {
		return nil, err
	}
	defer func() { _ = response.Body.Close() }()

	body, err := io.ReadAll(io.LimitReader(response.Body, ActionResponseBodyLimit))
	if err != nil {
		return nil, err
	}

	clientEvent := &pb.ClientEvent{
		Response: &pb.ClientEvent_ActionResponse{
			ActionResponse: &pb.ActionResponse{
				RequestID: a.action.RequestID,
				ResponseType: &pb.ActionResponse_HttpResponse{
					HttpResponse: &pb.HttpResponse{
						Body:       string(body),
						StatusCode: int32(response.StatusCode),
					},
				},
			},
		},
	}

	return clientEvent, nil
}
