package duoworkflow

import (
	"bytes"
	"context"
	"fmt"
	"net/http"
	"net/http/httptest"
	"strings"
	"testing"
	"time"

	"github.com/stretchr/testify/assert"
	"github.com/stretchr/testify/require"
	pb "gitlab.com/gitlab-org/modelops/applied-ml/code-suggestions/ai-assist/clients/gopb/contract"

	"gitlab.com/gitlab-org/gitlab/workhorse/internal/testhelper"
)

const testRemoteAddr = "192.0.2.1:1234"

// createBackendHandler creates a backend handler that makes HTTP requests using the provided client
// serverURL is used to rewrite the relative request URL to point at the test server
func createBackendHandler(client *http.Client, serverURL string) http.Handler {
	return http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		// Rewrite the relative URL to include the test server scheme and host
		reqWithServerURL := r.Clone(r.Context())
		reqWithServerURL.URL.Scheme = "http"
		reqWithServerURL.URL.Host = r.Host
		if reqWithServerURL.URL.Host == "" {
			reqWithServerURL.URL.Host = serverURL
		}

		resp, err := client.Do(reqWithServerURL)
		if err != nil {
			w.WriteHeader(http.StatusBadGateway)
			fmt.Fprint(w, err.Error())
			return
		}
		defer resp.Body.Close()

		// Copy response headers
		for k, v := range resp.Header {
			w.Header()[k] = v
		}
		w.WriteHeader(resp.StatusCode)

		// Copy response body
		buf := bytes.NewBuffer(nil)
		if _, err := buf.ReadFrom(resp.Body); err != nil {
			fmt.Fprint(w, err.Error())
			return
		}
		fmt.Fprint(w, buf.String())
	})
}

