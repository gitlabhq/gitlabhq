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
	"net/http/httptest"
	"net/url"
	"strings"
	"sync"
	"sync/atomic"
	"testing"
	"time"

	"github.com/stretchr/testify/assert"
	"github.com/stretchr/testify/require"

	pb "gitlab.com/gitlab-org/modelops/applied-ml/code-suggestions/ai-assist/clients/gopb/contract"

	"gitlab.com/gitlab-org/gitlab/workhorse/internal/api"
	"gitlab.com/gitlab-org/gitlab/workhorse/internal/secret"
	"gitlab.com/gitlab-org/gitlab/workhorse/internal/testhelper"
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
			session: newSession(httptest.NewRequest("GET", "/", nil)),
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
			next:    &mockTransportFunc{fn: transportFunc},
			headers: map[string]string{},
			session: newSession(originalReq),
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
			next:    &mockTransportFunc{fn: transportFunc},
			headers: map[string]string{},
			session: newSession(originalReq),
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
			next:    &mockTransportFunc{fn: transportFunc},
			headers: map[string]string{},
			session: newSession(originalReq),
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
			session: newSession(httptest.NewRequest("GET", "/", nil)),
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
			session: newSession(httptest.NewRequest("GET", "/", nil)),
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

	t.Run("includes X-Duo-Workflow-Session-Id once the workflow ID is set", func(t *testing.T) {
		var capturedRequest *http.Request
		var transportFunc = func(req *http.Request) (*http.Response, error) {
			capturedRequest = req
			return &http.Response{
				StatusCode: 200,
				Body:       http.NoBody,
				Header:     make(http.Header),
			}, nil
		}

		sess := newSession(httptest.NewRequest("GET", "/", nil))
		rt := &roundTripper{
			next:    &mockTransportFunc{fn: transportFunc},
			headers: map[string]string{},
			session: sess,
		}

		// Before the workflow ID is set — header should be absent
		req := httptest.NewRequest("GET", "http://example.com", nil)
		r, err := rt.RoundTrip(req)
		require.NoError(t, err)
		require.NoError(t, r.Body.Close())
		assert.Empty(t, capturedRequest.Header.Get("X-Duo-Workflow-Session-Id"))

		// After setting workflowID — header should be present
		sess.setWorkflowID("test-workflow-id-123")

		req = httptest.NewRequest("GET", "http://example.com", nil)
		r, err = rt.RoundTrip(req)
		require.NoError(t, err)
		require.NoError(t, r.Body.Close())
		assert.Equal(t, "test-workflow-id-123", capturedRequest.Header.Get("X-Duo-Workflow-Session-Id"))
	})
}

