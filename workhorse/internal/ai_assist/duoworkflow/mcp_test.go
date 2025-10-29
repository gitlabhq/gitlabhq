package duoworkflow

import (
	"context"
	"encoding/json"
	"io"
	"net/http"
	"net/http/httptest"
	"net/url"
	"strings"
	"testing"

	"github.com/stretchr/testify/assert"
	"github.com/stretchr/testify/require"

	pb "gitlab.com/gitlab-org/modelops/applied-ml/code-suggestions/ai-assist/clients/gopb/contract"

	"gitlab.com/gitlab-org/gitlab/workhorse/internal/api"
)

func TestRoundTripper_RoundTrip(t *testing.T) {
	t.Run("adds custom headers", func(t *testing.T) {
		var capturedRequest *http.Request
		var transportFunc = func(req *http.Request) (*http.Response, error) {
			capturedRequest = req
			return &http.Response{
				StatusCode: 200,
				Body:       http.NoBody,
				Header:     make(http.Header),
			}, nil
		}

		rt := &roundTripper{
			next: &mockTransportFunc{fn: transportFunc},
			headers: map[string]string{
				"Authorization":   "Bearer test-token",
				"X-Custom-Header": "custom-value",
			},
		}

		req := httptest.NewRequest("GET", "http://example.com", nil)
		r, err := rt.RoundTrip(req)
		require.NoError(t, err)
		require.NoError(t, r.Body.Close())

		require.NotNil(t, capturedRequest)
		assert.Equal(t, "Bearer test-token", capturedRequest.Header.Get("Authorization"))
		assert.Equal(t, "custom-value", capturedRequest.Header.Get("X-Custom-Header"))
		assert.Equal(t, "GitLab-Workhorse-Mcp-Client", capturedRequest.Header.Get("User-Agent"))
	})

	t.Run("sets X-Forwarded-For from original request", func(t *testing.T) {
		var capturedRequest *http.Request
		var transportFunc = func(req *http.Request) (*http.Response, error) {
			capturedRequest = req
			return &http.Response{
				StatusCode: 200,
				Body:       http.NoBody,
				Header:     make(http.Header),
			}, nil
		}

		originalReq := httptest.NewRequest("GET", "/test", nil)
		originalReq.RemoteAddr = "192.0.2.1:1234"

		rt := &roundTripper{
			next:        &mockTransportFunc{fn: transportFunc},
			headers:     map[string]string{},
			originalReq: originalReq,
		}

		req := httptest.NewRequest("GET", "http://example.com", nil)
		r, err := rt.RoundTrip(req)
		require.NoError(t, err)
		require.NoError(t, r.Body.Close())

		require.NotNil(t, capturedRequest)
		assert.Equal(t, "192.0.2.1", capturedRequest.Header.Get("X-Forwarded-For"))
	})

	t.Run("appends to existing X-Forwarded-For", func(t *testing.T) {
		var capturedRequest *http.Request
		var transportFunc = func(req *http.Request) (*http.Response, error) {
			capturedRequest = req
			return &http.Response{
				StatusCode: 200,
				Body:       http.NoBody,
				Header:     make(http.Header),
			}, nil
		}

		originalReq := httptest.NewRequest("GET", "/test", nil)
		originalReq.RemoteAddr = "192.0.2.1:1234"
		originalReq.Header.Set("X-Forwarded-For", "10.0.0.1")

		rt := &roundTripper{
			next:        &mockTransportFunc{fn: transportFunc},
			headers:     map[string]string{},
			originalReq: originalReq,
		}

		req := httptest.NewRequest("GET", "http://example.com", nil)
		r, err := rt.RoundTrip(req)
		require.NoError(t, err)
		require.NoError(t, r.Body.Close())

		require.NotNil(t, capturedRequest)
		assert.Equal(t, "10.0.0.1, 192.0.2.1", capturedRequest.Header.Get("X-Forwarded-For"))
	})

	t.Run("handles invalid RemoteAddr gracefully", func(t *testing.T) {
		var capturedRequest *http.Request
		var transportFunc = func(req *http.Request) (*http.Response, error) {
			capturedRequest = req
			return &http.Response{
				StatusCode: 200,
				Body:       http.NoBody,
				Header:     make(http.Header),
			}, nil
		}

		originalReq := httptest.NewRequest("GET", "/test", nil)
		originalReq.RemoteAddr = "invalid-address"

		rt := &roundTripper{
			next:        &mockTransportFunc{fn: transportFunc},
			headers:     map[string]string{},
			originalReq: originalReq,
		}

		req := httptest.NewRequest("GET", "http://example.com", nil)
		r, err := rt.RoundTrip(req)
		require.NoError(t, err)
		require.NoError(t, r.Body.Close())

		require.NotNil(t, capturedRequest)
		assert.Empty(t, capturedRequest.Header.Get("X-Forwarded-For"))
	})

	t.Run("wraps response body with limited reader", func(t *testing.T) {
		responseBody := "This is a test response body that should be limited"
		var transportFunc = func(_ *http.Request) (*http.Response, error) {
			return &http.Response{
				StatusCode: 200,
				Body:       io.NopCloser(strings.NewReader(responseBody)),
				Header:     make(http.Header),
			}, nil
		}

		rt := &roundTripper{
			next:    &mockTransportFunc{fn: transportFunc},
			headers: map[string]string{},
		}

		req := httptest.NewRequest("GET", "http://example.com", nil)
		resp, err := rt.RoundTrip(req)
		require.NoError(t, err)
		require.NotNil(t, resp)
		defer resp.Body.Close()

		_, ok := resp.Body.(*limitedReadCloser)
		require.True(t, ok, "Response body should be wrapped with limitedReadCloser")

		body, err := io.ReadAll(resp.Body)
		require.NoError(t, err)
		assert.Equal(t, responseBody, string(body))
	})

	t.Run("limits response body to ActionResponseBodyLimit", func(t *testing.T) {
		largeBody := strings.Repeat("x", ActionResponseBodyLimit+1000)
		var transportFunc = func(_ *http.Request) (*http.Response, error) {
			return &http.Response{
				StatusCode: 200,
				Body:       io.NopCloser(strings.NewReader(largeBody)),
				Header:     make(http.Header),
			}, nil
		}

		rt := &roundTripper{
			next:    &mockTransportFunc{fn: transportFunc},
			headers: map[string]string{},
		}

		req := httptest.NewRequest("GET", "http://example.com", nil)
		resp, err := rt.RoundTrip(req)
		require.NoError(t, err)
		require.NotNil(t, resp)
		defer resp.Body.Close()

		body, err := io.ReadAll(resp.Body)
		require.NoError(t, err)
		assert.Len(t, body, ActionResponseBodyLimit)
		assert.Equal(t, strings.Repeat("x", ActionResponseBodyLimit), string(body))
	})
}

