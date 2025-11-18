package bodylimit

import (
	"context"
	"io"
	"net/http"
	"net/http/httptest"
	"strings"
	"sync"
	"testing"

	"github.com/stretchr/testify/require"
)

// mockRoundTripper implements http.RoundTripper for testing
type mockRoundTripper struct {
	response      *http.Response
	err           error
	customHandler func(*http.Request) (*http.Response, error)
}

func (m *mockRoundTripper) RoundTrip(r *http.Request) (*http.Response, error) {
	// Use custom handler if provided
	if m.customHandler != nil {
		return m.customHandler(r)
	}

	return m.response, m.err
}

func TestCountingReadCloser(t *testing.T) {
	tests := []struct {
		name          string
		data          string
		readSizes     []int
		expectedCount int64
		mode          Mode
		limit         int64
		expectError   bool
	}{
		{
			name:          "single read within limit",
			data:          "hello world",
			readSizes:     []int{11},
			expectedCount: 11,
			mode:          ModeEnforced,
			limit:         20,
			expectError:   false,
		},
		{
			name:          "multiple reads within limit",
			data:          "hello world",
			readSizes:     []int{5, 6},
			expectedCount: 11,
			mode:          ModeEnforced,
			limit:         20,
			expectError:   false,
		},
		{
			name:          "exceeds limit in enforced mode",
			data:          "hello world this is too long",
			readSizes:     []int{28},
			expectedCount: 10,
			mode:          ModeEnforced,
			limit:         10,
			expectError:   false,
		},
		{
			name:          "multiple reads, exceeds limit in enforced mode",
			data:          "hello world this is too long",
			readSizes:     []int{15, 15},
			expectedCount: 10,
			mode:          ModeEnforced,
			limit:         10,
			expectError:   true,
		},
		{
			name:          "exceeds limit in logging mode",
			data:          "hello world this is too long",
			readSizes:     []int{28},
			expectedCount: 28,
			mode:          ModeLogging,
			limit:         10,
			expectError:   false,
		},
		{
			name:          "empty data",
			data:          "",
			readSizes:     []int{10},
			expectedCount: 0,
			mode:          ModeEnforced,
			limit:         5,
			expectError:   false,
		},
	}

	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			reader := io.NopCloser(strings.NewReader(tt.data))
			counter := &countingReadCloser{
				reader: reader,
				count:  0,
				limit:  tt.limit,
				mode:   tt.mode,
			}

			var lastErr error
			for _, size := range tt.readSizes {
				buf := make([]byte, size)
				_, err := counter.Read(buf)
				if err != nil && err != io.EOF {
					lastErr = err
					break // Stop reading after first error in enforced mode
				}
			}

			if tt.expectError {
				require.Error(t, lastErr, "expected error but got none")
				var bodyTooLargeErr *RequestBodyTooLargeError
				require.ErrorAs(t, lastErr, &bodyTooLargeErr, "error should be RequestBodyTooLargeError")
				require.Equal(t, tt.limit, bodyTooLargeErr.Limit, "error limit mismatch")
			} else {
				require.NoError(t, lastErr)
			}

			require.Equal(t, tt.expectedCount, counter.Count(), "byte count mismatch")
			require.NoError(t, counter.Close())
		})
	}
}

func TestRoundTripper_NoBodyLimit(t *testing.T) {
	mockNext := &mockRoundTripper{
		response: &http.Response{StatusCode: http.StatusOK},
	}

	rt := NewRoundTripper(mockNext, ModeEnforced)

	// Request without body limit in context
	req, err := http.NewRequest(http.MethodPost, "http://example.com", strings.NewReader("test data"))
	require.NoError(t, err)

	res, err := rt.RoundTrip(req)
	require.NoError(t, err)
	defer closeResponseBody(res)

	require.Equal(t, http.StatusOK, res.StatusCode)
}