func TestRunHttpActionHandler_Execute(t *testing.T) {
	testhelper.ConfigureSecret()

	t.Run("successful request with body", func(t *testing.T) {
		server := httptest.NewServer(http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
			assert.Equal(t, "/api/projects/123", r.URL.Path)
			assert.Equal(t, "Bearer test-token", r.Header.Get("Authorization"))
			assert.Equal(t, "application/json", r.Header.Get("Content-Type"))
			assert.Equal(t, "Agent-Flow-via-GitLab-Workhorse", r.Header.Get("User-Agent"))
			assert.NotEmpty(t, r.Header.Get("Gitlab-Workhorse-Api-Request"))
			assert.Equal(t, "192.0.2.1", r.Header.Get("X-Forwarded-For"))
			assert.Equal(t, "POST", r.Method)
			w.WriteHeader(http.StatusCreated)
			fmt.Fprint(w, `{"id": 123, "name": "test-project"}`)
		}))
		defer server.Close()

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
			backend:     http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) { server.Config.Handler.ServeHTTP(w, r) }),
			token:       "test-token",
			originalReq: originalReq,
		}

		result, err := handler.Execute(context.Background(), action)

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
			backend:     createBackendHandler(server.Client(), server.Listener.Addr().String()),
			token:       "test-token",
			originalReq: originalReq,
		}

		result, err := handler.Execute(context.Background(), action)

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
			backend:     createBackendHandler(server.Client(), server.Listener.Addr().String()),
			token:       "test-token",
			originalReq: &http.Request{},
		}

		result, err := handler.Execute(context.Background(), action)

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
			backend:     createBackendHandler(server.Client(), server.Listener.Addr().String()),
			token:       "test-token",
			originalReq: &http.Request{},
		}

		result, err := handler.Execute(context.Background(), action)

		require.NoError(t, err)
		require.NotNil(t, result)
		require.Equal(t, int32(500), result.GetActionResponse().GetHttpResponse().StatusCode)
		require.JSONEq(t, `{"error": "internal server error"}`, result.GetActionResponse().GetHttpResponse().Body)
	})

	t.Run("invalid request URL", func(t *testing.T) {
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
			backend:     http.HandlerFunc(func(_ http.ResponseWriter, _ *http.Request) {}),
			token:       "test-token",
			originalReq: &http.Request{},
		}

		result, err := handler.Execute(context.Background(), action)

		// Note: This test still expects an error because the URL parsing happens
		// before the HTTP request, in url.Parse() and http.NewRequestWithContext()
		// which are not covered by our HTTP error handling changes
		require.Error(t, err)
		require.Nil(t, result)
	})

	t.Run("forwards X-Gitlab-Duo-Workflow-Id when workflowID is set", func(t *testing.T) {
		server := httptest.NewServer(http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
			assert.Equal(t, "wf-abc-123", r.Header.Get("X-Gitlab-Duo-Workflow-Id"))
			w.WriteHeader(http.StatusOK)
			fmt.Fprint(w, `{}`)
		}))
		defer server.Close()

		action := &pb.Action{
			RequestID: "req-wf",
			Action: &pb.Action_RunHTTPRequest{
				RunHTTPRequest: &pb.RunHTTPRequest{
					Method: "GET",
					Path:   "/api/projects",
				},
			},
		}

		handler := &runHTTPActionHandler{
			backend:     createBackendHandler(server.Client(), server.Listener.Addr().String()),
			token:       "test-token",
			originalReq: &http.Request{},
			workflowID:  "wf-abc-123",
		}

		_, err := handler.Execute(context.Background(), action)
		require.NoError(t, err)
	})

	t.Run("omits X-Gitlab-Duo-Workflow-Id when workflowID is empty", func(t *testing.T) {
		server := httptest.NewServer(http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
			_, exists := r.Header["X-Gitlab-Duo-Workflow-Id"]
			assert.False(t, exists, "header should not be set when workflowID is empty")
			w.WriteHeader(http.StatusOK)
			fmt.Fprint(w, `{}`)
		}))
		defer server.Close()

		action := &pb.Action{
			RequestID: "req-no-wf",
			Action: &pb.Action_RunHTTPRequest{
				RunHTTPRequest: &pb.RunHTTPRequest{
					Method: "GET",
					Path:   "/api/projects",
				},
			},
		}

		handler := &runHTTPActionHandler{
			backend:     createBackendHandler(server.Client(), server.Listener.Addr().String()),
			token:       "test-token",
			originalReq: &http.Request{},
		}

		_, err := handler.Execute(context.Background(), action)
		require.NoError(t, err)
	})

	t.Run("request with query parameters", func(t *testing.T) {
		server := httptest.NewServer(http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
			assert.Equal(t, "/api/projects", r.URL.Path)
			assert.Equal(t, "visibility=public&page=1", r.URL.RawQuery)

			w.WriteHeader(http.StatusOK)
			fmt.Fprint(w, `[{"id": 123, "name": "test-project"}]`)
		}))
		defer server.Close()

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
			backend:     createBackendHandler(server.Client(), server.Listener.Addr().String()),
			token:       "test-token",
			originalReq: &http.Request{},
		}

		result, err := handler.Execute(context.Background(), action)

		require.NoError(t, err)
		require.NotNil(t, result)
		require.Equal(t, int32(200), result.GetActionResponse().GetHttpResponse().StatusCode)
	})
}

func TestRunHttpActionHandler_applyRelativeURLRoot(t *testing.T) {
	tests := []struct {
		name            string
		relativeURLRoot string
		path            string
		want            string
	}{
		{
			name:            "empty root leaves path unchanged",
			relativeURLRoot: "",
			path:            "/api/graphql",
			want:            "/api/graphql",
		},
		{
			name:            "root slash only leaves path unchanged",
			relativeURLRoot: "/",
			path:            "/api/graphql",
			want:            "/api/graphql",
		},
		{
			name:            "root with trailing slash is joined without double slash",
			relativeURLRoot: "/gitlab/",
			path:            "/api/graphql",
			want:            "/gitlab/api/graphql",
		},
		{
			name:            "root without trailing slash is prepended",
			relativeURLRoot: "/gitlab",
			path:            "/api/v4/projects/1",
			want:            "/gitlab/api/v4/projects/1",
		},
		{
			name:            "path already carrying the prefix is left unchanged",
			relativeURLRoot: "/gitlab/",
			path:            "/gitlab/api/graphql",
			want:            "/gitlab/api/graphql",
		},
		{
			name:            "path equal to the prefix is left unchanged",
			relativeURLRoot: "/gitlab/",
			path:            "/gitlab",
			want:            "/gitlab",
		},
		{
			name:            "prefix is not applied to a lookalike path",
			relativeURLRoot: "/gitlab/",
			path:            "/gitlabextra/api/graphql",
			want:            "/gitlab/gitlabextra/api/graphql",
		},
		{
			name:            "query string is preserved",
			relativeURLRoot: "/gitlab/",
			path:            "/api/v4/projects?visibility=public",
			want:            "/gitlab/api/v4/projects?visibility=public",
		},
	}

	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			handler := &runHTTPActionHandler{relativeURLRoot: tt.relativeURLRoot}
			require.Equal(t, tt.want, handler.applyRelativeURLRoot(tt.path))
		})
	}
}

