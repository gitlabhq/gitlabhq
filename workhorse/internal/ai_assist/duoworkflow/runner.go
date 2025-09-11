package duoworkflow

import (
	"context"
	"errors"
	"fmt"
	"io"
	"net/http"
	"sync"

	pb "gitlab.com/gitlab-org/modelops/applied-ml/code-suggestions/ai-assist/clients/gopb/contract"

	"gitlab.com/gitlab-org/gitlab/workhorse/internal/api"
	"gitlab.com/gitlab-org/gitlab/workhorse/internal/log"

	"github.com/gorilla/websocket"
	"google.golang.org/protobuf/encoding/protojson"
	"google.golang.org/protobuf/proto"
)

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
}

type workflowStream interface {
	Send(*pb.ClientEvent) error
	Recv() (*pb.Action, error)
	CloseSend() error
}

type runner struct {
	rails       *api.API
	token       string
	originalReq *http.Request
	conn        websocketConn
	wf          workflowStream
	client      *Client
	sendMu      sync.Mutex
}

func newRunner(conn websocketConn, rails *api.API, r *http.Request, cfg *api.DuoWorkflow) (*runner, error) {
	client, err := NewClient(cfg.ServiceURI, cfg.Headers, cfg.Secure)
	if err != nil {
		return nil, fmt.Errorf("failed to initialize client: %v", err)
	}

	wf, err := client.ExecuteWorkflow(r.Context())
	if err != nil {
		return nil, fmt.Errorf("failed to initialize stream: %v", err)
	}

	return &runner{
		rails:       rails,
		token:       cfg.Headers["x-gitlab-oauth-token"],
		originalReq: r,
		conn:        conn,
		wf:          wf,
		client:      client,
	}, nil
}

func (r *runner) Execute(ctx context.Context) error {
	errCh := make(chan error, 2)

	go func() {
		for {
			if err := r.handleWebSocketMessage(); err != nil {
				errCh <- err
				return
			}
		}
	}()

	go func() {
		for {
			action, err := r.wf.Recv()
			if err != nil {
				if err == io.EOF {
					errCh <- nil // Expected error when a workflow ends
				} else {
					errCh <- fmt.Errorf("duoworkflow: failed to read a gRPC message: %v", err)
				}
				return
			}

			if err := r.handleAgentAction(ctx, action); err != nil {
				errCh <- err
				return
			}
		}
	}()

	return <-errCh
}

func (r *runner) Close() error {
	r.sendMu.Lock()
	defer r.sendMu.Unlock()

	return errors.Join(r.wf.CloseSend(), r.client.Close())
}

func (r *runner) handleWebSocketMessage() error {
	_, message, err := r.conn.ReadMessage()
	if err != nil {
		return fmt.Errorf("handleWebSocketMessage: failed to read a WS message: %v", err)
	}

	response := &pb.ClientEvent{}
	if err = unmarshaler.Unmarshal(message, response); err != nil {
		return fmt.Errorf("handleWebSocketMessage: failed to unmarshal a WS message: %v", err)
	}

	if err = r.threadSafeSend(response); err != nil {
		if err == io.EOF {
			// ignore EOF to let Recv() fail and return a meaningful message
			return nil
		}

		return fmt.Errorf("handleWebSocketMessage: failed to write a gRPC message: %v", err)
	}

	return nil
}

func (r *runner) handleAgentAction(ctx context.Context, action *pb.Action) error {
	switch action.Action.(type) {
	case *pb.Action_RunHTTPRequest:
		handler := &runHTTPActionHandler{
			rails:       r.rails,
			token:       r.token,
			originalReq: r.originalReq,
			action:      action,
		}

		event, err := handler.Execute(ctx)
		if err != nil {
			return fmt.Errorf("handleAgentAction: failed to perform API call: %v", err)
		}

		statusCode := event.GetActionResponse().GetHttpResponse().StatusCode
		log.WithContextFields(r.originalReq.Context(), log.Fields{
			"path":                 action.GetRunHTTPRequest().Path,
			"status_code":          statusCode,
			"payload_size":         proto.Size(event),
			"event_type":           fmt.Sprintf("%T", event.Response),
			"action_response_type": fmt.Sprintf("%T", event.GetActionResponse().GetResponseType()),
		}).Info("Sending HTTP response event")
		if err := r.threadSafeSend(event); err != nil {
			return fmt.Errorf("handleAgentAction: failed to send gRPC message: %v", err)
		}
		log.WithContextFields(r.originalReq.Context(), log.Fields{
			"path": action.GetRunHTTPRequest().Path,
		}).Info("Successfully sent HTTP response event")

	default:
		message, err := marshaler.Marshal(action)
		if err != nil {
			return fmt.Errorf("handleAgentAction: failed to unmarshal action: %v", err)
		}

		if err = r.conn.WriteMessage(websocket.BinaryMessage, message); err != nil {
			return fmt.Errorf("handleAgentAction: failed to send WS message: %v", err)
		}
	}

	return nil
}

func (r *runner) threadSafeSend(event *pb.ClientEvent) error {
	r.sendMu.Lock()
	defer r.sendMu.Unlock()
	return r.wf.Send(event)
}