func TestRoundTripper_NilBody(t *testing.T) {
	mockNext := &mockRoundTripper{
		response: &http.Response{StatusCode: http.StatusOK},
		customHandler: func(r *http.Request) (*http.Response, error) {
			// Try to read from the body - this would panic if nil body wasn't handled
			if r.Body != nil {
				buf := make([]byte, 10)
				_, err := r.Body.Read(buf)
				if err != nil && err != io.EOF {
					return nil, err
				}
				r.Body.Close()
			}
			return &http.Response{StatusCode: http.StatusOK}, nil
		},
	}

	rt := NewRoundTripper(mockNext, ModeEnforced)

	// Request with nil body (like GET requests)
	ctx := context.WithValue(context.Background(), BodyLimitKey, int64(100))
	req, err := http.NewRequestWithContext(ctx, http.MethodGet, "http://example.com", nil)
	require.NoError(t, err, "failed to create request")

	res, err := rt.RoundTrip(req)
	require.NoError(t, err)
	defer closeResponseBody(res)

	require.Equal(t, http.StatusOK, res.StatusCode, "status code mismatch")
}

func TestRoundTripper_WithinLimit(t *testing.T) {
	mockNext := &mockRoundTripper{
		response: &http.Response{StatusCode: http.StatusOK},
		customHandler: func(r *http.Request) (*http.Response, error) {
			// Consume some of the body but stay within limit
			if r.Body != nil {
				buf := make([]byte, 5) // Read only 5 bytes
				r.Body.Read(buf)
				r.Body.Close()
			}
			return &http.Response{StatusCode: http.StatusOK}, nil
		},
	}

	rt := NewRoundTripper(mockNext, ModeEnforced)

	// Request with body limit in context
	ctx := context.WithValue(context.Background(), BodyLimitKey, int64(100))
	req, err := http.NewRequestWithContext(ctx, http.MethodPost, "http://example.com", strings.NewReader("small data"))
	require.NoError(t, err)

	res, err := rt.RoundTrip(req)
	require.NoError(t, err)
	defer closeResponseBody(res)

	require.Equal(t, http.StatusOK, res.StatusCode)
}

func TestRoundTripper_ExceedsLimit_Logging(t *testing.T) {
	largeData := strings.Repeat("a", 150) // Exceed 100 byte limit

	mockNext := &mockRoundTripper{
		response: &http.Response{StatusCode: http.StatusOK},
		customHandler: func(r *http.Request) (*http.Response, error) {
			// Consume the entire body to trigger counting
			if r.Body != nil {
				io.ReadAll(r.Body)
				r.Body.Close()
			}
			return &http.Response{StatusCode: http.StatusOK}, nil
		},
	}

	rt := NewRoundTripper(mockNext, ModeLogging)

	ctx := context.WithValue(context.Background(), BodyLimitKey, int64(100))
	req, err := http.NewRequestWithContext(ctx, http.MethodPost, "http://example.com", strings.NewReader(largeData))
	require.NoError(t, err)

	res, err := rt.RoundTrip(req)
	require.NoError(t, err)
	defer closeResponseBody(res)

	// In logging mode, request should still succeed
	require.Equal(t, http.StatusOK, res.StatusCode)
}

func TestRoundTripper_ExceedsLimit_Enforced(t *testing.T) {
	largeData := strings.Repeat("a", 150) // Exceed 100 byte limit

	mockNext := &mockRoundTripper{
		response: &http.Response{StatusCode: http.StatusOK},
		customHandler: func(r *http.Request) (*http.Response, error) {
			// Try to consume the entire body - this will trigger the limit error
			if r.Body != nil {
				_, err := io.ReadAll(r.Body)
				if err != nil {
					return nil, err // Return the error from counting reader
				}
				r.Body.Close()
			}
			return &http.Response{StatusCode: http.StatusOK}, nil
		},
	}

	rt := NewRoundTripper(mockNext, ModeEnforced)

	ctx := context.WithValue(context.Background(), BodyLimitKey, int64(100))
	req, err := http.NewRequestWithContext(ctx, http.MethodPost, "http://example.com", strings.NewReader(largeData))
	require.NoError(t, err)

	res, err := rt.RoundTrip(req)
	require.NoError(t, err)
	defer closeResponseBody(res)

	// In enforced mode, should return 413 error
	require.Equal(t, http.StatusRequestEntityTooLarge, res.StatusCode)

	expectedStatus := http.StatusText(http.StatusRequestEntityTooLarge)
	require.Equal(t, expectedStatus, res.Status, "status text mismatch")

	// Verify response body
	require.NotNil(t, res.Body, "response body is nil")

	body, err := io.ReadAll(res.Body)
	require.NoError(t, err)

	expectedBody := "Request Entity Too Large"
	require.Equal(t, expectedBody, string(body), "response body mismatch")

	// Verify request details are preserved
	require.Equal(t, req, res.Request, "request not preserved in response")
}

