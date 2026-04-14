package duoworkflow

import (
	"bytes"
	"context"
	"encoding/json"
	"errors"
	"fmt"
	"io"
	"net"
	"net/http"
	"reflect"
	"slices"
	"strings"

	"gitlab.com/gitlab-org/gitlab/workhorse/internal/api"
	"gitlab.com/gitlab-org/gitlab/workhorse/internal/headers"
	"gitlab.com/gitlab-org/gitlab/workhorse/internal/log"
	"gitlab.com/gitlab-org/gitlab/workhorse/internal/orbit"
	"gitlab.com/gitlab-org/gitlab/workhorse/internal/transport"

	pb "gitlab.com/gitlab-org/modelops/applied-ml/code-suggestions/ai-assist/clients/gopb/contract"

	"github.com/modelcontextprotocol/go-sdk/mcp"
	"google.golang.org/protobuf/proto"
)

const gitlabServerName = "gitlab"
const orbitServerName = "orbit"

type serverSession struct {
	name    string
	cfg     api.McpServerConfig
	session *mcp.ClientSession
}

type toolSession struct {
	originalName string
	session      *mcp.ClientSession
}

type mcpManager interface {
	HasTool(string) bool
	CallTool(context.Context, *pb.Action) (*pb.ClientEvent, error)
	Tools() []*pb.McpTool
	PreApprovedTools() []string
	Close() error
}

type manager struct {
	tools              []*pb.McpTool
	preApprovedTools   []string
	toolSessionsByName map[string]*toolSession
	serverSessions     []*serverSession
}

type roundTripper struct {
	serverName  string
	next        http.RoundTripper
	headers     map[string]string
	originalReq *http.Request
	rails       *api.API
}

type responseCapture struct {
	statusCode int
	headers    http.Header
	body       bytes.Buffer
}

func (rc *responseCapture) Header() http.Header         { return rc.headers }
func (rc *responseCapture) Write(b []byte) (int, error) { return rc.body.Write(b) }
func (rc *responseCapture) WriteHeader(statusCode int)  { rc.statusCode = statusCode }

func (rc *responseCapture) toResponse() *http.Response {
	return &http.Response{
		StatusCode: rc.statusCode,
		Header:     rc.headers,
		Body:       io.NopCloser(&rc.body),
	}
}

type limitedReadCloser struct {
	io.LimitedReader
	closer io.Closer
}

func (lrc *limitedReadCloser) Close() error {
	return lrc.closer.Close()
}

func (t *roundTripper) RoundTrip(r *http.Request) (*http.Response, error) {
	for name, value := range t.headers {
		r.Header.Set(name, value)
	}
	r.Header.Set("User-Agent", "GitLab-Workhorse-Mcp-Client")

	if t.originalReq != nil {
		if clientIP, _, splitHostErr := net.SplitHostPort(t.originalReq.RemoteAddr); splitHostErr == nil {
			var header string
			if prior, ok := t.originalReq.Header["X-Forwarded-For"]; ok {
				header = strings.Join(prior, ", ") + ", " + clientIP
			} else {
				header = clientIP
			}
			r.Header.Set("X-Forwarded-For", header)
		}
	}

	resp, err := t.next.RoundTrip(r)
	if err != nil {
		return resp, err
	}

	// Orbit MCP tool calls return a Gitlab-Workhorse-Send-Data header that
	// triggers gRPC streaming to GKG. Process it inline since this transport
	// bypasses the normal senddata middleware.
	if t.serverName == orbitServerName {
		if sendData := resp.Header.Get(headers.GitlabWorkhorseSendDataHeader); sendData != "" {
			sq := orbit.NewSendQuery(t.rails, t.rails.Version)
			if sq.Match(sendData) {
				if resp.Body != nil {
					_, _ = io.Copy(io.Discard, resp.Body)
					_ = resp.Body.Close()
				}
				rc := &responseCapture{statusCode: http.StatusOK, headers: make(http.Header)}
				sq.Inject(rc, r, sendData)
				return rc.toResponse(), nil
			}
		}
	}

	if resp.Body != nil {
		resp.Body = &limitedReadCloser{
			LimitedReader: io.LimitedReader{
				R: resp.Body,
				N: ActionResponseBodyLimit,
			},
			closer: resp.Body,
		}
	}

	return resp, err
}