// TestRunHttpActionHandler_Execute_RelativeURLRoot proves that a DWS action
// path is resolved against the relative URL root so it matches an upstream
// router that only serves requests under that prefix.
func TestRunHttpActionHandler_Execute_RelativeURLRoot(t *testing.T) {
	testhelper.ConfigureSecret()

	const relativeURLRoot = "/gitlab/"

	// prefixRouter emulates upstream.ServeHTTP: it only serves requests whose
	// path is under relativeURLRoot, otherwise it 404s exactly like the real
	// router. Requests missing the prefix therefore fail, proving the handler
	// must prepend it.
	prefixRouter := func(backend http.Handler) http.Handler {
		return http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
			if !strings.HasPrefix(r.URL.Path, relativeURLRoot) {
				http.Error(w, fmt.Sprintf("Not found %q", r.URL.Path), http.StatusNotFound)
				return
			}
			backend.ServeHTTP(w, r)
		})
	}

	t.Run("prefixes the action path so it matches the router", func(t *testing.T) {
		server := httptest.NewServer(http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
			assert.Equal(t, "/gitlab/api/graphql", r.URL.Path)
			w.WriteHeader(http.StatusOK)
			fmt.Fprint(w, `{"data": {}}`)
		}))
		defer server.Close()

		action := &pb.Action{
			RequestID: "req-graphql",
			Action: &pb.Action_RunHTTPRequest{
				RunHTTPRequest: &pb.RunHTTPRequest{
					Method: "POST",
					Path:   "/api/graphql",
				},
			},
		}

		handler := &runHTTPActionHandler{
			backend:         prefixRouter(createBackendHandler(server.Client(), server.Listener.Addr().String())),
			relativeURLRoot: relativeURLRoot,
			token:           "test-token",
			originalReq:     &http.Request{},
		}

		result, err := handler.Execute(context.Background(), action)

		require.NoError(t, err)
		require.NotNil(t, result)
		require.Equal(t, int32(http.StatusOK), result.GetActionResponse().GetHttpResponse().StatusCode)
		require.JSONEq(t, `{"data": {}}`, result.GetActionResponse().GetHttpResponse().Body)
	})

	t.Run("without the fix the router 404s the bare path", func(t *testing.T) {
		server := httptest.NewServer(http.HandlerFunc(func(w http.ResponseWriter, _ *http.Request) {
			w.WriteHeader(http.StatusOK)
			fmt.Fprint(w, `{"data": {}}`)
		}))
		defer server.Close()

		action := &pb.Action{
			RequestID: "req-graphql-bare",
			Action: &pb.Action_RunHTTPRequest{
				RunHTTPRequest: &pb.RunHTTPRequest{
					Method: "POST",
					Path:   "/api/graphql",
				},
			},
		}

		// relativeURLRoot left empty simulates the pre-fix behavior.
		handler := &runHTTPActionHandler{
			backend:     prefixRouter(createBackendHandler(server.Client(), server.Listener.Addr().String())),
			token:       "test-token",
			originalReq: &http.Request{},
		}

		result, err := handler.Execute(context.Background(), action)

		require.NoError(t, err)
		require.NotNil(t, result)
		require.Equal(t, int32(http.StatusNotFound), result.GetActionResponse().GetHttpResponse().StatusCode)
	})
}