func TestRoundTripper_BodyLimitEdgeCases(t *testing.T) {
	tests := []struct {
		name        string
		bodyLimit   interface{}
		expectPass  bool
		consumeBody bool
	}{
		{
			name:        "zero limit",
			bodyLimit:   int64(0),
			expectPass:  true, // Zero limit should pass through (< 1 check)
			consumeBody: false,
		},
		{
			name:        "negative limit",
			bodyLimit:   int64(-1),
			expectPass:  true, // Negative limit should pass through
			consumeBody: false,
		},
		{
			name:        "wrong type",
			bodyLimit:   "100",
			expectPass:  true, // Wrong type should pass through
			consumeBody: false,
		},
		{
			name:        "valid limit exceeded",
			bodyLimit:   int64(100),
			expectPass:  false, // Valid limit with large data should not pass
			consumeBody: true,  // Need to consume body for test to work
		},
	}

	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			mockNext := &mockRoundTripper{
				response: &http.Response{StatusCode: http.StatusOK},
			}

			if tt.consumeBody {
				// Set custom handler to consume the body
				mockNext.customHandler = func(r *http.Request) (*http.Response, error) {
					if r.Body != nil {
						_, err := io.ReadAll(r.Body)
						if err != nil {
							return nil, err // Propagate the error
						}
						r.Body.Close()
					}
					return &http.Response{StatusCode: http.StatusOK}, nil
				}
			}

			rt := NewRoundTripper(mockNext, ModeEnforced)

			largeData := strings.Repeat("a", 150)
			ctx := context.WithValue(context.Background(), BodyLimitKey, tt.bodyLimit)
			req, err := http.NewRequestWithContext(ctx, http.MethodPost, "http://example.com", strings.NewReader(largeData))
			require.NoError(t, err)

			res, err := rt.RoundTrip(req)
			require.NoError(t, err)
			defer closeResponseBody(res)

			if tt.expectPass {
				require.Equal(t, http.StatusOK, res.StatusCode, "expected request to pass with status 200")
			} else {
				require.Equal(t, http.StatusRequestEntityTooLarge, res.StatusCode, "expected request to fail with status 413")
			}
		})
	}
}

func TestRoundTripper_PerRequestModeOverride(t *testing.T) {
	tests := []struct {
		name           string
		globalMode     Mode
		requestMode    Mode
		expectedStatus int
		setRequestMode bool
	}{
		{
			name:           "global enforced, override to logging",
			globalMode:     ModeEnforced,
			requestMode:    ModeLogging,
			expectedStatus: http.StatusOK, // Should log but not block
			setRequestMode: true,
		},
		{
			name:           "global logging, override to enforced",
			globalMode:     ModeLogging,
			requestMode:    ModeEnforced,
			expectedStatus: http.StatusRequestEntityTooLarge, // Should block
			setRequestMode: true,
		},
		{
			name:           "global enforced, override to disabled",
			globalMode:     ModeEnforced,
			requestMode:    ModeDisabled,
			expectedStatus: http.StatusOK, // Should bypass completely
			setRequestMode: true,
		},
		{
			name:           "global disabled, override to enforced",
			globalMode:     ModeDisabled,
			requestMode:    ModeEnforced,
			expectedStatus: http.StatusRequestEntityTooLarge, // Should enforce
			setRequestMode: true,
		},
		{
			name:           "no override, use global mode",
			globalMode:     ModeEnforced,
			expectedStatus: http.StatusRequestEntityTooLarge, // Use global enforced
			setRequestMode: false,
		},
	}

	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			mockNext := &mockRoundTripper{
				response: &http.Response{StatusCode: http.StatusOK},
				customHandler: func(r *http.Request) (*http.Response, error) {
					if r.Body != nil {
						_, err := io.ReadAll(r.Body)
						if err != nil {
							return nil, err
						}
						r.Body.Close()
					}
					return &http.Response{StatusCode: http.StatusOK}, nil
				},
			}

			rt := NewRoundTripper(mockNext, tt.globalMode)

			// Create context with body limit
			ctx := context.WithValue(context.Background(), BodyLimitKey, int64(100))

			// Add per-request mode override if specified
			if tt.setRequestMode {
				ctx = context.WithValue(ctx, BodyLimitMode, tt.requestMode)
			}

			largeData := strings.Repeat("a", 150)
			req, err := http.NewRequestWithContext(ctx, http.MethodPost, "http://example.com", strings.NewReader(largeData))
			require.NoError(t, err)

			res, err := rt.RoundTrip(req)
			require.NoError(t, err)

			if res.Body != nil {
				defer res.Body.Close()
			}

			require.Equal(t, tt.expectedStatus, res.StatusCode)
		})
	}
}

