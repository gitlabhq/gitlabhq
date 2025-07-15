package duoworkflow

import (
	"context"
	"fmt"
	"io"
	"net/http"

	pb "gitlab.com/gitlab-org/modelops/applied-ml/code-suggestions/ai-assist/clients/gopb/contract"

	"gitlab.com/gitlab-org/gitlab/workhorse/internal/api"

	"github.com/gorilla/websocket"
	"google.golang.org/protobuf/encoding/protojson"
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
}

type runner struct {
	rails       *api.API
	token       string
	originalReq *http.Request
	conn        websocketConn
	wf          workflowStream
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

func (r *runner) handleWebSocketMessage() error {
	_, message, err := r.conn.ReadMessage()
	if err != nil {
		return fmt.Errorf("handleWebSocketMessage: failed to read a WS message: %v", err)
	}

	response := &pb.ClientEvent{}
	if err = unmarshaler.Unmarshal(message, response); err != nil {
		return fmt.Errorf("handleWebSocketMessage: failed to unmarshal a WS message: %v", err)
	}

	if err = r.wf.Send(response); err != nil {
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

		if err := r.wf.Send(event); err != nil {
			return fmt.Errorf("handleAgentAction: failed to send gRPC message: %v", err)
		}
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