func TestNewMcpManager(t *testing.T) {
	t.Run("successful initialization with single server", func(t *testing.T) {
		mcpServer := setupMockMcpServer(t, "", []mcpTool{
			{Name: "test_tool", Description: "A test tool"},
		})

		req := httptest.NewRequest("GET", "/test", nil)

		servers := map[string]api.McpServerConfig{
			"test-server": {
				URL:     mcpServer.URL,
				Headers: map[string]string{},
				Tools:   &([]string{"test_tool"}),
			},
		}

		mgr, err := newMcpManager(nil, req, servers)

		require.NoError(t, err)
		require.NotNil(t, mgr)
		assert.Len(t, mgr.tools, 1)
		assert.Equal(t, "test-server_test_tool", mgr.tools[0].Name)
		assert.Len(t, mgr.toolSessionsByName, 1)
		assert.Len(t, mgr.serverSessions, 1)
	})

	t.Run("successful initialization with multiple servers", func(t *testing.T) {
		mcpServer1 := setupMockMcpServer(t, "", []mcpTool{
			{Name: "tool1", Description: "Tool 1"},
		})
		mcpServer2 := setupMockMcpServer(t, "", []mcpTool{
			{Name: "tool2", Description: "Tool 2"},
		})

		req := httptest.NewRequest("GET", "/test", nil)

		servers := map[string]api.McpServerConfig{
			"server1": {
				URL:     mcpServer1.URL,
				Headers: map[string]string{},
				Tools:   &([]string{"tool1"}),
			},
			"server2": {
				URL:     mcpServer2.URL,
				Headers: map[string]string{},
				Tools:   &([]string{"tool2"}),
			},
		}

		mgr, err := newMcpManager(nil, req, servers)

		require.NoError(t, err)
		require.NotNil(t, mgr)
		assert.Len(t, mgr.tools, 2)
		assert.Len(t, mgr.toolSessionsByName, 2)
		assert.Len(t, mgr.serverSessions, 2)
	})

	t.Run("filters tools based on config", func(t *testing.T) {
		mcpServer := setupMockMcpServer(t, "", []mcpTool{
			{Name: "allowed_tool", Description: "Allowed tool"},
			{Name: "blocked_tool", Description: "Blocked tool"},
		})

		req := httptest.NewRequest("GET", "/test", nil)

		servers := map[string]api.McpServerConfig{
			"test-server": {
				URL:     mcpServer.URL,
				Headers: map[string]string{},
				Tools:   &([]string{"allowed_tool"}),
			},
		}

		mgr, err := newMcpManager(nil, req, servers)

		require.NoError(t, err)
		require.NotNil(t, mgr)
		assert.Len(t, mgr.tools, 1)
		assert.Equal(t, "test-server_allowed_tool", mgr.tools[0].Name)
	})

	t.Run("includes all tools when Tools config is empty", func(t *testing.T) {
		mcpServer := setupMockMcpServer(t, "", []mcpTool{
			{Name: "tool1", Description: "Tool 1"},
			{Name: "tool2", Description: "Tool 2"},
		})

		req := httptest.NewRequest("GET", "/test", nil)

		servers := map[string]api.McpServerConfig{
			"test-server": {
				URL:     mcpServer.URL,
				Headers: map[string]string{},
			},
		}

		mgr, err := newMcpManager(nil, req, servers)

		require.NoError(t, err)
		require.NotNil(t, mgr)
		assert.Len(t, mgr.tools, 2)
	})

	t.Run("filters all tools when Tools config is empty", func(t *testing.T) {
		mcpServer := setupMockMcpServer(t, "gitlab", []mcpTool{
			{Name: "tool1", Description: "Tool 1"},
			{Name: "tool2", Description: "Tool 2"},
		})

		apiURL, err := url.Parse(mcpServer.URL)
		require.NoError(t, err)

		rails := api.NewAPI(apiURL, "test-version", http.DefaultTransport)
		req := httptest.NewRequest("GET", "/test", nil)

		servers := map[string]api.McpServerConfig{
			"gitlab": {
				URL:     mcpServer.URL,
				Headers: map[string]string{},
				Tools:   &([]string{}),
			},
		}

		mgr, err := newMcpManager(rails, req, servers)

		require.NoError(t, err)
		require.NotNil(t, mgr)
		assert.Empty(t, mgr.tools)
	})

	t.Run("returns error when servers map is empty", func(t *testing.T) {
		req := httptest.NewRequest("GET", "/test", nil)

		servers := map[string]api.McpServerConfig{}

		mgr, err := newMcpManager(nil, req, servers)

		require.Error(t, err)
		require.Nil(t, mgr)
		assert.Contains(t, err.Error(), "the list of server configs is empty")
	})

	t.Run("continues with partial success when one server fails", func(t *testing.T) {
		mcpServer := setupMockMcpServer(t, "", []mcpTool{
			{Name: "tool1", Description: "Tool 1"},
		})

		req := httptest.NewRequest("GET", "/test", nil)

		servers := map[string]api.McpServerConfig{
			"good-server": {
				URL:     mcpServer.URL,
				Headers: map[string]string{},
				Tools:   &([]string{"tool1"}),
			},
			"bad-server": {
				URL:     "http://localhost:1", // Use a port that's likely to be refused
				Headers: map[string]string{},
				Tools:   &([]string{"tool2"}),
			},
		}

		mgr, err := newMcpManager(nil, req, servers)

		require.Error(t, err)
		require.NotNil(t, mgr)
		assert.Len(t, mgr.tools, 1)
		assert.Contains(t, err.Error(), "failed to initialize MCP session bad-server")
	})
}

