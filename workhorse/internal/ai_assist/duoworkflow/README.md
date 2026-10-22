# Duo Workflow Package

This package implements Workhorse's support for AI-assisted features through integration with the Duo Workflow Service. It provides two entry points: a WebSocket endpoint that proxies between a client and the Duo Workflow Service, and an HTTP endpoint that runs a flow for a caller that cannot execute actions itself. Both share gRPC communication and action handling for AI workflows.

## Overview

The `duoworkflow` package enables GitLab's AI-assisted features (Duo Chat, Duo Agent) by:

1. Managing WebSocket connections between clients and Workhorse
1. Running a flow on behalf of a caller that cannot execute actions, streaming its progress back as newline-delimited JSON
1. Establishing gRPC streams to the Duo Workflow Service
1. Handling bidirectional message exchange
1. Executing actions (HTTP requests, MCP tool calls) on behalf of the Duo Workflow Service
1. Supporting various deployment scenarios (GitLab.com, self-managed, self-hosted)

## Package structure

- **handler.go**: HTTP handler for WebSocket connections and graceful shutdown management
- **runner.go**: Main orchestrator that manages the lifecycle of a single workflow execution
- **action_pool.go**: Bounded worker pool that runs the actions Workhorse executes itself concurrently
- **session.go**: State shared by every part of one run: the original request, the run's context, the workflow ID, and the `X-Forwarded-For` value for requests made on the client's behalf
- **stop_coordinator.go**: The stop handshake with the Duo Workflow Service and the coordination between `Shutdown` and `Close`
- **teardown.go**: Classifies why a stream ended, for the `teardown_reason` metric label
- **transport.go**: Defines the `clientTransport` interface, the runner's view of the client that started the workflow
- **websocket.go**: WebSocket implementation of `clientTransport`, including read deadlines, keepalive pings, and close handling
- **http_transport.go**: ndjson implementation of `clientTransport`, which streams actions to a caller that executes none of them
- **http_handler.go**: HTTP handler for server-side flow execution, including start request decoding and outcome reporting
- **stream_manager.go**: Manages gRPC streams to the Duo Workflow Service (primary and optional cloud-tracking stream for self-hosted deployments)
- **client.go**: gRPC client for communicating with the Duo Workflow Service
- **action_dispatcher.go**: Routes each action from the Duo Workflow Service to whoever executes it (Workhorse or the client), and reports one log line and one set of metrics per action
- **actions.go**: Handler for executing HTTP action requests from the Duo Workflow Service
- **mcp.go**: Model Context Protocol (MCP) client for tool execution
- **lock.go**: Distributed workflow locking using Redis, and the `workflowLease` a run holds
- **metrics.go**: Prometheus metrics

## Core components

### Handler

The `Handler` manages WebSocket connections and provides graceful shutdown:

```go
type Handler struct {
    rails    *api.API
    rdb      *redis.Client
    backend  http.Handler
    upgrader websocket.Upgrader
    runners  sync.Map // map[*runner]bool
}
```

**Key responsibilities:**

- Accepts HTTP requests and upgrades them to WebSocket connections
- Pre-authorizes requests with GitLab Rails
- Creates and tracks `runner` instances for each connection
- Gracefully shuts down all active runners during server shutdown

**Usage:**

```go
handler := NewHandler(rails, rdb, backend)
http.Handle("/ai/duoworkflow", handler.Build())
```

### Client

The `Client` manages gRPC communication with the Duo Workflow Service:

```go
type Client struct {
    grpcConn   *grpc.ClientConn
    grpcClient pb.DuoWorkflowClient
    headers    map[string]string
}
```

**Key features:**

- Creates gRPC connections with keepalive parameters
- Maintains bidirectional streams for message exchange
- Implements retry logic with exponential backoff
- Handles connection failures gracefully

**Configuration:**

- Maximum message size: 4MB
- Keepalive time: 20 seconds
- Retry attempts: 4 with exponential backoff

### Client transport