func TestRoundTripper_NextRoundTripperError(t *testing.T) {
	expectedErr := io.EOF
	mockNext := &mockRoundTripper{
		response: nil,
		err:      expectedErr,
	}

	rt := NewRoundTripper(mockNext, ModeEnforced)

	ctx := context.WithValue(context.Background(), BodyLimitKey, int64(100))
	req, err := http.NewRequestWithContext(ctx, http.MethodPost, "http://example.com", strings.NewReader("test"))
	require.NoError(t, err)

	res, err := rt.RoundTrip(req)
	defer closeResponseBody(res)

	require.ErrorIs(t, err, expectedErr, "expected EOF error")
	require.Nil(t, res, "expected nil response")
}

func TestRequestBodyTooLargeError(t *testing.T) {
	err := &RequestBodyTooLargeError{
		Limit: 100,
		Read:  150,
	}

	expected := "request body too large: read 150 bytes, limit 100 bytes"
	require.Equal(t, expected, err.Error(), "error message mismatch")
}

func TestRoundTripper_DifferentModes(t *testing.T) {
	largeData := strings.Repeat("a", 150) // Exceed 100 byte limit

	tests := []struct {
		name         string
		mode         Mode
		expectStatus int
		expectError  bool
	}{
		{
			name:         "disabled mode bypasses limits",
			mode:         ModeDisabled,
			expectStatus: http.StatusOK,
			expectError:  false,
		},
		{
			name:         "logging mode allows request",
			mode:         ModeLogging,
			expectStatus: http.StatusOK,
			expectError:  false,
		},
		{
			name:         "enforced mode blocks request",
			mode:         ModeEnforced,
			expectStatus: http.StatusRequestEntityTooLarge,
			expectError:  false, // No error returned, just 413 response
		},
	}

	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			mockNext := &mockRoundTripper{
				response: &http.Response{StatusCode: http.StatusOK},
				customHandler: func(r *http.Request) (*http.Response, error) {
					if r.Body != nil {
						_, err := io.ReadAll(r.Body)
						if err != nil {
							return nil, err
						}
						r.Body.Close()
					}
					return &http.Response{StatusCode: http.StatusOK}, nil
				},
			}

			rt := NewRoundTripper(mockNext, tt.mode)

			ctx := context.WithValue(context.Background(), BodyLimitKey, int64(100))
			req, err := http.NewRequestWithContext(ctx, http.MethodPost, "http://example.com", strings.NewReader(largeData))
			require.NoError(t, err)

			res, err := rt.RoundTrip(req)
			defer closeResponseBody(res)

			if tt.expectError {
				require.Error(t, err, "expected error but got none")
			} else {
				require.NoError(t, err)
			}

			require.Equal(t, tt.expectStatus, res.StatusCode)
		})
	}
}