func TestManager_HasTool(t *testing.T) {
	t.Run("returns true for existing tool", func(t *testing.T) {
		mgr := &manager{
			toolSessionsByName: map[string]*toolSession{
				"test_tool": {},
			},
		}

		assert.True(t, mgr.HasTool("test_tool"))
	})

	t.Run("returns false for non-existing tool", func(t *testing.T) {
		mgr := &manager{
			toolSessionsByName: map[string]*toolSession{
				"test_tool": {},
			},
		}

		assert.False(t, mgr.HasTool("other_tool"))
	})

	t.Run("returns false when manager is nil", func(t *testing.T) {
		var mgr *manager
		assert.False(t, mgr.HasTool("test_tool"))
	})
}

func TestManager_Tools(t *testing.T) {
	t.Run("returns tools list", func(t *testing.T) {
		tools := []*pb.McpTool{
			{Name: "tool1", Description: "Tool 1"},
			{Name: "tool2", Description: "Tool 2"},
		}

		mgr := &manager{
			tools: tools,
		}

		result := mgr.Tools()
		assert.Equal(t, tools, result)
		assert.Len(t, result, 2)
	})

	t.Run("returns nil when manager is nil", func(t *testing.T) {
		var mgr *manager
		assert.Nil(t, mgr.Tools())
	})

	t.Run("returns empty list when no tools", func(t *testing.T) {
		mgr := &manager{
			tools: []*pb.McpTool{},
		}

		result := mgr.Tools()
		assert.NotNil(t, result)
		assert.Empty(t, result)
	})
}

