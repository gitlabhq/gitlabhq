package duoworkflow

import (
	"context"
	"errors"
	"fmt"
	"io"
	"net/http"
	"slices"
	"sync"
	"time"

	pb "gitlab.com/gitlab-org/modelops/applied-ml/code-suggestions/ai-assist/clients/gopb/contract"

	"gitlab.com/gitlab-org/gitlab/workhorse/internal/api"
	"gitlab.com/gitlab-org/gitlab/workhorse/internal/log"

	"github.com/gorilla/websocket"
	"google.golang.org/protobuf/encoding/protojson"
	"google.golang.org/protobuf/proto"
)

const wsCloseTimeout = 5 * time.Second
const wsStopWorkflowTimeout = 10 * time.Second

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
	Close() error
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
	marshalBuf  []byte
	conn        websocketConn
	wf          workflowStream
	client      *Client
	sendMu      sync.Mutex
	mcpManager  mcpManager
}

func newRunner(conn websocketConn, rails *api.API, r *http.Request, cfg *api.DuoWorkflow) (*runner, error) {
	userAgent := r.Header.Get("User-Agent")

	client, err := NewClient(cfg.ServiceURI, cfg.Headers, cfg.Secure, userAgent)
	if err != nil {
		return nil, fmt.Errorf("failed to initialize client: %v", err)
	}

	wf, err := client.ExecuteWorkflow(r.Context())
	if err != nil {
		return nil, fmt.Errorf("failed to initialize stream: %v", err)
	}

	mcpManager, err := newMcpManager(rails, r, cfg.McpServers)
	if err != nil {
		// Log the error while the feature is in development
		log.WithRequest(r).WithError(err).Info("failed to initialize MCP server(s)")
	}

	return &runner{
		rails:       rails,
		token:       cfg.Headers["x-gitlab-oauth-token"],
		originalReq: r,
		marshalBuf:  make([]byte, ActionResponseBodyLimit),
		conn:        conn,
		wf:          wf,
		client:      client,
		mcpManager:  mcpManager,
	}, nil
}

func (r *runner) Execute(ctx context.Context) error {
	errCh := make(chan error, 2)

	go r.handleWebSocketMessages(ctx, errCh)
	go r.handleAgentMessages(ctx, errCh)

	return <-errCh
}

func (r *runner) handleWebSocketMessages(ctx context.Context, errCh chan<- error) {
	for {
		_, message, err := r.conn.ReadMessage()
		if err != nil {
			if e, ok := err.(*websocket.CloseError); ok && slices.Contains(normalClosureErrCodes, e.Code) {
				log.WithRequest(r.originalReq).WithFields(log.Fields{
					"close_error": err.Error(),
				}).Info("handleWebSocketMessages: Sending stop workflow request...")

				stopRequest := &pb.ClientEvent{
					Response: &pb.ClientEvent_StopWorkflow{
						StopWorkflow: &pb.StopWorkflowRequest{
							Reason: fmt.Sprintf("WORKHORSE_WEBSOCKET_CLOSE_%d", e.Code),
						},
					},
				}

				if err = r.threadSafeSend(stopRequest); err != nil {
					errCh <- fmt.Errorf("handleWebSocketMessages: failed to gracefully stop a workflow: %v", err)
				}

				select {
				case <-ctx.Done():
					errCh <- nil
					return
				case <-time.After(wsStopWorkflowTimeout):
					errCh <- fmt.Errorf("handleWebSocketMessages: workflow didn't stop on time")
					return
				}
			}

			errCh <- fmt.Errorf("handleWebSocketMessages: failed to read a WS message: %v", err)
			return
		}

		if err := r.handleWebSocketMessage(message); err != nil {
			errCh <- err
			return
		}
	}
}

func (r *runner) handleAgentMessages(ctx context.Context, errCh chan<- error) {
	for {
		action, err := r.wf.Recv()
		if err != nil {
			if err == io.EOF {
				errCh <- nil // Expected error when a workflow ends
			} else {
				errCh <- fmt.Errorf("handleAgentMessages: failed to read a gRPC message: %v", err)
			}
			return
		}

		if err := r.handleAgentAction(ctx, action); err != nil {
			errCh <- err
			return
		}
	}
}

func (r *runner) Close() error {
	r.sendMu.Lock()
	defer r.sendMu.Unlock()

	return errors.Join(r.wf.CloseSend(), r.client.Close(), r.closeWebSocketConnection(), r.mcpManager.Close())
}