The runner does not talk to the client directly. It talks to a `clientTransport`, and
`wsManager` is the WebSocket implementation of that interface. Keeping the runner behind
this interface lets a second transport reuse the same distributed locking, stop handshake,
graceful shutdown, MCP tool execution, and metrics.

```go
type clientTransport interface {
	Start() error
	KeepaliveInterval() time.Duration
	Keepalive() error
	ReadClientEvent() (*pb.ClientEvent, error)
	ReadError(err error) (reason string, ok bool)
	WriteAction(ctx context.Context, action *pb.Action) error
	SendGoingAway() error
	SendInvalidRequest(reason string) error
	Close() error
}
```

There are two implementations, and what separates them is whether the client is an executor:

- `wsManager` backs the WebSocket endpoint. The client on the other end runs commands, reads
  files, and answers with an `ActionResponse`, so every action is handed to it.
- `ndjsonTransport` backs the server-side execution endpoint. Its caller executes nothing, so
  only `NewCheckpoint` actions are written out and every other action is rejected with
  `errActionUnsupported`. The runner then answers the Duo Workflow Service itself with an error
  `ActionResponse`. This is not optional: the Duo Workflow Service waits for a response to every
  action it emits, and an unanswered action stalls the flow until its own timeout.

### Server-side execution

`Handler.BuildHTTP` serves callers that want a flow run for them and cannot execute actions at
all, such as a chat turn arriving from a Slack integration and handled in a Sidekiq job. Before
this endpoint existed, the only way to run a flow for such a caller was to start a CI job whose
only purpose was to hold the gRPC stream and answer actions.

- **Route**: `POST /api/v4/ai/duo_workflows/workflows/:workflow_id/execute`, registered as
  `duo_workflow_execute` in `internal/upstream/routes.go`
- **Request**: a protojson-encoded `StartWorkflowRequest`, capped at `MaxMessageSize`. Workhorse
  sends it as the first client event instead of waiting for a client to send one
- **Response**: HTTP 200 with `Content-Type: application/x-ndjson`, one protojson-encoded
  `Action` per line, flushed as it arrives over a single chunked response. Empty lines are
  keepalives that carry no action, and ndjson readers skip them

The request is pre-authorized with GitLab Rails through the same `PreAuthorizeHandler` mechanism
as the `:ws` endpoint. The workflow ID comes from the pre-authorization response
(`api.DuoWorkflow.WorkflowID`), never from the request body, because Workhorse authorizes nothing
itself. A body naming a different workflow is rejected with `400`.

The caller's `clientCapabilities`, `mcpTools`, and `preapprovedTools` are dropped from the body.
Capabilities describe an executor, and Workhorse is not one here. The tools available to the flow
are the ones Rails configured. The runner still appends the server capabilities Rails reported.

Only `NewCheckpoint` actions reach the caller, so it can follow the flow's progress.
`RunHTTPRequest`, `RunMCPTool` for known tools, and `TrackLlmCallForSelfHosted` are executed by
Workhorse exactly as on the WebSocket path.

The response header is committed lazily, on the first action or keepalive written. Until then, a
failure is reported as a real HTTP status code:

| Status | Trigger                                                                          |
| ------ | -------------------------------------------------------------------------------- |
| `400`  | Request body cannot be decoded, or the Duo Workflow Service rejects it as invalid |
| `403`  | Usage quota is exhausted                                                          |
| `409`  | Workflow lock is held by another run                                              |
| `500`  | Pre-authorization response is missing the service config or the workflow ID       |
| `502`  | gRPC stream to the Duo Workflow Service cannot be opened                          |

On the WebSocket path the same conditions arrive as WebSocket close codes (`1013`, `1008`,
`4400`) that the client has to interpret.

Once the response is committed, a failure can only end the stream. The caller tells a completed
run from an interrupted one through the workflow's status in the database, which the Duo Workflow
Service keeps up to date. There is deliberately no in-band terminal record, so that the line
format stays exactly the `Action` stream WebSocket clients already parse.