func TestManager_CallTool(t *testing.T) {
	t.Run("successfully calls tool with valid arguments", func(t *testing.T) {
		mcpServer := setupMockMcpServerWithCallHandler(t, "", []mcpTool{
			{Name: "test_tool", Description: "A test tool"},
		}, func(name string, args map[string]any) (string, bool, error) {
			assert.Equal(t, "test_tool", name)
			assert.Equal(t, "123", args["issue_id"])
			return `{"id": 123, "title": "Test Issue"}`, false, nil
		})

		req := httptest.NewRequest("GET", "/test", nil)

		servers := map[string]api.McpServerConfig{
			"test-server": {
				URL:     mcpServer.URL,
				Headers: map[string]string{},
			},
		}

		mgr, err := newMcpManager(nil, req, servers)
		require.NoError(t, err)

		action := &pb.Action{
			RequestID: "req-mcp-123",
			Action: &pb.Action_RunMCPTool{
				RunMCPTool: &pb.RunMCPTool{
					Name: "test-server_test_tool",
					Args: `{"issue_id": "123"}`,
				},
			},
		}

		result, err := mgr.CallTool(context.Background(), action)

		require.NoError(t, err)
		require.NotNil(t, result)
		plainTextResp := result.GetActionResponse().GetPlainTextResponse()
		assert.Contains(t, plainTextResp.Response, "Test Issue")
		assert.Empty(t, plainTextResp.Error)
	})

	t.Run("returns error for unknown tool", func(t *testing.T) {
		mgr := &manager{
			toolSessionsByName: map[string]*toolSession{},
		}

		action := &pb.Action{
			RequestID: "req-mcp-123",
			Action: &pb.Action_RunMCPTool{
				RunMCPTool: &pb.RunMCPTool{
					Name: "unknown_tool",
					Args: `{}`,
				},
			},
		}

		result, err := mgr.CallTool(context.Background(), action)

		require.Error(t, err)
		require.Nil(t, result)
		assert.Contains(t, err.Error(), "unknown tool")
	})

	t.Run("returns error for invalid JSON arguments", func(t *testing.T) {
		mgr := &manager{
			toolSessionsByName: map[string]*toolSession{
				"test_tool": {},
			},
		}

		action := &pb.Action{
			RequestID: "req-mcp-123",
			Action: &pb.Action_RunMCPTool{
				RunMCPTool: &pb.RunMCPTool{
					Name: "test_tool",
					Args: `invalid json`,
				},
			},
		}

		result, err := mgr.CallTool(context.Background(), action)

		require.Error(t, err)
		require.Nil(t, result)
		assert.Contains(t, err.Error(), "failed to unmarshal MCP args")
	})

	t.Run("handles MCP error response", func(t *testing.T) {
		mcpServer := setupMockMcpServerWithCallHandler(t, "", []mcpTool{
			{Name: "test_tool", Description: "A test tool"},
		}, func(_ string, _ map[string]any) (string, bool, error) {
			return "Tool execution failed", true, nil
		})

		req := httptest.NewRequest("GET", "/test", nil)

		servers := map[string]api.McpServerConfig{
			"test-server": {
				URL:     mcpServer.URL,
				Headers: map[string]string{},
			},
		}

		mgr, err := newMcpManager(nil, req, servers)
		require.NoError(t, err)

		action := &pb.Action{
			RequestID: "req-mcp-123",
			Action: &pb.Action_RunMCPTool{
				RunMCPTool: &pb.RunMCPTool{
					Name: "test-server_test_tool",
					Args: `{}`,
				},
			},
		}

		result, err := mgr.CallTool(context.Background(), action)

		require.NoError(t, err)
		require.NotNil(t, result)
		plainTextResp := result.GetActionResponse().GetPlainTextResponse()
		assert.Equal(t, "Tool execution failed", plainTextResp.Error)
		assert.Empty(t, plainTextResp.Response)
	})

	t.Run("handles empty MCP response", func(t *testing.T) {
		mcpServer := setupMockMcpServerWithCallHandler(t, "", []mcpTool{
			{Name: "test_tool", Description: "A test tool"},
		}, func(_ string, _ map[string]any) (string, bool, error) {
			return "", false, nil
		})

		req := httptest.NewRequest("GET", "/test", nil)

		servers := map[string]api.McpServerConfig{
			"test-server": {
				URL:     mcpServer.URL,
				Headers: map[string]string{},
			},
		}

		mgr, err := newMcpManager(nil, req, servers)
		require.NoError(t, err)

		action := &pb.Action{
			RequestID: "req-mcp-123",
			Action: &pb.Action_RunMCPTool{
				RunMCPTool: &pb.RunMCPTool{
					Name: "test-server_test_tool",
					Args: `{}`,
				},
			},
		}

		result, err := mgr.CallTool(context.Background(), action)

		require.NoError(t, err)
		require.NotNil(t, result)
		plainTextResp := result.GetActionResponse().GetPlainTextResponse()
		assert.Equal(t, "MCP tool response is empty", plainTextResp.Response)
	})
}