func (r *runner) closeWebSocketConnection() error {
	deadline := time.Now().Add(wsCloseTimeout)
	if err := r.conn.WriteControl(websocket.CloseMessage, websocket.FormatCloseMessage(websocket.CloseNormalClosure, ""), deadline); err != nil {
		// If we can't send the close message, just close the connection
		closeErr := r.conn.Close()
		if closeErr != nil {
			return fmt.Errorf("failed to send close message and failed to close connection: %w", closeErr)
		}
		return fmt.Errorf("failed to send close message: %w", err)
	}

	if err := r.conn.SetReadDeadline(deadline); err != nil {
		closeErr := r.conn.Close()
		if closeErr != nil {
			return fmt.Errorf("failed to set read deadline and failed to close connection: %w", closeErr)
		}
		return fmt.Errorf("failed to set read deadline: %w", err)
	}

	if err := r.conn.Close(); err != nil {
		return fmt.Errorf("failed to close connection: %w", err)
	}

	return nil
}

func (r *runner) handleWebSocketMessage(message []byte) error {
	response := &pb.ClientEvent{}
	if err := unmarshaler.Unmarshal(message, response); err != nil {
		return fmt.Errorf("handleWebSocketMessage: failed to unmarshal a WS message: %v", err)
	}

	if startReq := response.GetStartRequest(); startReq != nil {
		startReq.McpTools = append(startReq.McpTools, r.mcpManager.Tools()...)
	}

	log.WithContextFields(r.originalReq.Context(), log.Fields{
		"payload_size": proto.Size(response),
		"event_type":   fmt.Sprintf("%T", response.Response),
		"request_id":   response.GetActionResponse().GetRequestID(),
	}).Info("Sending action response")

	if err := r.threadSafeSend(response); err != nil {
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
			"method":               action.GetRunHTTPRequest().Method,
			"status_code":          statusCode,
			"payload_size":         proto.Size(event),
			"event_type":           fmt.Sprintf("%T", event.Response),
			"action_response_type": fmt.Sprintf("%T", event.GetActionResponse().GetResponseType()),
			"request_id":           action.GetRequestID(),
		}).Info("Sending HTTP response event")

		if err := r.threadSafeSend(event); err != nil {
			return fmt.Errorf("handleAgentAction: failed to send gRPC message: %v", err)
		}

		log.WithContextFields(r.originalReq.Context(), log.Fields{
			"path": action.GetRunHTTPRequest().Path,
		}).Info("Successfully sent HTTP response event")
	case *pb.Action_RunMCPTool:
		mcpTool := action.GetRunMCPTool()

		// If a tool is not recongnized, propagate the message to the client
		// It's possible when a user has local MCP servers configured in IDE
		if !r.mcpManager.HasTool(mcpTool.Name) {
			return r.sendActionToWs(action)
		}
		event, err := r.mcpManager.CallTool(ctx, action)
		if err != nil {
			return fmt.Errorf("handleAgentAction: failed to call MCP tool: %v", err)
		}

		log.WithContextFields(ctx, log.Fields{
			"request_id":           action.GetRequestID(),
			"name":                 mcpTool.Name,
			"args_size":            len(mcpTool.Args),
			"payload_size":         proto.Size(event),
			"event_type":           fmt.Sprintf("%T", event.Response),
			"action_response_type": fmt.Sprintf("%T", event.GetActionResponse().GetResponseType()),
		}).Info("Sending MCP tool response")

		if err := r.threadSafeSend(event); err != nil {
			return fmt.Errorf("handleAgentAction: failed to send gRPC message: %v", err)
		}
	default:
		return r.sendActionToWs(action)
	}

	return nil
}

func (r *runner) sendActionToWs(action *pb.Action) error {
	var err error
	r.marshalBuf, err = marshaler.MarshalAppend(r.marshalBuf[:0], action)
	if err != nil {
		return fmt.Errorf("sendActionToWs: failed to unmarshal action: %v", err)
	}

	if err = r.conn.WriteMessage(websocket.BinaryMessage, r.marshalBuf); err != nil {
		if err != websocket.ErrCloseSent {
			return fmt.Errorf("sendActionToWs: failed to send WS message: %v", err)
		}
	}

	return nil
}

func (r *runner) threadSafeSend(event *pb.ClientEvent) error {
	r.sendMu.Lock()
	defer r.sendMu.Unlock()
	return r.wf.Send(event)
}