func TestNewMcpManager(t *testing.T) {
	testhelper.ConfigureSecret()

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

		mgr, err := newMcpManager(nil, newSession(req), servers)

		require.NoError(t, err)
		require.NotNil(t, mgr)
		assert.Len(t, mgr.tools, 1)
		assert.Equal(t, "test-server_test_tool", mgr.tools[0].Name)
		assert.Len(t, mgr.toolSessionsByName, 1)
		assert.Len(t, mgr.serverSessions, 1)
		assert.Empty(t, mgr.preApprovedTools)
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

		mgr, err := newMcpManager(nil, newSession(req), servers)

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

		mgr, err := newMcpManager(nil, newSession(req), servers)

		require.NoError(t, err)
		require.NotNil(t, mgr)
		assert.Len(t, mgr.tools, 1)
		assert.Equal(t, "test-server_allowed_tool", mgr.tools[0].Name)
		assert.Empty(t, mgr.preApprovedTools)
	})

	t.Run("includes preapproved tools when configured", func(t *testing.T) {
		mcpServer := setupMockMcpServer(t, "", []mcpTool{
			{Name: "tool1", Description: "Tool 1"},
			{Name: "tool2", Description: "Tool 2"},
		})

		req := httptest.NewRequest("GET", "/test", nil)

		preApprovedTools := []string{"tool1"}
		servers := map[string]api.McpServerConfig{
			"test-server": {
				URL:              mcpServer.URL,
				Headers:          map[string]string{},
				Tools:            &([]string{"tool1", "tool2"}),
				PreApprovedTools: &preApprovedTools,
			},
		}

		mgr, err := newMcpManager(nil, newSession(req), servers)

		require.NoError(t, err)
		require.NotNil(t, mgr)
		assert.Len(t, mgr.tools, 2)
		assert.Len(t, mgr.preApprovedTools, 1)
		assert.Equal(t, "test-server_tool1", mgr.preApprovedTools[0])
	})

	t.Run("only includes preapproved tools that are also in enabled tools", func(t *testing.T) {
		mcpServer := setupMockMcpServer(t, "", []mcpTool{
			{Name: "tool1", Description: "Tool 1"},
			{Name: "tool2", Description: "Tool 2"},
		})

		req := httptest.NewRequest("GET", "/test", nil)

		preApprovedTools := []string{"tool1", "tool3"}
		servers := map[string]api.McpServerConfig{
			"test-server": {
				URL:              mcpServer.URL,
				Headers:          map[string]string{},
				Tools:            &([]string{"tool1"}),
				PreApprovedTools: &preApprovedTools,
			},
		}

		mgr, err := newMcpManager(nil, newSession(req), servers)

		require.NoError(t, err)
		require.NotNil(t, mgr)
		assert.Len(t, mgr.tools, 1)
		assert.Len(t, mgr.preApprovedTools, 1)
		assert.Equal(t, "test-server_tool1", mgr.preApprovedTools[0])
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

		mgr, err := newMcpManager(nil, newSession(req), servers)

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

		mgr, err := newMcpManager(rails, newSession(req), servers)

		require.NoError(t, err)
		require.NotNil(t, mgr)
		assert.Empty(t, mgr.tools)
	})

	t.Run("returns nothing when servers map is empty", func(t *testing.T) {
		req := httptest.NewRequest("GET", "/test", nil)

		mgr, err := newMcpManager(nil, newSession(req), map[string]api.McpServerConfig{})

		require.NoError(t, err)
		require.Nil(t, mgr)
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

		initFailures := counterVecValue(t, mcpInitFailuresTotal, mcpServerCatalog)

		mgr, err := newMcpManager(nil, newSession(req), servers)

		require.Error(t, err)
		require.NotNil(t, mgr)
		assert.Len(t, mgr.tools, 1)
		assert.Contains(t, err.Error(), "failed to initialize MCP session bad-server")
		assert.InDelta(t, initFailures+1, counterVecValue(t, mcpInitFailuresTotal, mcpServerCatalog), 0)
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

func TestManager_PreApprovedTools(t *testing.T) {
	t.Run("returns preapproved tools list", func(t *testing.T) {
		preApprovedTools := []string{"tool1", "tool2"}

		mgr := &manager{
			preApprovedTools: preApprovedTools,
		}

		result := mgr.PreApprovedTools()
		assert.Equal(t, preApprovedTools, result)
		assert.Len(t, result, 2)
	})

	t.Run("returns nil when manager is nil", func(t *testing.T) {
		var mgr *manager
		assert.Nil(t, mgr.PreApprovedTools())
	})

	t.Run("returns empty list when no preapproved tools", func(t *testing.T) {
		mgr := &manager{
			preApprovedTools: []string{},
		}

		result := mgr.PreApprovedTools()
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

		mgr, err := newMcpManager(nil, newSession(req), servers)
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

		calls := counterVecValue(t, mcpCallsTotal, mcpServerCatalog, mcpOutcomeOK)

		result, err := mgr.CallTool(context.Background(), action)

		require.NoError(t, err)
		require.NotNil(t, result)
		plainTextResp := result.GetActionResponse().GetPlainTextResponse()
		assert.Contains(t, plainTextResp.Response, "Test Issue")
		assert.Empty(t, plainTextResp.Error)
		assert.InDelta(t, calls+1, counterVecValue(t, mcpCallsTotal, mcpServerCatalog, mcpOutcomeOK), 0)
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

		mgr, err := newMcpManager(nil, newSession(req), servers)
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

		toolErrors := counterVecValue(t, mcpCallsTotal, mcpServerCatalog, mcpOutcomeToolError)

		result, err := mgr.CallTool(context.Background(), action)

		require.NoError(t, err)
		require.NotNil(t, result)
		plainTextResp := result.GetActionResponse().GetPlainTextResponse()
		assert.Equal(t, "Tool execution failed", plainTextResp.Error)
		assert.Empty(t, plainTextResp.Response)
		assert.InDelta(t, toolErrors+1, counterVecValue(t, mcpCallsTotal, mcpServerCatalog, mcpOutcomeToolError), 0)
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

		mgr, err := newMcpManager(nil, newSession(req), servers)
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

func TestManager_CallTool_concurrentCallsOnOneServer(t *testing.T) {
	const calls = 3

	// Every call is held until all of them have reached the server, so the
	// test only passes if one session carries the calls concurrently.
	var arrived sync.WaitGroup
	arrived.Add(calls)
	allArrived := make(chan struct{})
	go func() {
		arrived.Wait()
		close(allArrived)
	}()

	mcpServer := setupMockMcpServerWithCallHandler(t, "", []mcpTool{
		{Name: "slow_tool", Description: "A slow tool"},
	}, func(_ string, args map[string]any) (string, bool, error) {
		arrived.Done()
		select {
		case <-allArrived:
		case <-time.After(5 * time.Second):
			return "", false, errors.New("calls were not concurrent")
		}
		return fmt.Sprint(args["n"]), false, nil
	})

	servers := map[string]api.McpServerConfig{
		"test-server": {URL: mcpServer.URL, Headers: map[string]string{}},
	}
	mgr, err := newMcpManager(nil, newSession(httptest.NewRequest("GET", "/test", nil)), servers)
	require.NoError(t, err)
	t.Cleanup(func() { require.NoError(t, mgr.Close()) })

	results := make([]*pb.ClientEvent, calls)
	errs := make([]error, calls)

	var wg sync.WaitGroup
	for i := range calls {
		wg.Go(func() {
			action := &pb.Action{
				RequestID: fmt.Sprint(i),
				Action: &pb.Action_RunMCPTool{
					RunMCPTool: &pb.RunMCPTool{Name: "test-server_slow_tool", Args: fmt.Sprintf(`{"n": "%d"}`, i)},
				},
			}

			results[i], errs[i] = mgr.CallTool(context.Background(), action)
		})
	}
	wg.Wait()

	for i := range calls {
		require.NoError(t, errs[i])
		require.Equal(t, fmt.Sprint(i), results[i].GetActionResponse().GetPlainTextResponse().Response)
	}
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

		mgr, err := newMcpManager(nil, newSession(req), servers)
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
	if name == "orbit" {
		assert.Contains(t, r.URL.Path, "/api/v4/orbit/mcp")
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
		// MCP spec requires 202 Accepted with no body for JSON-RPC notifications
		// See: https://modelcontextprotocol.io/specification/2025-03-26/basic/transports
		w.WriteHeader(http.StatusAccepted)

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

		session, err := buildSession(nil, newSession(req), "server-name", serverCfg)

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

		session, err := buildSession(nil, newSession(req), "test-server", serverCfg)

		require.Error(t, err)
		require.Nil(t, session)
	})
}

func TestManager_addTools(t *testing.T) {
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

		mgr, err := newMcpManager(nil, newSession(req), servers)

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
				// MCP spec requires 202 Accepted with no body for JSON-RPC notifications
				// See: https://modelcontextprotocol.io/specification/2025-03-26/basic/transports
				w.WriteHeader(http.StatusAccepted)
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

		mgr, err := newMcpManager(nil, newSession(req), servers)

		require.Error(t, err)
		require.NotNil(t, mgr)
		assert.Contains(t, err.Error(), "failed to list tools")
	})
}

func TestBuildSession_orbitRouting(t *testing.T) {
	testhelper.ConfigureSecret()

	t.Run("routes orbit server to /api/v4/orbit/mcp", func(t *testing.T) {
		mcpServer := setupMockMcpServer(t, "orbit", []mcpTool{
			{Name: "query_graph", Description: "Query the knowledge graph"},
		})

		apiURL, err := url.Parse(mcpServer.URL)
		require.NoError(t, err)

		rails := api.NewAPI(apiURL, "test-version", http.DefaultTransport)
		req := httptest.NewRequest("GET", "/test", nil)

		tools := []string{"query_graph"}
		serverCfg := api.McpServerConfig{
			Headers:          map[string]string{"Authorization": "Bearer test-token"},
			Tools:            &tools,
			PreApprovedTools: &tools,
		}

		session, err := buildSession(rails, newSession(req), "orbit", serverCfg)

		require.NoError(t, err)
		require.NotNil(t, session)
		assert.Equal(t, "orbit", session.name)
	})

	t.Run("routes gitlab server to /api/v4/mcp", func(t *testing.T) {
		mcpServer := setupMockMcpServer(t, "gitlab", []mcpTool{
			{Name: "search", Description: "Search"},
		})

		apiURL, err := url.Parse(mcpServer.URL)
		require.NoError(t, err)

		rails := api.NewAPI(apiURL, "test-version", http.DefaultTransport)
		req := httptest.NewRequest("GET", "/test", nil)

		serverCfg := api.McpServerConfig{
			Headers: map[string]string{"Authorization": "Bearer test-token"},
		}

		session, err := buildSession(rails, newSession(req), "gitlab", serverCfg)

		require.NoError(t, err)
		require.NotNil(t, session)
		assert.Equal(t, "gitlab", session.name)
	})
}

func TestBuildSession_signsInternalRequestsWithWorkhorseJWT(t *testing.T) {
	testhelper.ConfigureSecret()

	for _, serverName := range []string{gitlabServerName, orbitServerName} {
		t.Run(serverName, func(t *testing.T) {
			var jwtHeader string
			server := httptest.NewServer(http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
				jwtHeader = r.Header.Get(secret.RequestHeader)
				handleMcpRequest(t, w, r, serverName, []mcpTool{{Name: "tool1", Description: "desc"}}, nil)
			}))
			t.Cleanup(server.Close)

			apiURL, err := url.Parse(server.URL)
			require.NoError(t, err)

			rails := api.NewAPI(apiURL, "test-version", http.DefaultTransport)
			req := httptest.NewRequest("GET", "/test", nil)

			session, err := buildSession(rails, newSession(req), serverName, api.McpServerConfig{})
			require.NoError(t, err)
			require.NotNil(t, session)

			assert.NotEmpty(t, jwtHeader)
		})
	}
}