func newMcpManager(rails *api.API, r *http.Request, servers map[string]api.McpServerConfig) (*manager, error) {
	if len(servers) == 0 {
		return nil, fmt.Errorf("the list of server configs is empty")
	}

	var errs []error
	var sessions []*serverSession

	for serverName, serverCfg := range servers {
		session, err := buildSession(rails, r, serverName, serverCfg)
		if err != nil {
			errs = append(errs, fmt.Errorf("failed to initialize MCP session %s: %v", serverName, err))
			continue
		}

		sessions = append(sessions, session)
	}

	manager := &manager{
		toolSessionsByName: make(map[string]*toolSession),
		serverSessions:     sessions,
	}

	if err := manager.buildTools(r.Context()); err != nil {
		errs = append(errs, err)
	}

	return manager, errors.Join(errs...)
}

func buildSession(rails *api.API, r *http.Request, serverName string, serverCfg api.McpServerConfig) (*serverSession, error) {
	client := mcp.NewClient(&mcp.Implementation{Name: "mcp-client", Version: "v1.0.0"}, nil)

	var t *mcp.StreamableClientTransport

	var endpoint string
	var nextTransport http.RoundTripper

	internalPaths := map[string]string{
		gitlabServerName: "api/v4/mcp",
		orbitServerName:  "api/v4/orbit/mcp",
	}

	if path, ok := internalPaths[serverName]; ok {
		endpoint = rails.URL.JoinPath(path).String()
		nextTransport = rails.Client.Transport
	} else {
		endpoint = serverCfg.URL
		nextTransport = transport.NewRestrictedTransport()
	}

	rt := &roundTripper{
		serverName:  serverName,
		next:        nextTransport,
		headers:     serverCfg.Headers,
		originalReq: r,
	}
	if serverName == orbitServerName {
		rt.rails = rails
	}

	t = &mcp.StreamableClientTransport{
		Endpoint:   endpoint,
		HTTPClient: &http.Client{Transport: rt},
		// DisableStandaloneSSE must be true because the GitLab MCP server does not support
		// SSE (Server-Sent Events). Without this flag, the client attempts an SSE connection
		// first, which fails and breaks the connection flow.
		// See: https://github.com/modelcontextprotocol/go-sdk/pull/729
		DisableStandaloneSSE: true,
	}

	session, err := client.Connect(r.Context(), t, nil)
	if err != nil {
		return nil, err
	}

	return &serverSession{name: serverName, cfg: serverCfg, session: session}, err
}

func (m *manager) buildTools(ctx context.Context) error {
	var errs []error

	for _, s := range m.serverSessions {
		toolsResult, err := s.session.ListTools(ctx, &mcp.ListToolsParams{})
		if err != nil {
			errs = append(errs, fmt.Errorf("failed to list tools %s: %v", s.name, err))
			continue
		}

		// If s.cfg.Tools is missing (nil), then all tools are available
		// Otherwise, we filter the list of tools based on the provided value
		allToolsAvailable := true
		var configuredTools []string
		if s.cfg.Tools != nil {
			allToolsAvailable = false
			configuredTools = *s.cfg.Tools
		}

		var preApprovedTools []string
		if s.cfg.PreApprovedTools != nil {
			preApprovedTools = *s.cfg.PreApprovedTools
		}

		for _, tool := range toolsResult.Tools {
			schemaBytes, err := json.Marshal(tool.InputSchema)
			if err != nil {
				errs = append(errs, fmt.Errorf("failed to marshal input schema, server: %s, tool: %s, error: %v", s.name, tool.Name, err))
				continue
			}

			if allToolsAvailable || slices.Contains(configuredTools, tool.Name) {
				prefixedName := s.name + "_" + tool.Name

				mcpTool := &pb.McpTool{
					Name:        prefixedName,
					Description: tool.Description,
					InputSchema: string(schemaBytes),
					Trusted:     proto.Bool(s.cfg.Trusted),
				}

				m.tools = append(m.tools, mcpTool)

				m.toolSessionsByName[prefixedName] = &toolSession{
					originalName: tool.Name,
					session:      s.session,
				}

				if slices.Contains(preApprovedTools, tool.Name) {
					m.preApprovedTools = append(m.preApprovedTools, prefixedName)
				}
			}
		}
	}

	return errors.Join(errs...)
}

