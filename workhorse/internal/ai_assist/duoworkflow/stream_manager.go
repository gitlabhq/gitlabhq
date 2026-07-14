package duoworkflow

import (
	"context"
	"errors"
	"fmt"
	"io"
	"net/http"
	"strings"
	"sync"

	"gitlab.com/gitlab-org/gitlab/workhorse/internal/api"
	"gitlab.com/gitlab-org/gitlab/workhorse/internal/log"

	pb "gitlab.com/gitlab-org/modelops/applied-ml/code-suggestions/ai-assist/clients/gopb/contract"

	"google.golang.org/grpc/codes"
	"google.golang.org/grpc/status"
	"google.golang.org/protobuf/proto"
)

var errUsageQuotaExceededError = errors.New("usage quota exceeded")

// errStreamUnavailable is returned by Recv when DWS closes the gRPC stream
// with an Unavailable status code. This typically happens after DWS processes
// a StopWorkflowRequest and tears down the workflow.
var errStreamUnavailable = errors.New("stream unavailable")

// errInvalidRequest is returned by Recv when DWS closes the gRPC stream
// with an InvalidArgument status code. This happens when a client reconnects
// to a workflow that is paused at a stable boundary (INPUT_REQUIRED,
// PLAN_APPROVAL_REQUIRED, TOOL_CALL_APPROVAL_REQUIRED) with an empty goal.
// The server signals "your reconnect was rejected due to invalid input; the
// session is still paused".
var errInvalidRequest = errors.New("invalid request: workflow rejected the reconnect due to invalid input")

// invalidRequestError carries the DWS gRPC status message for an InvalidArgument
// rejection while still matching errInvalidRequest via errors.Is. This lets the
// caller both detect the case and forward the clean, human-readable status
// message to the WebSocket close frame, instead of the full wrapped error chain
// which would overflow the 125-byte control-frame limit and get dropped.
type invalidRequestError struct{ msg string }

func (e *invalidRequestError) Error() string { return e.msg }

func (e *invalidRequestError) Is(target error) bool { return target == errInvalidRequest }

type streamManager struct {
	wf                 workflowStream
	client             *Client
	cloudServiceClient *Client
	cloudServiceStream selfHostedWorkflowStream
	originalReq        *http.Request
	sendMu             sync.Mutex
}

func newStreamManager(r *http.Request, cfg *api.DuoWorkflow) (*streamManager, error) {
	userAgent := r.Header.Get("User-Agent")
	clientName := r.Header.Get("X-Gitlab-Client-Name")

	client, err := NewClient(cfg.Service, userAgent, clientName)
	if err != nil {
		return nil, fmt.Errorf("failed to initialize client: %v", err)
	}

	wf, err := client.ExecuteWorkflow(r.Context())
	if err != nil {
		closeErr := client.Close()
		return nil, fmt.Errorf("failed to initialize stream: %w", errors.Join(err, closeErr))
	}
	sessionsTotal.Inc()

	var cloudServiceClient *Client
	var cloudServiceStream selfHostedWorkflowStream

	if cfg.CloudServiceForSelfHosted != nil && cfg.CloudServiceForSelfHosted.URI != "" {
		cloudServiceClient, err = NewClient(cfg.CloudServiceForSelfHosted, userAgent, clientName)
		if err != nil {
			return nil, fmt.Errorf("failed to initialize cloud service client: %v", err)
		}

		cloudServiceStream, err = cloudServiceClient.TrackSelfHostedExecuteWorkflow(r.Context())
		if err != nil {
			_ = cloudServiceClient.Close()
			return nil, fmt.Errorf("failed to initialize cloud service stream: %w", err)
		}
	}

	return &streamManager{
		wf:                 wf,
		client:             client,
		cloudServiceClient: cloudServiceClient,
		cloudServiceStream: cloudServiceStream,
		originalReq:        r,
	}, nil
}

func (sm *streamManager) Send(event *pb.ClientEvent) error {
	sm.sendMu.Lock()
	defer sm.sendMu.Unlock()

	log.WithContextFields(sm.originalReq.Context(), log.Fields{
		"payload_size": proto.Size(event),
		"event_type":   fmt.Sprintf("%T", event.Response),
		"request_id":   event.GetActionResponse().GetRequestID(),
	}).Info("Sending action response")

	return sm.wf.Send(event)
}