func TestBuildSession_sendsWorkflowIDOnlyToInternalServers(t *testing.T) {
	testhelper.ConfigureSecret()

	tests := []struct {
		serverName string
		want       string
	}{
		{serverName: gitlabServerName, want: "workflow-123"},
		{serverName: orbitServerName, want: "workflow-123"},
		{serverName: "external-server", want: ""},
	}

	for _, tt := range tests {
		t.Run(tt.serverName, func(t *testing.T) {
			var workflowIDHeader string
			server := httptest.NewServer(http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
				workflowIDHeader = r.Header.Get("X-Gitlab-Duo-Workflow-Id")
				handleMcpRequest(t, w, r, tt.serverName, []mcpTool{{Name: "tool1", Description: "desc"}}, nil)
			}))
			t.Cleanup(server.Close)

			apiURL, err := url.Parse(server.URL)
			require.NoError(t, err)

			rails := api.NewAPI(apiURL, "test-version", http.DefaultTransport)
			req := httptest.NewRequest("GET", "/test", nil)
			sess := newSession(req)
			sess.setWorkflowID("workflow-123")

			session, err := buildSession(rails, sess, tt.serverName, api.McpServerConfig{URL: server.URL})
			require.NoError(t, err)
			require.NotNil(t, session)

			assert.Equal(t, tt.want, workflowIDHeader)
		})
	}
}