func (m *manager) HasTool(name string) bool {
	if m == nil {
		return false
	}

	_, ok := m.toolSessionsByName[name]
	return ok
}

func (m *manager) Tools() []*pb.McpTool {
	if m == nil {
		return nil
	}

	return m.tools
}

func (m *manager) PreApprovedTools() []string {
	if m == nil {
		return nil
	}

	return m.preApprovedTools
}

func (m *manager) CallTool(ctx context.Context, action *pb.Action) (*pb.ClientEvent, error) {
	mcpTool := action.GetRunMCPTool()

	log.WithContextFields(ctx, log.Fields{
		"name":       mcpTool.Name,
		"args_size":  len(mcpTool.Args),
		"request_id": action.RequestID,
	}).Info("Calling an MCP tool")

	toolSession, ok := m.toolSessionsByName[mcpTool.Name]
	if !ok {
		return nil, fmt.Errorf("CallTool: unknown tool: %v", mcpTool.Name)
	}

	var arguments map[string]any
	if err := json.Unmarshal([]byte(mcpTool.Args), &arguments); err != nil {
		return nil, fmt.Errorf("CallTool: failed to unmarshal MCP args: %v", err)
	}
	params := &mcp.CallToolParams{
		Name:      toolSession.originalName,
		Arguments: arguments,
	}

	res, err := toolSession.session.CallTool(ctx, params)
	if err != nil {
		return nil, fmt.Errorf("CallTool: failed to call MCP tool: %v", err)
	}

	event := m.buildClientEvent(ctx, action, mcpTool, res)

	log.WithContextFields(ctx, log.Fields{
		"request_id":           action.GetRequestID(),
		"name":                 mcpTool.Name,
		"args_size":            len(action.GetRunMCPTool().Args),
		"payload_size":         proto.Size(event),
		"event_type":           fmt.Sprintf("%T", event.Response),
		"action_response_type": fmt.Sprintf("%T", event.GetActionResponse().GetResponseType()),
	}).Info("Sending MCP tool response")

	return event, nil
}

func (m *manager) buildClientEvent(ctx context.Context, action *pb.Action, mcpTool *pb.RunMCPTool, res *mcp.CallToolResult) *pb.ClientEvent {
	var content string
	if len(res.Content) == 0 {
		content = "MCP tool response is empty"
	} else {
		if textContent, ok := res.Content[0].(*mcp.TextContent); ok {
			content = textContent.Text
		} else {
			log.WithContextFields(ctx, log.Fields{
				"name":         mcpTool.Name,
				"request_id":   action.RequestID,
				"content_type": reflect.TypeOf(res.Content[0]).String(),
			}).Info("MCP tool response content type not supported")
			content = "MCP tool response content type not supported"
		}
	}

	response := &pb.PlainTextResponse{}
	if res.IsError {
		response.Error = content
	} else {
		response.Response = content
	}

	return &pb.ClientEvent{
		Response: &pb.ClientEvent_ActionResponse{
			ActionResponse: &pb.ActionResponse{
				RequestID: action.RequestID,
				ResponseType: &pb.ActionResponse_PlainTextResponse{
					PlainTextResponse: response,
				},
			},
		},
	}
}

func (m *manager) Close() error {
	if m == nil {
		return nil
	}

	var errs []error
	for _, s := range m.serverSessions {
		errs = append(errs, s.session.Close())
	}

	return errors.Join(errs...)
}