func TestServeHTTPSafe(t *testing.T) {
	t.Run("recovers ErrAbortHandler with canceled context and returns error", func(t *testing.T) {
		handler := http.HandlerFunc(func(_ http.ResponseWriter, _ *http.Request) {
			panic(http.ErrAbortHandler)
		})

		ctx, cancel := context.WithCancel(context.Background())
		cancel() // cancel before the call to simulate a disconnected client

		req, err := http.NewRequestWithContext(ctx, "GET", "http://example.com", nil)
		require.NoError(t, err)

		err = serveHTTPSafe(handler, httptest.NewRecorder(), req)

		require.ErrorIs(t, err, context.Canceled)
	})

	t.Run("recovers ErrAbortHandler with size limit hit and returns error", func(t *testing.T) {
		handler := http.HandlerFunc(func(_ http.ResponseWriter, _ *http.Request) {
			panic(http.ErrAbortHandler)
		})

		req, err := http.NewRequestWithContext(context.Background(), "GET", "http://example.com", nil)
		require.NoError(t, err)

		nrw := &nullResponseWriter{
			sizeLimitHit: true,
		}

		err = serveHTTPSafe(handler, nrw, req)

		require.EqualError(t, err, "response body exceeded size limit (4190208 bytes)")
	})

	t.Run("recovers ErrAbortHandler with non-canceled context and returns error", func(t *testing.T) {
		handler := http.HandlerFunc(func(_ http.ResponseWriter, _ *http.Request) {
			panic(http.ErrAbortHandler)
		})

		req, err := http.NewRequestWithContext(context.Background(), "GET", "http://example.com", nil)
		require.NoError(t, err)

		err = serveHTTPSafe(handler, httptest.NewRecorder(), req)

		require.EqualError(t, err, "request aborted")
	})

	t.Run("re-panics on unexpected panics", func(t *testing.T) {
		handler := http.HandlerFunc(func(_ http.ResponseWriter, _ *http.Request) {
			panic("something unexpected")
		})

		req, err := http.NewRequestWithContext(context.Background(), "GET", "http://example.com", nil)
		require.NoError(t, err)

		require.Panics(t, func() {
			_ = serveHTTPSafe(handler, httptest.NewRecorder(), req)
		})
	})

	t.Run("returns nil when handler completes normally", func(t *testing.T) {
		handler := http.HandlerFunc(func(w http.ResponseWriter, _ *http.Request) {
			w.WriteHeader(http.StatusOK)
		})

		req, err := http.NewRequestWithContext(context.Background(), "GET", "http://example.com", nil)
		require.NoError(t, err)

		err = serveHTTPSafe(handler, httptest.NewRecorder(), req)

		require.NoError(t, err)
	})
}

func TestRunHttpActionHandler_Execute_ContextCancelled(t *testing.T) {
	t.Run("sends error to dws instead of panicking or erroring when context is canceled", func(t *testing.T) {
		testhelper.ConfigureSecret()

		// This backend simulates what httputil.ReverseProxy does when the request
		// context is canceled mid-flight: it panics with http.ErrAbortHandler.
		// Without the serveHTTPSafe wrapper, this panic would propagate uncaught
		// out of the agent goroutine and crash the process.
		backend := http.HandlerFunc(func(_ http.ResponseWriter, _ *http.Request) {
			panic(http.ErrAbortHandler)
		})

		action := &pb.Action{
			RequestID: "req-cancel",
			Action: &pb.Action_RunHTTPRequest{
				RunHTTPRequest: &pb.RunHTTPRequest{
					Method: "GET",
					Path:   "/api/test",
				},
			},
		}

		ctx, cancel := context.WithCancel(context.Background())
		cancel()

		originalReq := httptest.NewRequest("GET", "/ws", nil)
		originalReq.RemoteAddr = testRemoteAddr

		handler := &runHTTPActionHandler{
			backend:     backend,
			token:       "test-token",
			originalReq: originalReq,
		}

		result, err := handler.Execute(ctx, action)

		require.NoError(t, err)
		require.NotNil(t, result)
		require.NotEmpty(t, result.GetActionResponse().GetHttpResponse().Error)
	})
}