func TestNewMcpManager_orbitAndGitlabServers(t *testing.T) {
	testhelper.ConfigureSecret()

	t.Run("initializes both gitlab and orbit servers with correct routing", func(t *testing.T) {
		gitlabServer := setupMockMcpServer(t, "gitlab", []mcpTool{
			{Name: "search", Description: "Search code"},
		})
		orbitServer := setupMockMcpServer(t, "orbit", []mcpTool{
			{Name: "query_graph", Description: "Query the knowledge graph"},
			{Name: "get_graph_schema", Description: "Get the graph schema"},
		})

		// Use a mux to route both gitlab and orbit paths on the same server
		mux := http.NewServeMux()
		mux.HandleFunc("/api/v4/mcp", func(w http.ResponseWriter, r *http.Request) {
			handleMcpRequest(t, w, r, "gitlab", []mcpTool{
				{Name: "search", Description: "Search code"},
			}, nil)
		})
		mux.HandleFunc("/api/v4/orbit/mcp", func(w http.ResponseWriter, r *http.Request) {
			handleMcpRequest(t, w, r, "orbit", []mcpTool{
				{Name: "query_graph", Description: "Query the knowledge graph"},
				{Name: "get_graph_schema", Description: "Get the graph schema"},
			}, nil)
		})
		combinedServer := httptest.NewServer(mux)
		t.Cleanup(func() { combinedServer.Close() })

		combinedURL, err := url.Parse(combinedServer.URL)
		require.NoError(t, err)

		rails := api.NewAPI(combinedURL, "test-version", http.DefaultTransport)
		req := httptest.NewRequest("GET", "/test", nil)

		gitlabTools := []string{"search"}
		orbitTools := []string{"query_graph", "get_graph_schema"}
		servers := map[string]api.McpServerConfig{
			"gitlab": {
				Headers:          map[string]string{"Authorization": "Bearer gitlab-token"},
				Tools:            &gitlabTools,
				PreApprovedTools: &gitlabTools,
				Trusted:          true,
			},
			"orbit": {
				Headers:          map[string]string{"Authorization": "Bearer orbit-token"},
				Tools:            &orbitTools,
				PreApprovedTools: &orbitTools,
			},
		}

		_ = gitlabServer
		_ = orbitServer

		mgr, err := newMcpManager(rails, newSession(req), servers)

		require.NoError(t, err)
		require.NotNil(t, mgr)
		assert.Len(t, mgr.tools, 3)

		toolsByName := make(map[string]*pb.McpTool)
		for _, tool := range mgr.tools {
			toolsByName[tool.Name] = tool
		}

		assert.Contains(t, toolsByName, "gitlab_search")
		assert.Contains(t, toolsByName, "orbit_query_graph")
		assert.Contains(t, toolsByName, "orbit_get_graph_schema")

		assert.Len(t, mgr.preApprovedTools, 3)
		assert.Contains(t, mgr.preApprovedTools, "gitlab_search")
		assert.Contains(t, mgr.preApprovedTools, "orbit_query_graph")
		assert.Contains(t, mgr.preApprovedTools, "orbit_get_graph_schema")
	})
}