func TestManager_Close(t *testing.T) {
	t.Run("closes all sessions successfully", func(t *testing.T) {
		mcpServer := setupMockMcpServer(t, "", []mcpTool{
			{Name: "test_tool", Description: "A test tool"},
		})

		req := httptest.NewRequest("GET", "/test", nil)

		servers := map[string]api.McpServerConfig{
			"test-server": {
				URL:     mcpServer.URL,
				Headers: map[string]string{},
			},
		}

		mgr, err := newMcpManager(nil, req, servers)
		require.NoError(t, err)

		err = mgr.Close()
		assert.NoError(t, err)
	})

	t.Run("returns nil when manager is nil", func(t *testing.T) {
		var mgr *manager
		err := mgr.Close()
		assert.NoError(t, err)
	})
}

// Helper types and functions for testing

type mockTransportFunc struct {
	fn func(*http.Request) (*http.Response, error)
}

func (m *mockTransportFunc) RoundTrip(req *http.Request) (*http.Response, error) {
	return m.fn(req)
}

type mcpTool struct {
	Name        string
	Description string
}

func setupMockMcpServer(t *testing.T, name string, tools []mcpTool) *httptest.Server {
	return setupMockMcpServerWithCallHandler(t, name, tools, nil)
}

func setupMockMcpServerWithCallHandler(t *testing.T, name string, tools []mcpTool, callHandler func(string, map[string]any) (string, bool, error)) *httptest.Server {
	server := httptest.NewServer(http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		handleMcpRequest(t, w, r, name, tools, callHandler)
	}))
	t.Cleanup(func() {
		server.Close()
	})
	return server
}

func handleMcpRequest(t *testing.T, w http.ResponseWriter, r *http.Request, name string, tools []mcpTool, callHandler func(string, map[string]any) (string, bool, error)) {
	w.Header().Set("Content-Type", "application/json")

	if name == "gitlab" {
		assert.Contains(t, r.URL.Path, "/api/v4/mcp")
	}

	if r.Method != "POST" {
		w.WriteHeader(http.StatusMethodNotAllowed)
		return
	}

	var request map[string]any
	err := json.NewDecoder(r.Body).Decode(&request)
	if err != nil {
		w.WriteHeader(http.StatusBadRequest)
		return
	}

	method, ok := request["method"].(string)
	if !ok {
		w.WriteHeader(http.StatusBadRequest)
		return
	}

	switch method {
	case "initialize":
		response := map[string]any{
			"jsonrpc": "2.0",
			"id":      request["id"],
			"result": map[string]any{
				"protocolVersion": "2024-11-05",
				"capabilities":    map[string]any{},
				"serverInfo": map[string]any{
					"name":    "test-server",
					"version": "1.0.0",
				},
			},
		}
		json.NewEncoder(w).Encode(response)

	case "notifications/initialized":
		w.WriteHeader(http.StatusOK)

	case "tools/list":
		var toolsList []map[string]any
		for _, tool := range tools {
			toolsList = append(toolsList, map[string]any{
				"name":        tool.Name,
				"description": tool.Description,
				"inputSchema": map[string]any{
					"type":       "object",
					"properties": map[string]any{},
				},
			})
		}
		response := map[string]any{
			"jsonrpc": "2.0",
			"id":      request["id"],
			"result": map[string]any{
				"tools": toolsList,
			},
		}
		json.NewEncoder(w).Encode(response)

	case "tools/call":
		if callHandler == nil {
			w.WriteHeader(http.StatusNotImplemented)
			return
		}
		params, ok := request["params"].(map[string]any)
		if !ok {
			w.WriteHeader(http.StatusBadRequest)
			return
		}
		name, _ := params["name"].(string)
		arguments, _ := params["arguments"].(map[string]any)
		content, isError, err := callHandler(name, arguments)
		if err != nil {
			w.WriteHeader(http.StatusInternalServerError)
			json.NewEncoder(w).Encode(map[string]any{
				"jsonrpc": "2.0",
				"id":      request["id"],
				"error": map[string]any{
					"code":    -32603,
					"message": err.Error(),
				},
			})
			return
		}
		var resultContent []map[string]any
		if content != "" {
			resultContent = append(resultContent, map[string]any{
				"type": "text",
				"text": content,
			})
		}
		response := map[string]any{
			"jsonrpc": "2.0",
			"id":      request["id"],
			"result": map[string]any{
				"content": resultContent,
				"isError": isError,
			},
		}
		json.NewEncoder(w).Encode(response)

	default:
		w.WriteHeader(http.StatusNotImplemented)
	}
}