func TestRunHttpActionHandler_Execute_Timeout(t *testing.T) {
	testhelper.ConfigureSecret()

	// slowBackend simulates a backend that blocks until the request context is done,
	// then panics with http.ErrAbortHandler — the same behavior as httputil.ReverseProxy
	// when the upstream connection is interrupted by a context cancellation or deadline.
	slowBackend := http.HandlerFunc(func(_ http.ResponseWriter, r *http.Request) {
		<-r.Context().Done()
		panic(http.ErrAbortHandler)
	})

	makeAction := func() *pb.Action {
		return &pb.Action{
			RequestID: "req-timeout",
			Action: &pb.Action_RunHTTPRequest{
				RunHTTPRequest: &pb.RunHTTPRequest{
					Method: "GET",
					Path:   "/api/test",
				},
			},
		}
	}

	t.Run("returns errRequestTimedOut when shouldTimeoutHTTPRequests is true and deadline is exceeded", func(t *testing.T) {
		originalReq := httptest.NewRequest("GET", "/ws", nil)
		originalReq.RemoteAddr = testRemoteAddr

		handler := &runHTTPActionHandler{
			backend:                   slowBackend,
			token:                     "test-token",
			originalReq:               originalReq,
			shouldTimeoutHTTPRequests: true,
		}

		// Use an already-expired deadline context so the timeout fires immediately
		// without waiting for the full httpRequestTimeout duration.
		ctx, cancel := context.WithDeadline(context.Background(), time.Now().Add(-time.Second))
		defer cancel()

		result, err := handler.Execute(ctx, makeAction())

		require.NoError(t, err)
		require.NotNil(t, result)
		require.Equal(t, errRequestTimedOut.Error(), result.GetActionResponse().GetHttpResponse().Error)
	})

	t.Run("does not apply timeout when shouldTimeoutHTTPRequests is false", func(t *testing.T) {
		server := httptest.NewServer(http.HandlerFunc(func(w http.ResponseWriter, _ *http.Request) {
			w.WriteHeader(http.StatusOK)
			fmt.Fprint(w, `{"status": "ok"}`)
		}))
		defer server.Close()

		originalReq := httptest.NewRequest("GET", "/ws", nil)
		originalReq.RemoteAddr = testRemoteAddr

		handler := &runHTTPActionHandler{
			backend:                   createBackendHandler(server.Client(), server.Listener.Addr().String()),
			token:                     "test-token",
			originalReq:               originalReq,
			shouldTimeoutHTTPRequests: false,
		}

		result, err := handler.Execute(context.Background(), makeAction())

		require.NoError(t, err)
		require.NotNil(t, result)
		require.Empty(t, result.GetActionResponse().GetHttpResponse().Error)
		require.Equal(t, int32(http.StatusOK), result.GetActionResponse().GetHttpResponse().StatusCode)
	})

	t.Run("succeeds when shouldTimeoutHTTPRequests is true and request completes within timeout", func(t *testing.T) {
		server := httptest.NewServer(http.HandlerFunc(func(w http.ResponseWriter, _ *http.Request) {
			w.WriteHeader(http.StatusOK)
			fmt.Fprint(w, `{"status": "ok"}`)
		}))
		defer server.Close()

		originalReq := httptest.NewRequest("GET", "/ws", nil)
		originalReq.RemoteAddr = testRemoteAddr

		handler := &runHTTPActionHandler{
			backend:                   createBackendHandler(server.Client(), server.Listener.Addr().String()),
			token:                     "test-token",
			originalReq:               originalReq,
			shouldTimeoutHTTPRequests: true,
		}

		result, err := handler.Execute(context.Background(), makeAction())

		require.NoError(t, err)
		require.NotNil(t, result)
		require.Empty(t, result.GetActionResponse().GetHttpResponse().Error)
		require.Equal(t, int32(http.StatusOK), result.GetActionResponse().GetHttpResponse().StatusCode)
	})
}

