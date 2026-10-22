package duoworkflow

import (
	"context"
	"errors"
	"fmt"
	"runtime/debug"
	"strings"
	"time"

	pb "gitlab.com/gitlab-org/modelops/applied-ml/code-suggestions/ai-assist/clients/gopb/contract"
	"google.golang.org/protobuf/proto"

	"gitlab.com/gitlab-org/gitlab/workhorse/internal/log"
)

var errActionPanicked = errors.New("internal error while executing the action")

// actionDispatcher hands each action received from the Duo Workflow Service to
// whoever executes it: Workhorse itself, or the client. It reports one log line
// and one set of metrics per action.
type actionDispatcher struct {
	session     *session
	client      clientTransport
	httpActions *runHTTPActionHandler
	mcp         mcpManager
	streams     *streamManager
	// pool runs the actions Workhorse executes itself. When nil, they run
	// one at a time on the goroutine receiving them.
	pool *actionPool
}

func (r *runner) actionDispatcher() *actionDispatcher {
	return &actionDispatcher{
		session:     r.session,
		client:      r.client,
		httpActions: r.httpActionHandler,
		mcp:         r.mcpManager,
		streams:     r.streamManager,
		pool:        r.actions,
	}
}

// actionResult is how handling one action went.
type actionResult struct {
	// actionErr is the error the action was answered with. The run carries on.
	actionErr error
	// fatalErr ends the run.
	fatalErr error
	// responseSize is the size of the response sent to the Duo Workflow Service.
	responseSize int
	fields       log.Fields
}

func (res *actionResult) outcome() string {
	switch {
	case res.fatalErr != nil:
		return actionOutcomeFatal
	case res.actionErr != nil:
		return actionOutcomeError
	default:
		return actionOutcomeOK
	}
}

// classify returns the action type, which says who executes the action.
// Client-bound actions must be written from the goroutine that receives them,
// in receive order: clients rely on that order, and a WebSocket allows only one
// writer at a time.
func (d *actionDispatcher) classify(action *pb.Action) string {
	switch a := action.Action.(type) {
	case *pb.Action_RunHTTPRequest:
		return actionTypeHTTP
	case *pb.Action_RunMCPTool:
		// Tools Workhorse doesn't know come from MCP servers configured in the
		// client, such as an IDE.
		if d.mcp.HasTool(a.RunMCPTool.GetName()) {
			return actionTypeMCP
		}
		return actionTypeClient
	case *pb.Action_TrackLlmCallForSelfHosted:
		return actionTypeSelfHostedTracking
	default:
		return actionTypeClient
	}
}

// dispatch handles one action, or hands it to the action pool. It returns an
// error only when the run must end.
func (d *actionDispatcher) dispatch(ctx context.Context, action *pb.Action) error {
	actionType := d.classify(action)
	if actionType == actionTypeClient || d.pool == nil {
		return d.handle(ctx, actionType, action)
	}

	if err := d.pool.submit(actionType, func(ctx context.Context) error {
		return d.handle(ctx, actionType, action)
	}); err != nil {
		return fmt.Errorf("dispatch: %w", err)
	}

	return nil
}

func (d *actionDispatcher) handle(ctx context.Context, actionType string, action *pb.Action) error {
	inFlight := actionsInFlight.WithLabelValues(actionType)
	inFlight.Inc()
	defer inFlight.Dec()

	start := time.Now()
	res := d.execute(ctx, actionType, action)
	duration := time.Since(start)

	outcome := res.outcome()
	actionsTotal.WithLabelValues(actionType, outcome).Inc()
	actionDurationSeconds.WithLabelValues(actionType).Observe(duration.Seconds())

	// Checkpoints and other client-bound actions are frequent and logged by
	// the client, so only failures to forward them are logged here.
	if actionType != actionTypeClient || outcome != actionOutcomeOK {
		d.log(action, actionType, outcome, res, duration)
	}

	return res.fatalErr
}

func (d *actionDispatcher) execute(ctx context.Context, actionType string, action *pb.Action) (res actionResult) {
	if actionType != actionTypeClient {
		// Neither the receiving goroutine nor a pool worker is covered by
		// net/http's recovery, so a panic would take down the process.
		defer d.recoverAction(&res, action)
	}

	switch actionType {
	case actionTypeHTTP:
		return d.executeHTTP(ctx, action)
	case actionTypeMCP:
		return d.executeMCP(ctx, action)
	case actionTypeSelfHostedTracking:
		tracking := action.GetTrackLlmCallForSelfHosted()
		return actionResult{
			fatalErr: d.streams.HandleCloudServiceTracking(ctx, action),
			fields:   log.Fields{"source_type": tracking.GetSourceType()},
		}
	default:
		return d.writeToClient(ctx, action)
	}
}