func (sm *streamManager) Close() error {
	sm.sendMu.Lock()
	defer sm.sendMu.Unlock()

	var cloudServiceErrs error
	if sm.cloudServiceStream != nil {
		cloudServiceErrs = sm.cloudServiceStream.CloseSend()
	}
	if sm.cloudServiceClient != nil {
		cloudServiceErrs = errors.Join(cloudServiceErrs, sm.cloudServiceClient.Close())
	}

	return errors.Join(sm.wf.CloseSend(), sm.client.Close(), cloudServiceErrs)
}

// handleCloudServiceTracking sends tracking data to cloud service for self-hosted deployments
func (sm *streamManager) HandleCloudServiceTracking(ctx context.Context, action *pb.Action) error {
	if sm.cloudServiceStream == nil {
		return fmt.Errorf("cloud service stream not initialized")
	}

	trackAction := action.GetTrackLlmCallForSelfHosted()

	log.WithContextFields(ctx, log.Fields{
		"request_id":  action.GetRequestID(),
		"workflow_id": trackAction.WorkflowID,
	}).Info("Sending TrackLlmCallForSelfHosted to cloud service")

	clientEvent := &pb.TrackSelfHostedClientEvent{
		RequestID:            action.GetRequestID(),
		WorkflowID:           trackAction.WorkflowID,
		FeatureQualifiedName: trackAction.FeatureQualifiedName,
		FeatureAiCatalogItem: trackAction.FeatureAiCatalogItem,
	}

	if err := sm.cloudServiceStream.Send(clientEvent); err != nil {
		return fmt.Errorf("failed to send to cloud service: %v", err)
	}

	selfHostedAction, err := sm.cloudServiceStream.Recv()
	if err != nil {
		return fmt.Errorf("failed to receive from cloud service: %v", err)
	}

	log.WithContextFields(ctx, log.Fields{
		"request_id": selfHostedAction.GetRequestID(),
	}).Info("Received acknowledgment from cloud service")

	// Send empty event to acknowledge
	event := &pb.ClientEvent{
		Response: &pb.ClientEvent_ActionResponse{
			ActionResponse: &pb.ActionResponse{
				RequestID: action.GetRequestID(),
				ResponseType: &pb.ActionResponse_PlainTextResponse{
					PlainTextResponse: &pb.PlainTextResponse{},
				},
			},
		},
	}
	if err := sm.Send(event); err != nil {
		return fmt.Errorf("failed to send gRPC message: %v", err)
	}

	return nil
}

// isUsageQuotaExceededError checks if the error is a gRPC RESOURCE_EXHAUSTED error
// indicating that the consumer has exceeded their usage quota.
func (sm *streamManager) isUsageQuotaExceededError(err error) bool {
	// Extract gRPC status from the error
	st, ok := status.FromError(err)
	if !ok {
		return false
	}

	// Check if the error code is RESOURCE_EXHAUSTED and contains the quota exceeded message
	if st.Code() == codes.ResourceExhausted {
		return strings.Contains(st.Message(), "USAGE_QUOTA_EXCEEDED")
	}

	return false
}

// receiveWithErrorHandling receives an action and handles special error cases
func (sm *streamManager) Recv() (*pb.Action, error) {
	action, err := sm.wf.Recv()
	if err != nil {
		if err == io.EOF {
			return nil, err // Expected error when a workflow ends
		}

		grpcCode := status.Code(err)
		sessionErrorsTotal.WithLabelValues(grpcCode.String()).Inc()

		// Check if this is a RESOURCE_EXHAUSTED error indicating quota exceeded
		if sm.isUsageQuotaExceededError(err) {
			return nil, errUsageQuotaExceededError
		}

		// Unavailable typically means DWS closed the stream after processing
		// a stop request. Return a sentinel so the caller can distinguish this
		// from other gRPC errors.
		if grpcCode == codes.Unavailable {
			return nil, fmt.Errorf("failed to read a gRPC message: %w", errStreamUnavailable)
		}

		// InvalidArgument means the client reconnected to a workflow that is
		// paused at a stable boundary with an empty goal. Return an error that
		// carries only the DWS status message (not the full wrapped chain) so
		// the caller can detect the case via errors.Is(err, errInvalidRequest)
		// while forwarding a close reason that fits the 125-byte control-frame
		// limit. Forwarding the wrapped err.Error() here overflowed that limit
		// and caused the 4400 close frame to be silently dropped.
		if grpcCode == codes.InvalidArgument {
			return nil, &invalidRequestError{msg: status.Convert(err).Message()}
		}

		return nil, fmt.Errorf("failed to read a gRPC message: %w", err)
	}

	return action, nil
}