func TestHeaderParsing(t *testing.T) {
	t.Run("response headers are correctly parsed and joined", func(t *testing.T) {
		server := httptest.NewServer(http.HandlerFunc(func(w http.ResponseWriter, _ *http.Request) {
			w.Header().Set("Content-Type", "application/json")
			w.Header().Set("X-Custom-Header", "custom-value")
			w.Header().Set("Cache-Control", "no-cache")
			w.WriteHeader(http.StatusOK)
			fmt.Fprint(w, `{"status": "ok"}`)
		}))
		defer server.Close()

		action := &pb.Action{
			RequestID: "req-headers",
			Action: &pb.Action_RunHTTPRequest{
				RunHTTPRequest: &pb.RunHTTPRequest{
					Method: "GET",
					Path:   "/api/test",
				},
			},
		}

		handler := &runHTTPActionHandler{
			backend:     createBackendHandler(server.Client(), server.Listener.Addr().String()),
			token:       "test-token",
			originalReq: &http.Request{},
		}

		result, err := handler.Execute(context.Background(), action)

		require.NoError(t, err)
		require.NotNil(t, result)

		headers := result.GetActionResponse().GetHttpResponse().Headers
		require.NotNil(t, headers)
		require.Equal(t, "application/json", headers["Content-Type"])
		require.Equal(t, "custom-value", headers["X-Custom-Header"])
		require.Equal(t, "no-cache", headers["Cache-Control"])
	})

	t.Run("multiple header values are joined with comma and space", func(t *testing.T) {
		server := httptest.NewServer(http.HandlerFunc(func(w http.ResponseWriter, _ *http.Request) {
			w.Header().Add("Set-Cookie", "session=abc123")
			w.Header().Add("Set-Cookie", "user=john")
			w.WriteHeader(http.StatusOK)
			fmt.Fprint(w, `{}`)
		}))
		defer server.Close()

		action := &pb.Action{
			RequestID: "req-multi-headers",
			Action: &pb.Action_RunHTTPRequest{
				RunHTTPRequest: &pb.RunHTTPRequest{
					Method: "GET",
					Path:   "/api/test",
				},
			},
		}

		handler := &runHTTPActionHandler{
			backend:     createBackendHandler(server.Client(), server.Listener.Addr().String()),
			token:       "test-token",
			originalReq: &http.Request{},
		}

		result, err := handler.Execute(context.Background(), action)

		require.NoError(t, err)
		require.NotNil(t, result)

		headers := result.GetActionResponse().GetHttpResponse().Headers
		require.NotNil(t, headers)
		// Multiple header values should be joined with ", "
		require.Equal(t, "session=abc123, user=john", headers["Set-Cookie"])
	})

	t.Run("X-Forwarded-For header with existing prior value", func(t *testing.T) {
		var capturedHeaders http.Header

		server := httptest.NewServer(http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
			capturedHeaders = r.Header
			w.WriteHeader(http.StatusOK)
			fmt.Fprint(w, `{}`)
		}))
		defer server.Close()

		action := &pb.Action{
			RequestID: "req-forwarded",
			Action: &pb.Action_RunHTTPRequest{
				RunHTTPRequest: &pb.RunHTTPRequest{
					Method: "GET",
					Path:   "/api/test",
				},
			},
		}

		originalReq := httptest.NewRequest("GET", "/ws", nil)
		originalReq.RemoteAddr = testRemoteAddr
		originalReq.Header.Set("X-Forwarded-For", "10.0.0.1, 10.0.0.2")

		handler := &runHTTPActionHandler{
			backend:     createBackendHandler(server.Client(), server.Listener.Addr().String()),
			token:       "test-token",
			originalReq: originalReq,
		}

		result, err := handler.Execute(context.Background(), action)

		require.NoError(t, err)
		require.NotNil(t, result)

		// X-Forwarded-For should contain prior values plus the new client IP
		require.Equal(t, "10.0.0.1, 10.0.0.2, 192.0.2.1", capturedHeaders.Get("X-Forwarded-For"))
	})

	t.Run("X-Forwarded-For header without prior value", func(t *testing.T) {
		var capturedHeaders http.Header

		server := httptest.NewServer(http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
			capturedHeaders = r.Header
			w.WriteHeader(http.StatusOK)
			fmt.Fprint(w, `{}`)
		}))
		defer server.Close()

		action := &pb.Action{
			RequestID: "req-forwarded-new",
			Action: &pb.Action_RunHTTPRequest{
				RunHTTPRequest: &pb.RunHTTPRequest{
					Method: "GET",
					Path:   "/api/test",
				},
			},
		}

		originalReq := httptest.NewRequest("GET", "/ws", nil)
		originalReq.RemoteAddr = testRemoteAddr

		handler := &runHTTPActionHandler{
			backend:     createBackendHandler(server.Client(), server.Listener.Addr().String()),
			token:       "test-token",
			originalReq: originalReq,
		}

		result, err := handler.Execute(context.Background(), action)

		require.NoError(t, err)
		require.NotNil(t, result)

		// X-Forwarded-For should contain only the client IP
		require.Equal(t, "192.0.2.1", capturedHeaders.Get("X-Forwarded-For"))
	})
}
