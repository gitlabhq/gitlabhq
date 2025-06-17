package circuitbreaker

import (
	"bytes"
	"encoding/json"
	"errors"
	"io"
	"net/http"
	"net/url"
	"strings"
	"testing"
	"time"

	"github.com/alicebob/miniredis/v2"
	"github.com/stretchr/testify/assert"
	"github.com/stretchr/testify/require"

	"gitlab.com/gitlab-org/gitlab/workhorse/internal/config"
)

// mockRoundTripper implements http.RoundTripper for testing
type mockRoundTripper struct {
	response *http.Response
	err      error
}

const (
	delegateBody = "delegate body"
)

func (m *mockRoundTripper) RoundTrip(_ *http.Request) (*http.Response, error) {
	return m.response, m.err
}

func TestRoundTripCircuitBreaker(t *testing.T) {
	redisConfig, cleanup := setupRedisConfig(t)
	defer cleanup()

	testCases := []struct {
		name       string
		statusCode int
		shouldTrip bool
	}{
		{"429 Too Many Requests", http.StatusTooManyRequests, true},
		{"200 OK", http.StatusOK, false},
		{"500 Internal Server Error", http.StatusInternalServerError, false},
		{"403 Forbidden", http.StatusForbidden, false},
	}

	for _, tc := range testCases {
		t.Run(tc.name, func(t *testing.T) {
			delegateResponseHeader := http.Header{
				tc.name:                    []string{tc.name},
				enableCircuitBreakerHeader: []string{"true"},
			}
			mockRT := &mockRoundTripper{
				response: &http.Response{
					StatusCode: tc.statusCode,
					Body:       io.NopCloser(bytes.NewBufferString(tc.name)),
					Header:     delegateResponseHeader,
				},
			}
			rt := NewRoundTripper(mockRT, &config.DefaultCircuitBreakerConfig, redisConfig)

			reqBody, err := json.Marshal(map[string]string{"key_id": "test-user-" + tc.name})
			require.NoError(t, err)
			req, err := http.NewRequest("POST", "http://example.com", bytes.NewBuffer(reqBody))
			require.NoError(t, err)

			// Make enough requests to trip the circuit breaker
			for range config.DefaultCircuitBreakerConfig.ConsecutiveFailures + 1 {
				resp, _ := rt.RoundTrip(req)

				body, err := io.ReadAll(resp.Body)
				require.NoError(t, err)

				resp.Body.Close()
				resp.Body = io.NopCloser(bytes.NewBuffer(body))

				assert.Equal(t, tc.statusCode, resp.StatusCode)
				assert.Equal(t, delegateResponseHeader, resp.Header)
				assert.Equal(t, tc.name, string(body))
				resp.Body.Close()
			}

			// Check if the circuit breaker tripped
			resp, _ := rt.RoundTrip(req)

			if tc.shouldTrip {
				body, err := io.ReadAll(resp.Body)
				require.NoError(t, err)

				resp.Body.Close()
				resp.Body = io.NopCloser(bytes.NewBuffer(body))

				circuitBreakerHeader := http.Header{
					"Retry-After": []string{(time.Duration(config.DefaultCircuitBreakerConfig.Timeout) * time.Second).String()},
				}
				assert.Equal(t, http.StatusTooManyRequests, resp.StatusCode)
				assert.Equal(t, "This endpoint has been requested too many times. Try again later.", string(body))
				assert.Equal(t, circuitBreakerHeader, resp.Header)
			} else {
				assert.Equal(t, tc.statusCode, resp.StatusCode)
			}
		})
	}
}

func TestResponseToErrorHeaderCondition(t *testing.T) {
	testCases := []struct {
		name           string
		headerValue    string
		statusCode     int
		expectedError  bool
		expectedErrMsg string
	}{
		{
			name:           "Header true with 429 status",
			headerValue:    "true",
			statusCode:     http.StatusTooManyRequests,
			expectedError:  true,
			expectedErrMsg: "rate limited",
		},
		{
			name:          "Header false with 429 status",
			headerValue:   "false",
			statusCode:    http.StatusTooManyRequests,
			expectedError: false,
		},
		{
			name:          "Missing header with 429 status",
			headerValue:   "",
			statusCode:    http.StatusTooManyRequests,
			expectedError: false,
		},
		{
			name:          "Header true with 200 status",
			headerValue:   "true",
			statusCode:    http.StatusOK,
			expectedError: false,
		},
	}

	for _, tc := range testCases {
		t.Run(tc.name, func(t *testing.T) {
			header := http.Header{}
			if tc.headerValue != "" {
				header.Set(enableCircuitBreakerHeader, tc.headerValue)
			}

			res := &http.Response{
				StatusCode: tc.statusCode,
				Header:     header,
			}

			err := responseToError(res)

			if tc.expectedError {
				require.EqualError(t, err, tc.expectedErrMsg)
			} else {
				assert.NoError(t, err)
			}
		})
	}
}