// TestIntegration tests the roundtripper with a real HTTP server
func TestIntegration(t *testing.T) {
	handler := http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		_, err := io.ReadAll(r.Body)
		if err != nil {
			http.Error(w, err.Error(), http.StatusInternalServerError)
			return
		}
		w.Write([]byte("success"))
	})

	// Create test server
	server := httptest.NewServer(handler)
	defer server.Close()

	tests := []struct {
		name         string
		mode         Mode
		bodySize     int
		expectedCode int
	}{
		{
			name:         "under limit with enforced mode",
			mode:         ModeEnforced,
			bodySize:     90,
			expectedCode: http.StatusOK,
		},
		{
			name:         "over limit with enforced mode",
			mode:         ModeEnforced,
			bodySize:     150,
			expectedCode: http.StatusRequestEntityTooLarge,
		},
		{
			name:         "over limit with logging mode",
			mode:         ModeLogging,
			bodySize:     150,
			expectedCode: http.StatusOK,
		},
		{
			name:         "over limit with disabled mode",
			mode:         ModeDisabled,
			bodySize:     150,
			expectedCode: http.StatusOK,
		},
	}

	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			// Create HTTP client with our custom roundtripper
			transport := &contextSettingTransport{
				next:      http.DefaultTransport,
				bodyLimit: 100,
				mode:      tt.mode,
			}
			client := &http.Client{Transport: transport}

			// Make request
			body := strings.NewReader(strings.Repeat("a", tt.bodySize))
			resp, err := client.Post(server.URL, "text/plain", body)

			require.NoError(t, err)
			require.Equal(t, tt.expectedCode, resp.StatusCode)

			defer closeResponseBody(resp)

			// Verify response body for successful requests
			switch tt.expectedCode {
			case http.StatusOK:
				respBody, err := io.ReadAll(resp.Body)
				require.NoError(t, err)
				require.Equal(t, "success", string(respBody), "response body mismatch")
			case http.StatusRequestEntityTooLarge:
				respBody, err := io.ReadAll(resp.Body)
				require.NoError(t, err)
				require.Equal(t, "Request Entity Too Large", string(respBody), "error response body mismatch")
			}
		})
	}
}

func TestStressLimitEnforcement(t *testing.T) {
	handler := http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		_, err := io.ReadAll(r.Body)
		if err != nil {
			http.Error(w, err.Error(), http.StatusInternalServerError)
			return
		}
		w.Write([]byte("success"))
	})

	server := httptest.NewServer(handler)
	defer server.Close()

	transport := &contextSettingTransport{
		next:      http.DefaultTransport,
		bodyLimit: 100,
		mode:      ModeEnforced,
	}

	// Run many concurrent requests
	type testResult struct {
		id         int
		statusCode int
		err        error
	}

	const numRequests = 100
	results := make(chan testResult, numRequests)
	var wg sync.WaitGroup

	for i := 0; i < numRequests; i++ {
		wg.Add(1)
		go func(id int) {
			defer wg.Done()

			client := &http.Client{Transport: transport}
			largeData := strings.Repeat("a", 150) // Exceed limit

			resp, err := client.Post(server.URL, "text/plain", strings.NewReader(largeData))
			if err != nil {
				results <- testResult{id: id, err: err}
				return
			}
			defer closeResponseBody(resp)

			results <- testResult{id: id, statusCode: resp.StatusCode}
		}(i)
	}

	wg.Wait()
	close(results)

	// Count results
	statusCounts := make(map[int]int)

	for result := range results {
		if result.err != nil {
			t.Errorf("id %d: unexpected error: %v", result.id, result.err)
		}

		statusCounts[result.statusCode]++
	}

	// ALL requests should return 413 (no 200 responses)
	require.Equal(t, numRequests, statusCounts[413], "Expected %d requests with 413 status, got %d. Status counts: %v", numRequests, statusCounts[413], statusCounts)
	require.Equal(t, 0, statusCounts[200], "Expected 0 requests with 200 status, got %d. Status counts: %v", statusCounts[200], statusCounts)
}

// contextSettingTransport wraps the request body roundtripper and sets context
type contextSettingTransport struct {
	next      http.RoundTripper
	bodyLimit int64
	mode      Mode
}

func (t *contextSettingTransport) RoundTrip(r *http.Request) (*http.Response, error) {
	// Set body limit in context
	ctx := context.WithValue(r.Context(), BodyLimitKey, t.bodyLimit)
	r = r.WithContext(ctx)

	// Use our roundtripper
	rt := NewRoundTripper(t.next, t.mode)
	return rt.RoundTrip(r)
}

func closeResponseBody(res *http.Response) {
	if res != nil && res.Body != nil {
		res.Body.Close()
	}
}
