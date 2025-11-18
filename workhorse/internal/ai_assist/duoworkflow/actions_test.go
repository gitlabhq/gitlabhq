package duoworkflow

import (
	"context"
	"errors"
	"fmt"
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

const testRemoteAddr = "192.0.2.1:1234"

// errorReader is a mock reader that always returns an error
type errorReader struct{}

func (e *errorReader) Read(_ []byte) (n int, err error) {
	return 0, errors.New("simulated read error")
}

func (e *errorReader) Close() error {
	return nil
}

// mockTransport is a mock HTTP transport for testing
type mockTransport struct {
	response *http.Response
	err      error
}

func (m *mockTransport) RoundTrip(_ *http.Request) (*http.Response, error) {
	if m.err != nil {
		return nil, m.err
	}
	return m.response, nil
}

func TestRunHttpActionHandler_Execute(t *testing.T) {
	t.Run("successful request with body", func(t *testing.T) {
		server := httptest.NewServer(http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
			assert.Equal(t, "/api/projects/123", r.URL.Path)
			assert.Equal(t, "Bearer test-token", r.Header.Get("Authorization"))
			assert.Equal(t, "application/json", r.Header.Get("Content-Type"))
			assert.Equal(t, "Agent-Flow-via-GitLab-Workhorse", r.Header.Get("User-Agent"))
			assert.Equal(t, "192.0.2.1", r.Header.Get("X-Forwarded-For"))
			assert.Equal(t, "POST", r.Method)
			w.WriteHeader(http.StatusCreated)
			fmt.Fprint(w, `{"id": 123, "name": "test-project"}`)
		}))
		defer server.Close()

		serverURL, err := url.Parse(server.URL)
		require.NoError(t, err)

		body := `{"name": "test-project"}`

		action := &pb.Action{
			RequestID: "req-123",
			Action: &pb.Action_RunHTTPRequest{
				RunHTTPRequest: &pb.RunHTTPRequest{
					Method: "POST",
					Path:   "/api/projects/123",
					Body:   &body,
				},
			},
		}

		originalReq := httptest.NewRequest("GET", "/ws", nil)
		originalReq.RemoteAddr = testRemoteAddr

		handler := &runHTTPActionHandler{
			rails: &api.API{
				Client: server.Client(),
				URL:    serverURL,
			},
			action:      action,
			token:       "test-token",
			originalReq: originalReq,
		}

		result, err := handler.Execute(context.Background())

		require.NoError(t, err)
		require.NotNil(t, result)
		require.Equal(t, "req-123", result.GetActionResponse().RequestID)
		require.JSONEq(t, `{"id": 123, "name": "test-project"}`, result.GetActionResponse().GetHttpResponse().Body)
		require.Equal(t, int32(201), result.GetActionResponse().GetHttpResponse().StatusCode)
	})

	t.Run("successful request without body", func(t *testing.T) {
		server := httptest.NewServer(http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
			assert.Equal(t, "/api/projects", r.URL.Path)
			assert.Equal(t, "127.0.0.1:3000, 192.0.2.1", r.Header.Get("X-Forwarded-For"))
			assert.Equal(t, "GET", r.Method)

			w.WriteHeader(http.StatusOK)
			fmt.Fprint(w, `[{"id": 123, "name": "test-project"}]`)
		}))
		defer server.Close()

		serverURL, err := url.Parse(server.URL)
		require.NoError(t, err)

		action := &pb.Action{
			RequestID: "req-456",
			Action: &pb.Action_RunHTTPRequest{
				RunHTTPRequest: &pb.RunHTTPRequest{
					Method: "GET",
					Path:   "/api/projects",
				},
			},
		}

		originalReq := httptest.NewRequest("GET", "/ws", nil)
		originalReq.RemoteAddr = testRemoteAddr
		originalReq.Header.Set("X-Forwarded-For", "127.0.0.1:3000")

		handler := &runHTTPActionHandler{
			rails: &api.API{
				Client: server.Client(),
				URL:    serverURL,
			},
			action:      action,
			token:       "test-token",
			originalReq: originalReq,
		}

		result, err := handler.Execute(context.Background())

		require.NoError(t, err)
		require.NotNil(t, result)
		require.Equal(t, "req-456", result.GetActionResponse().RequestID)
		require.JSONEq(t, `[{"id": 123, "name": "test-project"}]`, result.GetActionResponse().GetHttpResponse().Body)
		require.Equal(t, int32(200), result.GetActionResponse().GetHttpResponse().StatusCode)
	})

	t.Run("successful request with limited body", func(t *testing.T) {
		body := strings.Repeat("large body", 5*1024*1024)

		server := httptest.NewServer(http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
			assert.Equal(t, "/api/projects", r.URL.Path)
			assert.Equal(t, "GET", r.Method)

			w.WriteHeader(http.StatusOK)
			fmt.Fprint(w, body)
		}))
		defer server.Close()

		serverURL, err := url.Parse(server.URL)
		require.NoError(t, err)

		action := &pb.Action{
			RequestID: "req-456",
			Action: &pb.Action_RunHTTPRequest{
				RunHTTPRequest: &pb.RunHTTPRequest{
					Method: "GET",
					Path:   "/api/projects",
				},
			},
		}

		handler := &runHTTPActionHandler{
			rails: &api.API{
				Client: server.Client(),
				URL:    serverURL,
			},
			action:      action,
			token:       "test-token",
			originalReq: &http.Request{},
		}

		result, err := handler.Execute(context.Background())

		require.NoError(t, err)
		require.NotNil(t, result)
		require.Equal(t, "req-456", result.GetActionResponse().RequestID)
		require.Equal(t, body[:ActionResponseBodyLimit], result.GetActionResponse().GetHttpResponse().Body)
		require.Equal(t, int32(200), result.GetActionResponse().GetHttpResponse().StatusCode)
	})

	t.Run("server error", func(t *testing.T) {
		server := httptest.NewServer(http.HandlerFunc(func(w http.ResponseWriter, _ *http.Request) {
			w.WriteHeader(http.StatusInternalServerError)
			fmt.Fprint(w, `{"error": "internal server error"}`)
		}))
		defer server.Close()

		serverURL, err := url.Parse(server.URL)
		require.NoError(t, err)

		action := &pb.Action{
			RequestID: "req-789",
			Action: &pb.Action_RunHTTPRequest{
				RunHTTPRequest: &pb.RunHTTPRequest{
					Method: "GET",
					Path:   "/api/projects",
				},
			},
		}

		handler := &runHTTPActionHandler{
			rails: &api.API{
				Client: server.Client(),
				URL:    serverURL,
			},
			action:      action,
			token:       "test-token",
			originalReq: &http.Request{},
		}

		result, err := handler.Execute(context.Background())

		require.NoError(t, err)
		require.NotNil(t, result)
		require.Equal(t, int32(500), result.GetActionResponse().GetHttpResponse().StatusCode)
		require.JSONEq(t, `{"error": "internal server error"}`, result.GetActionResponse().GetHttpResponse().Body)
	})

	t.Run("invalid request URL", func(t *testing.T) {
		serverURL, err := url.Parse("http://localhost:0")
		require.NoError(t, err)

		action := &pb.Action{
			RequestID: "req-invalid",
			Action: &pb.Action_RunHTTPRequest{
				RunHTTPRequest: &pb.RunHTTPRequest{
					Method: "GET",
					Path:   ":%invalid",
				},
			},
		}

		handler := &runHTTPActionHandler{
			rails: &api.API{
				Client: &http.Client{},
				URL:    serverURL,
			},
			action:      action,
			token:       "test-token",
			originalReq: &http.Request{},
		}

		result, err := handler.Execute(context.Background())

		// Note: This test still expects an error because the URL parsing happens
		// before the HTTP request, in url.Parse() and http.NewRequestWithContext()
		// which are not covered by our HTTP error handling changes
		require.Error(t, err)
		require.Nil(t, result)
	})

	t.Run("HTTP connection error returns HttpResponse.Error", func(t *testing.T) {
		// Use a mock transport that returns an error
		transport := &mockTransport{
			err: errors.New("connection refused"),
		}

		action := &pb.Action{
			RequestID: "req-connection-error",
			Action: &pb.Action_RunHTTPRequest{
				RunHTTPRequest: &pb.RunHTTPRequest{
					Method: "GET",
					Path:   "/api/projects",
				},
			},
		}

		serverURL, err := url.Parse("http://localhost:3000")
		require.NoError(t, err)

		handler := &runHTTPActionHandler{
			rails: &api.API{
				Client: &http.Client{Transport: transport},
				URL:    serverURL,
			},
			action:      action,
			token:       "test-token",
			originalReq: &http.Request{},
		}

		result, err := handler.Execute(context.Background())

		require.NoError(t, err)
		require.NotNil(t, result)
		require.Equal(t, "req-connection-error", result.GetActionResponse().RequestID)

		httpResponse := result.GetActionResponse().GetHttpResponse()
		require.NotNil(t, httpResponse)
		require.NotEmpty(t, httpResponse.Error)
		require.Contains(t, httpResponse.Error, "connection refused")
		require.Empty(t, httpResponse.Body)
		require.Equal(t, int32(0), httpResponse.StatusCode)
	})

	t.Run("body read error returns HttpResponse.Error", func(t *testing.T) {
		// Create a custom roundtripper that returns a response with an error reader
		transport := &mockTransport{
			response: &http.Response{
				StatusCode: 200,
				Body:       &errorReader{},
				Header:     make(http.Header),
			},
		}

		action := &pb.Action{
			RequestID: "req-read-error",
			Action: &pb.Action_RunHTTPRequest{
				RunHTTPRequest: &pb.RunHTTPRequest{
					Method: "GET",
					Path:   "/api/projects",
				},
			},
		}

		serverURL, err := url.Parse("http://localhost:3000")
		require.NoError(t, err)

		handler := &runHTTPActionHandler{
			rails: &api.API{
				Client: &http.Client{Transport: transport},
				URL:    serverURL,
			},
			action:      action,
			token:       "test-token",
			originalReq: &http.Request{},
		}

		result, err := handler.Execute(context.Background())

		require.NoError(t, err)
		require.NotNil(t, result)
		require.Equal(t, "req-read-error", result.GetActionResponse().RequestID)

		httpResponse := result.GetActionResponse().GetHttpResponse()
		require.NotNil(t, httpResponse)
		require.NotEmpty(t, httpResponse.Error)
		require.Contains(t, httpResponse.Error, "simulated read error")
		require.Empty(t, httpResponse.Body)
		require.Equal(t, int32(200), httpResponse.StatusCode)
	})

	t.Run("request with query parameters", func(t *testing.T) {
		server := httptest.NewServer(http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
			assert.Equal(t, "/api/projects", r.URL.Path)
			assert.Equal(t, "visibility=public&page=1", r.URL.RawQuery)

			w.WriteHeader(http.StatusOK)
			fmt.Fprint(w, `[{"id": 123, "name": "test-project"}]`)
		}))
		defer server.Close()

		serverURL, err := url.Parse(server.URL)
		require.NoError(t, err)

		action := &pb.Action{
			RequestID: "req-query",
			Action: &pb.Action_RunHTTPRequest{
				RunHTTPRequest: &pb.RunHTTPRequest{
					Method: "GET",
					Path:   "/api/projects?visibility=public&page=1",
				},
			},
		}

		handler := &runHTTPActionHandler{
			rails: &api.API{
				Client: server.Client(),
				URL:    serverURL,
			},
			action:      action,
			token:       "test-token",
			originalReq: &http.Request{},
		}

		result, err := handler.Execute(context.Background())

		require.NoError(t, err)
		require.NotNil(t, result)
		require.Equal(t, int32(200), result.GetActionResponse().GetHttpResponse().StatusCode)
	})
}
