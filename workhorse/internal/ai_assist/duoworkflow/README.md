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
- **transport.go**: Defines the `clientTransport` interface, the runner's view of the client that started the workflow
- **websocket.go**: WebSocket implementation of `clientTransport`, including read deadlines, keepalive pings, and close handling
- **http_transport.go**: ndjson implementation of `clientTransport`, which streams actions to a caller that executes none of them
- **http_handler.go**: HTTP handler for server-side flow execution, including start request decoding and outcome reporting
- **stream_manager.go**: Manages gRPC streams to the Duo Workflow Service (primary and optional cloud-tracking stream for self-hosted deployments)
- **client.go**: gRPC client for communicating with the Duo Workflow Service
- **actions.go**: Handler for executing HTTP action requests from the Duo Workflow Service
- **mcp.go**: Model Context Protocol (MCP) client for tool execution
- **lock.go**: Distributed workflow locking using Redis
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
	originalReq         *http.Request
	httpActionHandler   *runHTTPActionHandler
	client              clientTransport
	lockManager         *workflowLockManager
	workflowID          string
	mutex               *redsync.Mutex
	lockFlow            bool
	serverCapabilities  []string
	streamManager       *streamManager
	mcpManager          mcpManager
	stop                stopCoordinator
	stopWorkflowTimeout time.Duration
}
```

**Responsibilities:**

- Handles client events received over the client transport
- Handles gRPC actions from the Duo Workflow Service
- Manages message serialization/deserialization
- Coordinates HTTP request execution and MCP tool calls
- Manages workflow lifecycle and graceful shutdown

**Message handling flow:**

1. **Client events** → Unmarshal JSON to Protocol Buffer → Send to gRPC stream
2. **gRPC actions** → Process action type → Execute action → Send response back to gRPC stream
3. **Client disconnect** → Send StopWorkflow request → Wait for acknowledgment

### Stream manager

The `streamManager` manages gRPC streams to the Duo Workflow Service:

```go
type streamManager struct {
    wf                 workflowStream
    client             *Client
    cloudServiceClient *Client
    cloudServiceStream selfHostedWorkflowStream
    originalReq        *http.Request
    sendMu             sync.Mutex
}
```

**Responsibilities:**

- Opens and owns the primary `ExecuteWorkflow` gRPC stream
- Optionally opens a secondary `TrackSelfHostedExecuteWorkflow` stream for self-hosted deployments
- Provides mutex-protected `Send` to allow concurrent goroutines to write safely
- Translates `io.EOF` and quota-exceeded gRPC errors into sentinel errors on `Recv`

### Action handlers

#### HTTP request execution

The `runHTTPActionHandler` executes HTTP requests to the GitLab API:

```go
type runHTTPActionHandler struct {
    rails       *api.API
    backend     http.Handler
    token       string
    originalReq *http.Request
    action      *pb.Action
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

- Initializes connections to configured MCP servers
- Discovers available tools from each server
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
2. Release the lock when workflow ends
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

The package exposes six Prometheus counters, one gauge and one histogram.

### `gitlab_workhorse_duo_workflow_connections_total`

Incremented for every inbound request that passes pre-authorization, labeled by `transport`, which is `websocket` for the WebSocket endpoint and `http` for server-side execution. On the WebSocket transport the counter is incremented before the upgrade is attempted, so it includes requests that subsequently fail to upgrade.

### `gitlab_workhorse_duo_workflow_connections_open`

The number of runners currently executing, labeled by `transport`, incremented when a runner is registered and decremented when it is torn down.

Connections stay open for hours, so concurrency cannot be derived from `connections_total` alone. `gitlab_workhorse_http_in_flight_requests` is not a substitute: it is unlabelled, so it cannot be narrowed to this route, and it also counts the HTTP actions that re-enter the upstream router while the connection is still open.

Use it to normalise process memory per connection. Sum over `transport` first, because a WebSocket connection and a server-side run cost different amounts and mixing them makes the ratio meaningless on its own:

```promql
go_memstats_heap_inuse_bytes{job=~"gitlab-workhorse.*"}
  / on(instance) sum without(transport) (gitlab_workhorse_duo_workflow_connections_open)
```

### `gitlab_workhorse_duo_workflow_connection_errors_total`

Incremented whenever a connection fails at any stage, labeled by `transport` (`websocket`, `http`) and `error_type`:

| Stage                 | Trigger                                                              | `error_type`     |
| --------------------- | -------------------------------------------------------------------- | ---------------- |
| WebSocket upgrade     | `websocket.Upgrader.Upgrade` returns an error                        | `other`          |
| Request body          | Start request body cannot be read or decoded (`http` transport only) | `other`          |
| Runner initialisation | `newRunner` / `newStreamManager` returns an error                    | `other`          |
| Runner execution      | Usage quota exceeded                                                 | `quota_exceeded` |
| Runner execution      | Workflow lock cannot be acquired                                     | `locked`         |
| Runner execution      | Any other `runner.Execute` error                                     | `other`          |

The ratio `connection_errors_total / connections_total` gives the connection error rate.

Example query to break down errors by transport and type:

```promql
sum(rate(gitlab_workhorse_duo_workflow_connection_errors_total[5m])) by (transport, error_type)
```

### `gitlab_workhorse_duo_workflow_sessions_total`

Incremented each time a gRPC `ExecuteWorkflow` stream is successfully opened to the Duo Workflow Service (inside `newStreamManager`).

### `gitlab_workhorse_duo_workflow_session_errors_total`

Incremented for every non-EOF error received on the `ExecuteWorkflow` stream, labelled by the gRPC status code string (e.g. `"Internal"`, `"Unavailable"`, `"ResourceExhausted"`). `io.EOF` is the normal end-of-stream signal and does not increment this counter.

Example query:

```promql
sum(rate(gitlab_workhorse_duo_workflow_session_errors_total[5m])) by (grpc_code)
```

### `gitlab_workhorse_duo_workflow_http_actions_total`

Incremented once for every HTTP action executed on behalf of the Duo Workflow Service (in `runHTTPActionHandler.Execute`), labelled by `method` and `status_code`.

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

## Configuration

### From GitLab Rails

Workhorse receives configuration during pre-authorization:

```go
type DuoWorkflow struct {
    Service                  *DuoWorkflowServiceConfig // Primary gRPC service
    CloudServiceForSelfHosted *DuoWorkflowServiceConfig // Optional cloud tracking service
    LockConcurrentFlow       bool                      // Enable workflow locking
    McpServers               map[string]*McpServerConfig
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
    Tools: ["tool1", "tool2"], # Empty means all tools
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