func TestManager_addTools_propagatesTrustedFlag(t *testing.T) {
	t.Run("sets Trusted on tools from trusted server", func(t *testing.T) {
		mcpServer := setupMockMcpServer(t, "", []mcpTool{
			{Name: "tool1", Description: "Tool 1"},
		})

		req := httptest.NewRequest("GET", "/test", nil)

		servers := map[string]api.McpServerConfig{
			"trusted-server": {
				URL:     mcpServer.URL,
				Headers: map[string]string{},
				Trusted: true,
			},
		}

		mgr, err := newMcpManager(nil, newSession(req), servers)

		require.NoError(t, err)
		require.NotNil(t, mgr)
		require.Len(t, mgr.tools, 1)
		require.NotNil(t, mgr.tools[0].Trusted)
		assert.True(t, *mgr.tools[0].Trusted)
	})

	t.Run("sets Trusted false on tools from untrusted server", func(t *testing.T) {
		mcpServer := setupMockMcpServer(t, "", []mcpTool{
			{Name: "tool1", Description: "Tool 1"},
		})

		req := httptest.NewRequest("GET", "/test", nil)

		servers := map[string]api.McpServerConfig{
			"untrusted-server": {
				URL:     mcpServer.URL,
				Headers: map[string]string{},
				Trusted: false,
			},
		}

		mgr, err := newMcpManager(nil, newSession(req), servers)

		require.NoError(t, err)
		require.NotNil(t, mgr)
		require.Len(t, mgr.tools, 1)
		require.NotNil(t, mgr.tools[0].Trusted)
		assert.False(t, *mgr.tools[0].Trusted)
	})

	t.Run("mixed trusted and untrusted servers", func(t *testing.T) {
		trustedServer := setupMockMcpServer(t, "", []mcpTool{
			{Name: "safe_tool", Description: "Safe tool"},
		})
		untrustedServer := setupMockMcpServer(t, "", []mcpTool{
			{Name: "ext_tool", Description: "External tool"},
		})

		req := httptest.NewRequest("GET", "/test", nil)

		servers := map[string]api.McpServerConfig{
			"internal": {
				URL:     trustedServer.URL,
				Headers: map[string]string{},
				Trusted: true,
			},
			"external": {
				URL:     untrustedServer.URL,
				Headers: map[string]string{},
				Trusted: false,
			},
		}

		mgr, err := newMcpManager(nil, newSession(req), servers)

		require.NoError(t, err)
		require.NotNil(t, mgr)
		require.Len(t, mgr.tools, 2)

		toolsByName := make(map[string]*pb.McpTool)
		for _, tool := range mgr.tools {
			toolsByName[tool.Name] = tool
		}

		require.NotNil(t, toolsByName["internal_safe_tool"].Trusted)
		assert.True(t, *toolsByName["internal_safe_tool"].Trusted)

		require.NotNil(t, toolsByName["external_ext_tool"].Trusted)
		assert.False(t, *toolsByName["external_ext_tool"].Trusted)
	})
}