func TestRedisConfigErrors(t *testing.T) {
	mockRT := &mockRoundTripper{
		response: &http.Response{
			StatusCode: http.StatusOK,
			Body:       io.NopCloser(bytes.NewBufferString(delegateBody)),
		},
	}

	testCases := []struct {
		name        string
		redisConfig *config.RedisConfig
	}{
		{
			name:        "Nil Redis config",
			redisConfig: nil,
		},
		{
			name: "Invalid Redis URL",
			redisConfig: func() *config.RedisConfig {
				invalidURL, _ := url.Parse("invalid://localhost:6379")
				return &config.RedisConfig{
					URL: config.TomlURL{URL: *invalidURL},
				}
			}(),
		},
	}

	for _, tc := range testCases {
		t.Run(tc.name, func(t *testing.T) {
			rt := NewRoundTripper(mockRT, &config.DefaultCircuitBreakerConfig, tc.redisConfig)

			req, err := http.NewRequest("GET", "http://example.com", nil)
			require.NoError(t, err)

			resp, _ := rt.RoundTrip(req)

			body, err := io.ReadAll(resp.Body)
			require.NoError(t, err)
			resp.Body.Close()
			resp.Body = io.NopCloser(bytes.NewBuffer(body))

			// Should use delegate directly in both cases
			assert.Equal(t, http.StatusOK, resp.StatusCode)
			assert.Equal(t, delegateBody, string(body))
		})
	}
}

func TestCircuitBreakerNilRedisKey(t *testing.T) {
	redisConfig, cleanup := setupRedisConfig(t)
	defer cleanup()

	errorResp := delegateErrorResponse()
	mockRT := &mockRoundTripper{response: errorResp}
	errorResp.Body.Close()
	rt := NewRoundTripper(mockRT, &config.DefaultCircuitBreakerConfig, redisConfig)

	reqBody, err := json.Marshal(map[string]string{"not_a_key_id": "test-value"})
	require.NoError(t, err)

	req, err := http.NewRequest("POST", "http://example.com", bytes.NewBuffer(reqBody))
	require.NoError(t, err)

	testCircuitBreakerResponse(t, rt, req, delegateBody)
}

func TestCircuitBreakerRedisKeyException(t *testing.T) {
	redisConfig, cleanup := setupRedisConfig(t)
	defer cleanup()

	errorResp := delegateErrorResponse()
	mockRT := &mockRoundTripper{response: errorResp}
	errorResp.Body.Close()
	rt := NewRoundTripper(mockRT, &config.DefaultCircuitBreakerConfig, redisConfig)

	req, err := http.NewRequest("POST", "http://example.com", &errorReader{})
	require.NoError(t, err)

	testCircuitBreakerResponse(t, rt, req, delegateBody)
}

func delegateErrorResponse() *http.Response {
	return &http.Response{
		StatusCode: http.StatusTooManyRequests,
		Body:       io.NopCloser(bytes.NewBufferString(delegateBody)),
	}
}

type errorReader struct{}

func (e *errorReader) Read(_ []byte) (n int, err error) {
	return 0, errors.New("simulated read error")
}

func testCircuitBreakerResponse(t *testing.T, rt http.RoundTripper, req *http.Request, expectedBody string) {
	for range config.DefaultCircuitBreakerConfig.ConsecutiveFailures + 2 {
		resp, _ := rt.RoundTrip(req)

		body, err := io.ReadAll(resp.Body)
		require.NoError(t, err)
		resp.Body.Close()
		resp.Body = io.NopCloser(bytes.NewBuffer(body))

		assert.Equal(t, http.StatusTooManyRequests, resp.StatusCode)
		assert.Equal(t, expectedBody, string(body))
	}
}

func TestGetRedisKey(t *testing.T) {
	tests := []struct {
		name     string
		body     string
		expected string
	}{
		{
			name:     "with key_id",
			body:     `{"key_id":"123456"}`,
			expected: "gobreaker:key_id:123456",
		},
		{
			name:     "without key_id",
			body:     `{"something":"else"}`,
			expected: "",
		},
		{
			name:     "invalid json",
			body:     `not json`,
			expected: "",
		},
	}

	for _, tc := range tests {
		t.Run(tc.name, func(t *testing.T) {
			req, err := http.NewRequest("POST", "http://example.com", strings.NewReader(tc.body))
			require.NoError(t, err)

			key, _ := getRedisKey(req)
			assert.Equal(t, tc.expected, key)

			// Verify body can still be read
			body, err := io.ReadAll(req.Body)
			require.NoError(t, err)
			assert.Equal(t, tc.body, string(body))
		})
	}
}

// Create a miniredis instance
func setupRedisConfig(t *testing.T) (*config.RedisConfig, func()) {
	s, err := miniredis.Run()
	require.NoError(t, err)

	redisURL, err := url.Parse("redis://" + s.Addr())
	require.NoError(t, err)
	redisConfig := &config.RedisConfig{
		URL: config.TomlURL{URL: *redisURL},
	}

	cleanup := func() {
		s.Close()
	}

	return redisConfig, cleanup
}