func TestBuildSession(t *testing.T) {
	t.Run("builds session for a server", func(t *testing.T) {
		mcpServer := setupMockMcpServer(t, "", []mcpTool{})

		req := httptest.NewRequest("GET", "/test", nil)

		serverCfg := api.McpServerConfig{
			URL:     mcpServer.URL,
			Headers: map[string]string{},
		}

		session, err := buildSession(nil, req, "server-name", serverCfg)

		require.NoError(t, err)
		require.NotNil(t, session)
		assert.Equal(t, "server-name", session.name)
		assert.NotNil(t, session.session)
	})

	t.Run("returns error on connection failure", func(t *testing.T) {
		req := httptest.NewRequest("GET", "/test", nil)

		serverCfg := api.McpServerConfig{
			URL:     "http://localhost:1", // Use a port that's likely to be refused
			Headers: map[string]string{},
		}

		session, err := buildSession(nil, req, "test-server", serverCfg)

		require.Error(t, err)
		require.Nil(t, session)
	})
}

func TestManager_buildTools(t *testing.T) {
	t.Run("successfully builds tools from server", func(t *testing.T) {
		mcpServer := setupMockMcpServer(t, "", []mcpTool{
			{Name: "tool1", Description: "Tool 1"},
			{Name: "tool2", Description: "Tool 2"},
		})

		req := httptest.NewRequest("GET", "/test", nil)

		servers := map[string]api.McpServerConfig{
			"test-server": {
				URL:     mcpServer.URL,
				Headers: map[string]string{},
			},
		}

		mgr, err := newMcpManager(nil, req, servers)

		require.NoError(t, err)
		require.NotNil(t, mgr)
		assert.Len(t, mgr.tools, 2)
		assert.Equal(t, "test-server_tool1", mgr.tools[0].Name)
		assert.Equal(t, "test-server_tool2", mgr.tools[1].Name)
	})

	t.Run("handles error from ListTools", func(t *testing.T) {
		// Create a server that returns an error for tools/list
		server := httptest.NewServer(http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
			w.Header().Set("Content-Type", "application/json")

			var request map[string]any
			json.NewDecoder(r.Body).Decode(&request)

			switch request["method"].(string) {
			case "initialize":
				response := map[string]any{
					"jsonrpc": "2.0",
					"id":      request["id"],
					"result": map[string]any{
						"protocolVersion": "2024-11-05",
						"capabilities":    map[string]any{},
						"serverInfo": map[string]any{
							"name":    "test-server",
							"version": "1.0.0",
						},
					},
				}
				json.NewEncoder(w).Encode(response)
			case "tools/list":
				w.WriteHeader(http.StatusInternalServerError)
			}
		}))
		defer server.Close()

		req := httptest.NewRequest("GET", "/test", nil)

		servers := map[string]api.McpServerConfig{
			"test-server": {
				URL:     server.URL,
				Headers: map[string]string{},
				Tools:   &([]string{}),
			},
		}

		mgr, err := newMcpManager(nil, req, servers)

		require.Error(t, err)
		require.NotNil(t, mgr)
		assert.Contains(t, err.Error(), "failed to list tools")
	})
}
