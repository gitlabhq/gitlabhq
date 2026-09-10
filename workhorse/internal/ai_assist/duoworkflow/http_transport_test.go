package duoworkflow

import (
	"context"
	"errors"
	"net/http"
	"net/http/httptest"
	"strings"
	"sync"
	"testing"

	"github.com/stretchr/testify/assert"
	"github.com/stretchr/testify/require"

	pb "gitlab.com/gitlab-org/modelops/applied-ml/code-suggestions/ai-assist/clients/gopb/contract"
)

func newTestNdjsonTransport(t *testing.T, startEvent *pb.ClientEvent) (*ndjsonTransport, *httptest.ResponseRecorder, context.CancelFunc) {
	t.Helper()

	req := httptest.NewRequest(http.MethodPost, "/execute", nil)
	ctx, cancel := context.WithCancel(req.Context())
	t.Cleanup(cancel)

	recorder := httptest.NewRecorder()

	return newNdjsonTransport(recorder, req.WithContext(ctx), startEvent), recorder, cancel
}

// parseNdjsonActions parses an ndjson response body back into actions,
// skipping the empty lines written as keepalives.
func parseNdjsonActions(t *testing.T, body string) []*pb.Action {
	t.Helper()

	var actions []*pb.Action

	for _, line := range strings.Split(body, "\n") {
		if line == "" {
			continue
		}

		action := &pb.Action{}
		require.NoError(t, unmarshaler.Unmarshal([]byte(line), action), "each line must be one complete action")
		actions = append(actions, action)
	}

	return actions
}

func newTestStartEvent() *pb.ClientEvent {
	return &pb.ClientEvent{
		Response: &pb.ClientEvent_StartRequest{
			StartRequest: &pb.StartWorkflowRequest{WorkflowID: testWorkflowID},
		},
	}
}

// testCheckpointPayload stands in for the serialized graph state DWS puts in a
// checkpoint. Its contents are opaque to workhorse.
const testCheckpointPayload = "serialized-graph-state"

func checkpointAction(requestID string) *pb.Action {
	return &pb.Action{
		RequestID: requestID,
		Action: &pb.Action_NewCheckpoint{
			NewCheckpoint: &pb.NewCheckpoint{Checkpoint: testCheckpointPayload},
		},
	}
}

func TestNdjsonTransport_ReadClientEvent(t *testing.T) {
	t.Run("reports the start event once", func(t *testing.T) {
		startEvent := newTestStartEvent()
		transport, _, cancel := newTestNdjsonTransport(t, startEvent)

		event, err := transport.ReadClientEvent()
		require.NoError(t, err)
		require.Same(t, startEvent, event)

		// The caller never sends anything else, so the second read blocks
		// until the request is canceled.
		cancel()

		_, err = transport.ReadClientEvent()
		require.ErrorIs(t, err, errClientGone)
	})

	t.Run("unblocks on Close", func(t *testing.T) {
		transport, _, _ := newTestNdjsonTransport(t, newTestStartEvent())

		_, err := transport.ReadClientEvent()
		require.NoError(t, err)

		require.NoError(t, transport.Close())

		_, err = transport.ReadClientEvent()
		require.ErrorIs(t, err, errTransportClosed)
	})

	t.Run("Close is idempotent", func(t *testing.T) {
		transport, _, _ := newTestNdjsonTransport(t, newTestStartEvent())

		require.NoError(t, transport.Close())
		require.NoError(t, transport.Close())
	})
}

func TestNdjsonTransport_ReadError(t *testing.T) {
	transport, _, _ := newTestNdjsonTransport(t, newTestStartEvent())

	// No read error can be answered with a stop request: the gRPC stream shares
	// the request context, so a caller that goes away takes the stream with it.
	for _, err := range []error{errClientGone, errTransportClosed, errors.New("boom")} {
		_, ok := transport.ReadError(err)
		require.False(t, ok, "no stop request can be sent for %v", err)
	}
}