If the caller hangs up, no `StopWorkflowRequest` can be sent: the gRPC stream is derived from the
HTTP request context, so it is already gone. The Duo Workflow Service sees the canceled stream
and treats it as a disconnect, exactly as when a WebSocket client vanishes, which leaves the
workflow resumable from its last checkpoint. On a Workhorse graceful shutdown, where the caller
is still connected and the stream is intact, the stop request is sent as usual. As on the
WebSocket endpoint, there is deliberately no maximum run duration.

### Runner

The `runner` orchestrates a single workflow execution:

```go
type runner struct {
	session             *session
	httpActionHandler   *runHTTPActionHandler
	client              clientTransport
	lease               *workflowLease
	serverCapabilities  []string
	streamManager       *streamManager
	mcpManager          mcpManager
	stop                 stopCoordinator
	stopWorkflowTimeout  time.Duration
	maxConcurrentActions int
	actions              *actionPool
	started              bool
	teardown             teardownTracker
}
```

**Responsibilities:**

- Handles client events received over the client transport
- Handles gRPC actions from the Duo Workflow Service
- Manages message serialization/deserialization
- Coordinates HTTP request execution and MCP tool calls
- Manages workflow lifecycle and graceful shutdown

**Message handling flow:**

1. **Client events** → Unmarshal JSON to Protocol Buffer → Send to gRPC stream. Only the first start request on a connection is accepted; a client reconnects to start again
2. **gRPC actions** → Process action type → Execute action → Send response back to gRPC stream. See [Concurrent actions](#concurrent-actions)
3. **Client disconnect** → Send StopWorkflow request → Wait for acknowledgment. Concurrent stop requests send a single StopWorkflow request and share its acknowledgment

#### Concurrent actions

Client-bound actions are always written by the goroutine that receives them, in the order they arrive. See [Action dispatch](#action-dispatch).

By default, actions run one at a time on the receiving goroutine, so the next `Recv` waits until the action has completed. When Rails sets `MaxConcurrentActions` above 1, the actions Workhorse executes run on a per-run `actionPool` of that many workers instead, and the receiving goroutine moves straight on. Duo Workflow Service matches responses to actions by request ID, so they can complete in any order.

- **Back-pressure**: when every worker is busy, the receiving goroutine waits for one to free up before it reads the next action.
- **Errors**: an action that fails is answered with an error response, as before. A response that cannot be sent ends the run and cancels the other actions in flight.
- **Panics**: a panic while Workhorse executes an action is logged and answered with an error response, so it does not take the process down. This holds with or without a pool.
- **Close**: actions still in flight are canceled and waited for, up to the stop timeout, before the stream is closed, so no response is sent on a closed stream.

### Stream manager

The `streamManager` manages gRPC streams to the Duo Workflow Service:

```go
type streamManager struct {
    wf                 workflowStream
    client             *Client
    cloudServiceClient *Client
    cloudServiceStream selfHostedWorkflowStream
    session            *session
    sendMu             sync.Mutex
    cloudServiceMu     sync.Mutex
}
```

**Responsibilities:**

- Opens and owns the primary `ExecuteWorkflow` gRPC stream
- Optionally opens a secondary `TrackSelfHostedExecuteWorkflow` stream for self-hosted deployments. Each send is paired with the receive that follows it, so concurrent tracking calls take turns on it
- Provides mutex-protected `Send` to allow concurrent goroutines to write safely
- Translates `io.EOF` and quota-exceeded gRPC errors into sentinel errors on `Recv`

### Action dispatch

The `actionDispatcher` classifies each action by who executes it, which is the `type` label on the action metrics:

| Type                   | Actions                                                        | Executed by                     |
| ---------------------- | -------------------------------------------------------------- | ------------------------------- |
| `http`                 | `RunHTTPRequest`                                               | Workhorse, through the upstream router |
| `mcp`                  | `RunMCPTool` for a tool from an MCP server configured in Rails | Workhorse                       |
| `self_hosted_tracking` | `TrackLlmCallForSelfHosted`                                    | Workhorse, through the cloud tracking stream |
| `client`               | Everything else, including MCP tools Workhorse doesn't know    | The client                      |

Client-bound actions are written from the goroutine that receives them, in receive order: clients rely on that order, and a WebSocket allows one writer at a time.

An action the client can't execute, or an MCP call that fails, is answered with an error and the run carries on. Only a failure to send a response, to perform an HTTP action, or to track a self-hosted call ends the run.

Each action Workhorse executes produces one `Handled action` log line with its `action_type`, `request_id`, `outcome`, `duration_s` and `response_size`, plus `method`, `path` (without the query string) and `status_code` for HTTP actions. Client-bound actions are logged only when they fail.

### Action handlers

#### HTTP request execution

The `runHTTPActionHandler` executes HTTP requests to the GitLab API:

```go
type runHTTPActionHandler struct {
    backend                   http.Handler
    token                     string
    session                   *session
    shouldTimeoutHTTPRequests bool
    relativeURLRoot           string
    clientType                string
    clientName                string
}
```

**Process:**

1. Parse the action's path and method
2. Construct an HTTP request to the GitLab API
3. Add authentication headers (OAuth token)
4. Add client IP information (X-Forwarded-For)
5. Execute the request through the backend handler
6. Capture response body and status code
7. Enforce maximum response size (4MB)
8. Return response as Protocol Buffer ActionResponse

**Security features:**

- Uses OAuth tokens from the original request
- Validates request paths
- Limits response body size to prevent memory exhaustion
- Preserves X-Forwarded-For headers

#### MCP tool execution

The MCP manager handles communication with Model Context Protocol servers:

```go
type mcpManager interface {
    Tools() []*pb.McpTool
    PreApprovedTools() []string
    HasTool(name string) bool
    CallTool(ctx context.Context, action *pb.Action) (*pb.ClientEvent, error)
    Close() error
}
```

**Features:**

- Initializes connections to configured MCP servers concurrently
- Shares one transport for external MCP servers, so idle connections can be reused across sessions
- Discovers available tools from each server, ordered by server name
- Filters tools by name and pre-approved status
- Executes tool calls and returns results
- Handles tool execution errors gracefully

### Workflow locking

For self-managed instances, distributed workflow locking prevents concurrent execution:

```go
type workflowLockManager struct {
    rdb *redis.Client
}
```

**Process:**

1. Acquire a distributed lock when workflow starts
2. Release the lock once the stream to Duo Workflow Service is closed, even when the caller has already gone away. When Duo Workflow Service doesn't acknowledge a stop, the stream is closed and the lock released one stop timeout (10s) after the stop request. `Shutdown` and `Close` both release it, and only the first release takes effect
3. Return specific error if lock cannot be acquired
4. Requires Redis configuration

## Message flow

### Client to Duo Workflow Service

```
WebSocket ClientEvent
    ↓
Unmarshal JSON to Protocol Buffer
    ↓
streamManager.Send
    ↓
Duo Workflow Service receives ClientEvent
```

### Duo Workflow Service to client

```
gRPC Action received (streamManager.Recv)
    ↓
Determine action type
    ↓
Execute action (HTTP request or MCP tool)
    ↓
Create ActionResponse
    ↓
streamManager.Send
    ↓
Receive response in gRPC stream
    ↓
Marshal to JSON
    ↓
Send to WebSocket
    ↓
Client receives action response
```

## Metrics

The package exposes the Prometheus metrics below. Every label value comes from a fixed set, never from user input, the Duo Workflow Service or the client.

### `gitlab_workhorse_duo_workflow_connections_open`

The number of runners currently executing, labeled by `transport`, incremented when a runner is registered and decremented when it is torn down.

This gauge is the only way to see concurrency. `gitlab_workhorse_http_in_flight_requests` is not a substitute: it is unlabelled, so it cannot be narrowed to this route, and it also counts the HTTP actions that re-enter the upstream router while the connection is still open.

Use it to normalise process memory per connection. Sum over `transport` first, because a WebSocket connection and a server-side run cost different amounts and mixing them makes the ratio meaningless on its own:

```promql
go_memstats_heap_inuse_bytes{job=~"gitlab-workhorse.*"}
  / on(instance) sum without(transport) (gitlab_workhorse_duo_workflow_connections_open)
```

### `gitlab_workhorse_duo_workflow_sessions_total`

Incremented each time a gRPC `ExecuteWorkflow` stream is successfully opened to the Duo Workflow Service (inside `newStreamManager`).

### `gitlab_workhorse_duo_workflow_session_errors_total`

Incremented for every non-EOF error received on the `ExecuteWorkflow` stream, labelled by `grpc_code` and `teardown_reason`. `grpc_code` is the gRPC status code string (e.g. `"Internal"`, `"Unavailable"`, `"ResourceExhausted"`). `io.EOF` is the normal end-of-stream signal and does not increment this counter.

`teardown_reason` records what ended the stream, because a single gRPC code covers causes that are not equally a failure: an `Unavailable` arrives both when DWS closes the stream to acknowledge a stop workhorse asked for, and when the connection to DWS fails outright. Possible values:

| `teardown_reason`         | Trigger                                                                                                        |
| ------------------------- | -------------------------------------------------------------------------------------------------------------- |
| `unsolicited`             | Nothing on the workhorse side asked for this teardown: DWS closed the stream on its own, or the transport failed |
| `client_normal_close`     | Client closed the WebSocket with a normal code (1000 or 1001): the user closed the browser tab or IDE panel, or stopped the flow |
| `client_pong_timeout`     | Client stopped answering pings                                                                                  |
| `client_keepalive_failed` | Writing a keepalive to the client failed, so its connection was already gone                                     |
| `client_read_failed`      | Reading from the client failed unexpectedly: an abnormal WebSocket closure, a connection reset, or an unparsable message |
| `workhorse_shutdown`      | This workhorse instance is draining                                                                             |

Every reason except `unsolicited` means workhorse initiated the teardown, so the gRPC error is the expected end of the stream rather than a failure. Filter on `teardown_reason="unsolicited"` to alert only on unexpected terminations:

```promql
sum(rate(gitlab_workhorse_duo_workflow_session_errors_total[5m])) by (grpc_code, teardown_reason)
```

### `gitlab_workhorse_duo_workflow_http_actions_total`

Incremented once for every HTTP action executed on behalf of the Duo Workflow Service (in `runHTTPActionHandler.Execute`), labelled by `method` and `status_code`. `method` is one of the standard HTTP methods, or `other`: the Duo Workflow Service can send any valid method token.

`status_code` is `"0"` when the request could not be completed at all, so no response status exists — for example a timeout, an aborted request, or a response exceeding the body size limit. Those cases are also counted in `http_action_errors_total`.

Example query for the rate of 5xx actions:

```promql
sum(rate(gitlab_workhorse_duo_workflow_http_actions_total{status_code=~"5.."}[5m])) by (method)
```

### `gitlab_workhorse_duo_workflow_http_action_duration_seconds`

Histogram of HTTP action latency in seconds, labelled by `method`, using the Prometheus default buckets. The duration is observed for every action, including those that end in a transport-level error.

Example query for the 95th percentile:

```promql
histogram_quantile(0.95, sum(rate(gitlab_workhorse_duo_workflow_http_action_duration_seconds_bucket[5m])) by (le, method))
```

### `gitlab_workhorse_duo_workflow_http_action_errors_total`

Incremented when an HTTP action fails with a transport-level error, labelled by `method` and `error_type`:

| `error_type`          | Trigger                                                                                    |
| --------------------- | ------------------------------------------------------------------------------------------ |
| `timeout`             | Request context deadline exceeded (`httpRequestTimeout`)                                    |
| `aborted`             | Backend panicked with `http.ErrAbortHandler`, typically a client disconnect or cancellation |
| `size_limit_exceeded` | Response body exceeded `ActionResponseBodyLimit`                                            |
| `other`               | Defensive fallback for any error not matching the above                                     |

HTTP 4xx and 5xx responses are not errors at this layer: the backend answered, so they are counted only in `http_actions_total` under their status code.

Example query:

```promql
sum(rate(gitlab_workhorse_duo_workflow_http_action_errors_total[5m])) by (method, error_type)
```

### `gitlab_workhorse_duo_workflow_actions_total`, `_action_duration_seconds` and `_actions_in_flight`

Every action received from the Duo Workflow Service, labelled by `type` (see [Action dispatch](#action-dispatch)). The counter also carries `outcome`:

| `outcome` | Meaning                                                                            |
| --------- | ---------------------------------------------------------------------------------- |
| `ok`      | Answered, or forwarded to the client. HTTP 4xx and 5xx responses count as answered |
| `error`   | Answered with an error, and the run carried on                                     |
| `fatal`   | Handling the action ended the run                                                  |

The duration runs from the start of execution until the response is sent, or until the action is written to the client. It excludes the time an action waits for a free worker in the action pool, which `action_queue_wait_seconds` measures.

```promql
histogram_quantile(0.95, sum(rate(gitlab_workhorse_duo_workflow_action_duration_seconds_bucket[5m])) by (le, type))
```

### `gitlab_workhorse_duo_workflow_action_queue_wait_seconds`

Histogram of how long an action waited for a free worker in the run's action pool, in seconds, labelled by `type` (`http`, `mcp` or `self_hosted_tracking`). Only observed when actions run concurrently.

### `gitlab_workhorse_duo_workflow_action_pool_saturated_total`

Incremented when an action finds every worker in the run's action pool busy, so the runner stops receiving from Duo Workflow Service until a worker is free. A rising rate means `MaxConcurrentActions` is too low for the workload, or a slow upstream such as an MCP server is holding workers.

### `gitlab_workhorse_duo_workflow_mcp_calls_total`, `_mcp_call_duration_seconds` and `_mcp_init_failures_total`

MCP tool calls, labelled by `server`: `gitlab`, `orbit` or `slack` for the servers Rails configures itself, and `catalog` for every server added through the AI Catalog, whose names users choose. The `Failed to initialize MCP server` log line carries the actual name. `outcome` on the counter is `ok`, `tool_error` (the server answered with `isError`) or `error` (the call failed). `mcp_init_failures_total` counts servers whose tools are missing from a run because connecting or listing tools failed.

### `gitlab_workhorse_duo_workflow_session_duration_seconds`

How long a run lasts, from the start of execution until the runner is closed, labelled by `transport` and `teardown_reason`. A run that finishes normally ends when DWS closes the stream, so it is labelled `unsolicited`, as is a run ended by an error.

### `gitlab_workhorse_duo_workflow_session_setup_duration_seconds`

The setup that runs before a run starts, labelled by `stage`: `grpc` opens the stream to the Duo Workflow Service, and `mcp` initializes the MCP servers, one at a time. `grpc` is only observed when the stream opens, and `mcp` only when MCP servers are configured. `mcp` includes servers that fail to initialize.

### `gitlab_workhorse_duo_workflow_lock_acquire_total` and `_lock_release_failures_total`

Workflow lock attempts by `outcome`: `acquired`, `taken` (another run holds it, so this one ends) or `transient_error` (Redis failed, so the run goes ahead without a lock). A lock that couldn't be released stays in Redis until it expires after two hours.

### `gitlab_workhorse_duo_workflow_stop_requests_total`

`StopWorkflowRequest`s sent to the Duo Workflow Service, by `outcome`: `acked`, `timeout` (no acknowledgment within the stop timeout) or `send_failed`.

## Configuration

### From GitLab Rails

Workhorse receives configuration during pre-authorization:

```go
type DuoWorkflow struct {
    Service                  *DuoWorkflowServiceConfig // Primary gRPC service
    CloudServiceForSelfHosted *DuoWorkflowServiceConfig // Optional cloud tracking service
    LockConcurrentFlow       bool                      // Enable workflow locking
    McpServers               map[string]*McpServerConfig
    MaxConcurrentActions     int                       // Actions Workhorse may execute at once; 0 or 1 runs them one at a time
}

type DuoWorkflowServiceConfig struct {
    URI     string            // gRPC service URI (e.g., "localhost:50052")
    Headers map[string]string // Headers for gRPC requests (e.g., OAuth token)
    Secure  bool              // Use TLS for gRPC connection
}
```

### MCP server configuration

MCP servers are configured in GitLab Rails and passed to Workhorse:

```ruby
{
  gitlab: {
    # URL is automatically resolved in Workhorse
    Headers: { "Authorization" => "Bearer token" },
    Tools: ["tool1", "tool2"], # Omit the key for all tools; an empty list serves none
    PreApprovedTools: ["tool1"]
  },
  external_server: {
    URL: "https://mcp-server.example.com",
    Headers: { "Authorization" => "Bearer token" },
    Tools: []
  }
}
```

## Error handling

### Connection errors

- **Duo Workflow Service unavailable**: Returns `ErrServerUnavailable` and closes WebSocket
- **Runner initialization failure**: The WebSocket is closed with `CloseInternalServerErr` (1011), because the connection is already upgraded and cannot carry an HTTP error
- **MCP server unavailable**: Logs error and continues without MCP tools
- **Network errors**: Implements gRPC retry logic with exponential backoff
- **Usage quota exceeded**: gRPC `RESOURCE_EXHAUSTED` with `USAGE_QUOTA_EXCEEDED` message is translated to `errUsageQuotaExceededError`; the WebSocket is closed with `ClosePolicyViolation`

### Message handling errors

- **Invalid messages**: Logs error and closes connection
- **Oversized responses**: Truncates response bodies to maximum size
- **Serialization errors**: Returns error response to Duo Workflow Service

### Graceful shutdown

During server shutdown:

1. Initiates graceful shutdown of all active runners
2. Sends `StopWorkflow` requests to Duo Workflow Service
3. Waits for workflows to complete within timeout
4. Forcefully terminates connections if needed

## Security

### Authentication and authorization

- Pre-authorization with GitLab Rails before WebSocket upgrade
- OAuth tokens from original request used for API calls
- Secure token propagation through Workhorse

## Testing

Test files are located in the same directory:

- **handler_test.go**: WebSocket connection handling and pre-authorization
- **http_transport_test.go**: ndjson line framing, keepalives, action rejection, and lazy header commit
- **http_handler_test.go**: start request decoding, streamed responses, and failure status codes
- **client_test.go**: gRPC client creation and connection management
- **runner_test.go**: Message handling and workflow execution
- **actions_test.go**: HTTP request execution and response handling
- **mcp_test.go**: MCP server communication
- **lock_test.go**: Distributed workflow locking
- **metrics_test.go**: Prometheus counter instrumentation
- **action_dispatcher_test.go**: Action classification, per-action metrics and logging

### Running tests

```bash
go test ./internal/ai_assist/duoworkflow/... -v
```

## Constants and limits

- **MaxMessageSize**: 4MB — maximum size of gRPC messages
- **ActionResponseBodyLimit**: ~4MB — maximum response body size
- **wsWriteDeadline**: 60 seconds — WebSocket write timeout
- **wsCloseTimeout**: 5 seconds — WebSocket close timeout
- **wsStopWorkflowTimeout**: 10 seconds — workflow stop request timeout
- **httpKeepaliveInterval**: 20 seconds — ndjson keepalive interval, matching the WebSocket ping interval
- **startRequestBodyLimit**: 4MB (`MaxMessageSize`) — maximum server-side execution request body size
- **gRPC keepalive time**: 20 seconds — keepalive ping interval
- **gRPC retry attempts**: 4 — maximum retry attempts for failed requests

## Related documentation

- [AI-assisted features architecture](../../doc/development/workhorse/ai_assisted_features_architecture.md)
- [Workhorse development guide](https://docs.gitlab.com/ee/development/workhorse/)
- [Duo Workflow Service](https://gitlab.com/gitlab-org/modelops/applied-ml/code-suggestions/ai-assist)
- [Model Context Protocol (MCP)](https://modelcontextprotocol.io/)