// recoverAction answers an action whose execution panicked as a failed action.
func (d *actionDispatcher) recoverAction(res *actionResult, action *pb.Action) {
	p := recover()
	if p == nil {
		return
	}

	d.session.logger().WithFields(log.Fields{
		"request_id": action.GetRequestID(),
		"panic":      fmt.Sprint(p),
		"stack":      string(debug.Stack()),
	}).Error("dispatch: recovered from a panic while executing an action")

	*res = actionResult{}
	d.answerWithError(res, action, errActionPanicked)
}

func (d *actionDispatcher) executeHTTP(ctx context.Context, action *pb.Action) actionResult {
	httpAction := action.GetRunHTTPRequest()
	// The query string can carry user search text.
	path, _, _ := strings.Cut(httpAction.GetPath(), "?")
	res := actionResult{fields: log.Fields{"method": httpAction.GetMethod(), "path": path}}

	event, err := d.httpActions.Execute(ctx, action)
	if err != nil {
		res.fatalErr = fmt.Errorf("dispatch: failed to perform API call: %w", err)
		return res
	}

	httpResponse := event.GetActionResponse().GetHttpResponse()
	res.fields["status_code"] = httpResponse.GetStatusCode()
	if httpResponse.GetError() != "" {
		res.actionErr = errors.New(httpResponse.GetError())
	}

	d.send(&res, event)
	return res
}

func (d *actionDispatcher) executeMCP(ctx context.Context, action *pb.Action) actionResult {
	tool := action.GetRunMCPTool()
	res := actionResult{fields: log.Fields{"tool": tool.GetName(), "args_size": len(tool.GetArgs())}}

	event, err := d.mcp.CallTool(ctx, action)
	if err != nil {
		d.answerWithError(&res, action, err)
		return res
	}

	if toolErr := event.GetActionResponse().GetPlainTextResponse().GetError(); toolErr != "" {
		res.actionErr = errors.New(toolErr)
	}

	d.send(&res, event)
	return res
}

func (d *actionDispatcher) writeToClient(ctx context.Context, action *pb.Action) actionResult {
	err := d.client.WriteAction(ctx, action)
	if !errors.Is(err, errActionUnsupported) {
		return actionResult{fatalErr: err}
	}

	res := actionResult{}
	d.answerWithError(&res, action, err)
	return res
}

// send sends the response to an action. The size is measured here rather than
// under the stream's send lock, since it walks the whole message.
func (d *actionDispatcher) send(res *actionResult, event *pb.ClientEvent) {
	res.responseSize = proto.Size(event)

	if err := d.streams.Send(event); err != nil {
		res.fatalErr = fmt.Errorf("dispatch: failed to send gRPC message: %w", err)
	}
}

// answerWithError answers the action with an error: DWS waits for every
// action to be answered, so none can be dropped.
func (d *actionDispatcher) answerWithError(res *actionResult, action *pb.Action, actionErr error) {
	res.actionErr = actionErr
	d.send(res, &pb.ClientEvent{
		Response: &pb.ClientEvent_ActionResponse{
			ActionResponse: &pb.ActionResponse{
				RequestID: action.RequestID,
				ResponseType: &pb.ActionResponse_PlainTextResponse{
					PlainTextResponse: &pb.PlainTextResponse{Error: actionErr.Error()},
				},
			},
		},
	})
}

func (d *actionDispatcher) log(action *pb.Action, actionType string, outcome string, res actionResult, duration time.Duration) {
	logger := d.session.logger().WithFields(res.fields).WithFields(log.Fields{
		"request_id":    action.GetRequestID(),
		"action":        actionName(action),
		"action_type":   actionType,
		"outcome":       outcome,
		"duration_s":    duration.Seconds(),
		"response_size": res.responseSize,
	})

	switch outcome {
	case actionOutcomeOK:
		logger.Info("Handled action")
	case actionOutcomeError:
		logger.WithFields(log.Fields{"action_error": res.actionErr.Error()}).Warn("Handled action with an error")
	default:
		logger.WithFields(log.Fields{"action_error": res.fatalErr.Error()}).Warn("Failed to handle action, ending the run")
	}
}

// actionName is the name of the action's oneof field, such as runCommand.
func actionName(action *pb.Action) string {
	m := action.ProtoReflect()
	if fd := m.WhichOneof(m.Descriptor().Oneofs().ByName("action")); fd != nil {
		return string(fd.Name())
	}
	return "unknown"
}