func TestNdjsonTransport_WriteAction(t *testing.T) {
	t.Run("writes a checkpoint as one line and commits the response", func(t *testing.T) {
		transport, recorder, _ := newTestNdjsonTransport(t, newTestStartEvent())

		require.False(t, transport.HeaderWritten())

		require.NoError(t, transport.WriteAction(context.Background(), checkpointAction("req-1")))
		require.NoError(t, transport.WriteAction(context.Background(), checkpointAction("req-2")))

		require.True(t, transport.HeaderWritten())
		require.Equal(t, http.StatusOK, recorder.Code)
		require.Equal(t, "application/x-ndjson", recorder.Header().Get("Content-Type"))
		require.True(t, recorder.Flushed)

		actions := parseNdjsonActions(t, recorder.Body.String())
		require.Len(t, actions, 2, "one line per action, and no trailing garbage")
		require.Equal(t, "req-1", actions[0].RequestID)
		require.Equal(t, testCheckpointPayload, actions[0].GetNewCheckpoint().Checkpoint)
		require.Equal(t, "req-2", actions[1].RequestID)
	})

	t.Run("rejects every action the caller cannot execute", func(t *testing.T) {
		unsupported := map[string]*pb.Action{
			"run command":    {Action: &pb.Action_RunCommand{RunCommand: &pb.RunCommandAction{Program: "ls"}}},
			"read file":      {Action: &pb.Action_RunReadFile{RunReadFile: &pb.ReadFile{Filepath: "README.md"}}},
			"list directory": {Action: &pb.Action_ListDirectory{ListDirectory: &pb.ListDirectory{Directory: "."}}},
			"mcp tool":       {Action: &pb.Action_RunMCPTool{RunMCPTool: &pb.RunMCPTool{Name: "local_tool"}}},
			"no action set":  {},
		}

		for name, action := range unsupported {
			t.Run(name, func(t *testing.T) {
				transport, recorder, _ := newTestNdjsonTransport(t, newTestStartEvent())

				err := transport.WriteAction(context.Background(), action)

				require.ErrorIs(t, err, errActionUnsupported)
				require.Empty(t, recorder.Body.String(), "a rejected action must not reach the caller")
				require.False(t, transport.HeaderWritten())
			})
		}
	})
}

func TestNdjsonTransport_Keepalive(t *testing.T) {
	t.Run("writes an empty line that ndjson readers skip", func(t *testing.T) {
		transport, recorder, _ := newTestNdjsonTransport(t, newTestStartEvent())

		require.NoError(t, transport.Keepalive())
		require.NoError(t, transport.WriteAction(context.Background(), checkpointAction("req-1")))
		require.NoError(t, transport.Keepalive())

		body := recorder.Body.String()
		require.True(t, strings.HasPrefix(body, "\n"))
		require.True(t, strings.HasSuffix(body, "\n\n"))
		require.Len(t, parseNdjsonActions(t, body), 1)
	})

	t.Run("commits the response so an idle flow keeps the connection", func(t *testing.T) {
		transport, recorder, _ := newTestNdjsonTransport(t, newTestStartEvent())

		require.NoError(t, transport.Keepalive())

		require.True(t, transport.HeaderWritten())
		require.Equal(t, http.StatusOK, recorder.Code)
		require.True(t, recorder.Flushed)
	})

	t.Run("is serialized against action writes", func(t *testing.T) {
		transport, recorder, _ := newTestNdjsonTransport(t, newTestStartEvent())

		var wg sync.WaitGroup
		for range 20 {
			wg.Add(2)
			go func() {
				defer wg.Done()
				assert.NoError(t, transport.Keepalive())
			}()
			go func() {
				defer wg.Done()
				assert.NoError(t, transport.WriteAction(context.Background(), checkpointAction("req")))
			}()
		}
		wg.Wait()

		// Interleaved writes must not corrupt the stream: every action still
		// parses, on a line of its own.
		actions := parseNdjsonActions(t, recorder.Body.String())
		require.Len(t, actions, 20)
		for _, action := range actions {
			require.Equal(t, testCheckpointPayload, action.GetNewCheckpoint().Checkpoint)
		}
	})
}

func TestNdjsonTransport_InvalidRequest(t *testing.T) {
	transport, recorder, _ := newTestNdjsonTransport(t, newTestStartEvent())

	require.Empty(t, transport.InvalidRequestReason())

	require.NoError(t, transport.SendInvalidRequest("goal is empty"))

	require.Equal(t, "goal is empty", transport.InvalidRequestReason())
	require.Empty(t, recorder.Body.String(), "the reason is reported as a status code, not in the stream")
	require.False(t, transport.HeaderWritten())
}

func TestNdjsonTransport_SendGoingAway(t *testing.T) {
	transport, recorder, _ := newTestNdjsonTransport(t, newTestStartEvent())

	// There is no reconnect signal to send: the caller learns that the flow was
	// stopped from the workflow's status.
	require.NoError(t, transport.SendGoingAway())
	require.Empty(t, recorder.Body.String())
	require.False(t, transport.HeaderWritten())
}

func TestNdjsonTransport_ImplementsClientTransport(_ *testing.T) {
	var _ clientTransport = &ndjsonTransport{}
}
