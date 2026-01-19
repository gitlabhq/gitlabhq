# Duo Workflow Package

This package implements Workhorse's support for AI-assisted features through integration with the Duo Workflow Service. It provides WebSocket proxying, gRPC communication, and action handling for AI workflows.

## Overview

The `duoworkflow` package enables GitLab's AI-assisted features (Duo Chat, Duo Agent) by:

1. Managing WebSocket connections between clients and Workhorse
2. Establishing gRPC streams to the Duo Workflow Service
3. Handling bidirectional message exchange
4. Executing actions (HTTP requests, MCP tool calls) on behalf of the Duo Workflow Service
5. Supporting various deployment scenarios (GitLab.com, self-managed, restricted networks)

## Package structure

- **handler.go**: HTTP handler for WebSocket connections and graceful shutdown management
- **client.go**: gRPC client for communicating with the Duo Workflow Service
- **runner.go**: Main orchestrator that manages the lifecycle of a single workflow execution
- **actions.go**: Handlers for executing actions from the Duo Workflow Service
- **mcp.go**: Model Context Protocol (MCP) client for tool execution
- **lock.go**: Distributed workflow locking using Redis

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

### Runner

The `runner` orchestrates a single workflow execution:

```go
type runner struct {
    rails       *api.API
    backend     http.Handler
    token       string
    originalReq *http.Request
    conn        websocketConn
    wf          workflowStream
    client      *Client
    mcpManager  mcpManager
    lockManager *workflowLockManager
    workflowID  string
    mutex       *redsync.Mutex
    lockFlow    bool
}
```

**Responsibilities:**
- Handles WebSocket messages from clients
- Handles gRPC actions from the Duo Workflow Service
- Manages message serialization/deserialization
- Coordinates HTTP request execution and MCP tool calls
- Manages workflow lifecycle and graceful shutdown

**Message handling flow:**

1. **WebSocket messages** → Unmarshal to Protocol Buffer → Send to gRPC stream
2. **gRPC actions** → Process action type → Execute action → Send response back to gRPC stream
3. **WebSocket closure** → Send StopWorkflow request → Wait for acknowledgment

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
    Tools() []*pb.MCPTool
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
Send to gRPC stream (threadSafeSend)
    ↓
Duo Workflow Service receives ClientEvent
```

### Duo Workflow Service to Client

```
gRPC Action received
    ↓
Determine action type
    ↓
Execute action (HTTP request or MCP tool)
    ↓
Create ActionResponse
    ↓
Send to gRPC stream (threadSafeSend)
    ↓
Receive response in gRPC stream
    ↓
Marshal to JSON
    ↓
Send to WebSocket
    ↓
Client receives action response
```

## Configuration

### From GitLab Rails

Workhorse receives configuration during pre-authorization:

```go
type DuoWorkflow struct {
    ServiceURI        string            // gRPC service URI (e.g., "localhost:50052")
    Headers           map[string]string // Headers for gRPC requests (e.g., OAuth token)
    Secure            bool              // Use TLS for gRPC connection
    McpServers        map[string]interface{} // MCP server configurations
    LockConcurrentFlow bool             // Enable workflow locking
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

### Unit tests

Test files are located in the same directory:

- `handler_test.go`: WebSocket connection handling and pre-authorization
- `client_test.go`: gRPC client creation and connection management
- `runner_test.go`: Message handling and workflow execution
- `actions_test.go`: HTTP request execution and response handling
- `mcp_test.go`: MCP server communication
- `lock_test.go`: Distributed workflow locking

### Running tests

```bash
# Run all tests in the package
go test ./internal/ai_assist/duoworkflow -v
```

## Constants and limits

- **MaxMessageSize**: 4MB - Maximum size of gRPC messages
- **ActionResponseBodyLimit**: ~4MB - Maximum response body size
- **wsWriteDeadline**: 60 seconds - WebSocket write timeout
- **wsCloseTimeout**: 5 seconds - WebSocket close timeout
- **wsStopWorkflowTimeout**: 10 seconds - Workflow stop request timeout
- **gRPC keepalive time**: 20 seconds - Keepalive ping interval
- **gRPC retry attempts**: 4 - Maximum retry attempts for failed requests


## Related documentation

- [AI-assisted features architecture](../../doc/development/workhorse/ai_assisted_features_architecture.md)
- [Workhorse development guide](https://docs.gitlab.com/ee/development/workhorse/)
- [Duo Workflow Service](https://gitlab.com/gitlab-org/modelops/applied-ml/code-suggestions/ai-assist)
- [Model Context Protocol (MCP)](https://modelcontextprotocol.io/)