func TestNewMcpManager_SetsUpServersConcurrently(t *testing.T) {
	const serverCount = 2

	// Each server holds its initialize request until every server has
	// received one, which only happens when they are set up concurrently.
	arrived := make(chan struct{}, serverCount)
	allArrived := make(chan struct{})
	go func() {
		for range serverCount {
			select {
			case <-arrived:
			case <-t.Context().Done():
				return
			}
		}
		close(allArrived)
	}()

	newServer := func(tool string) *httptest.Server {
		server := httptest.NewServer(http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
			body, err := io.ReadAll(r.Body)
			if !assert.NoError(t, err) {
				return
			}
			r.Body = io.NopCloser(bytes.NewReader(body))

			if bytes.Contains(body, []byte(`"method":"initialize"`)) {
				select {
				case arrived <- struct{}{}:
				default:
				}

				select {
				case <-allArrived:
				case <-time.After(5 * time.Second):
					w.WriteHeader(http.StatusServiceUnavailable)
					return
				}
			}

			handleMcpRequest(t, w, r, "", []mcpTool{{Name: tool}}, nil)
		}))
		t.Cleanup(server.Close)
		return server
	}

	servers := map[string]api.McpServerConfig{
		"server1": {URL: newServer("tool1").URL},
		"server2": {URL: newServer("tool2").URL},
	}

	mgr, err := newMcpManager(nil, newSession(httptest.NewRequest("GET", "/test", nil)), servers)

	require.NoError(t, err)
	require.Len(t, mgr.tools, serverCount)
	require.NoError(t, mgr.Close())
}

func TestNewMcpManager_OrdersToolsByServerName(t *testing.T) {
	servers := map[string]api.McpServerConfig{
		"b-server": {URL: setupMockMcpServer(t, "", []mcpTool{{Name: "tool"}}).URL},
		"a-server": {URL: setupMockMcpServer(t, "", []mcpTool{{Name: "tool"}}).URL},
		"c-server": {URL: setupMockMcpServer(t, "", []mcpTool{{Name: "tool"}}).URL},
	}

	// Map iteration order is random, so repeat to catch an order that
	// depends on it.
	for range 5 {
		mgr, err := newMcpManager(nil, newSession(httptest.NewRequest("GET", "/test", nil)), servers)
		require.NoError(t, err)

		var names []string
		for _, tool := range mgr.Tools() {
			names = append(names, tool.Name)
		}
		require.Equal(t, []string{"a-server_tool", "b-server_tool", "c-server_tool"}, names)
		require.NoError(t, mgr.Close())
	}
}

func TestNewMcpManager_ReusesConnectionsToExternalServers(t *testing.T) {
	var connections atomic.Int32

	server := httptest.NewUnstartedServer(http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		handleMcpRequest(t, w, r, "", []mcpTool{{Name: "tool"}}, nil)
	}))
	server.Config.ConnState = func(_ net.Conn, state http.ConnState) {
		if state == http.StateNew {
			connections.Add(1)
		}
	}
	server.Start()
	t.Cleanup(server.Close)

	servers := map[string]api.McpServerConfig{"external": {URL: server.URL}}

	for range 2 {
		mgr, err := newMcpManager(nil, newSession(httptest.NewRequest("GET", "/test", nil)), servers)
		require.NoError(t, err)
		require.NoError(t, mgr.Close())
	}

	require.Equal(t, int32(1), connections.Load(), "the second session should reuse the first session's connection")
}
