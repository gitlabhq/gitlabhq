package ratelimitcache

import (
	"bytes"
	"context"
	"encoding/json"
	"io"
	"net/http"
	"os"
	"strings"
	"testing"
	"time"

	redis "github.com/redis/go-redis/v9"
	"github.com/stretchr/testify/assert"
	"github.com/stretchr/testify/require"

	"gitlab.com/gitlab-org/gitlab/workhorse/internal/config"
	configRedis "gitlab.com/gitlab-org/gitlab/workhorse/internal/redis"
)

type mockRoundTripper struct {
	response *http.Response
	err      error
}

func (m *mockRoundTripper) RoundTrip(_ *http.Request) (*http.Response, error) {
	return m.response, m.err
}

func TestNewRoundTripper_NilRedis(t *testing.T) {
	mockRT := &mockRoundTripper{}
	rt := NewRoundTripper(mockRT, nil)

	// Should return delegate directly when Redis is nil
	assert.Equal(t, mockRT, rt)
}

func TestRoundTrip_ForwardsRequestWhenNotBlocked(t *testing.T) {
	rdb := InitRdb(t)

	mockRT := &mockRoundTripper{
		response: &http.Response{
			StatusCode: http.StatusOK,
			Body:       io.NopCloser(bytes.NewBufferString("success")),
			Header:     make(http.Header),
		},
	}
	rt := NewRoundTripper(mockRT, rdb)

	req := newRequestWithKeyID(t, "user-123")
	resp, err := rt.RoundTrip(req)

	require.NoError(t, err)
	assert.Equal(t, http.StatusOK, resp.StatusCode)
	resp.Body.Close()
}

func TestRoundTrip_BlocksUserOn429WithHeader(t *testing.T) {
	rdb := InitRdb(t)

	mockRT := &mockRoundTripper{
		response: &http.Response{
			StatusCode: http.StatusTooManyRequests,
			Body:       io.NopCloser(bytes.NewBufferString("rate limited")),
			Header: http.Header{
				enableCircuitBreakerHeader: []string{"true"},
				"Retry-After":              []string{"60"},
			},
		},
	}
	rt := NewRoundTripper(mockRT, rdb)

	// First request - gets 429 and records block
	req := newRequestWithKeyID(t, "blocked-user")
	resp, err := rt.RoundTrip(req)
	require.NoError(t, err)
	assert.Equal(t, http.StatusTooManyRequests, resp.StatusCode)
	resp.Body.Close()

	// Second request - should be blocked immediately
	req = newRequestWithKeyID(t, "blocked-user")
	resp, err = rt.RoundTrip(req)
	require.NoError(t, err)
	assert.Equal(t, http.StatusTooManyRequests, resp.StatusCode)

	body, _ := io.ReadAll(resp.Body)
	assert.Equal(t, errorMsg, string(body))
	assert.NotEmpty(t, resp.Header.Get("Retry-After"))
	resp.Body.Close()
}

func TestRoundTrip_DoesNotBlockWithoutHeader(t *testing.T) {
	rdb := InitRdb(t)

	// 429 without enableCircuitBreakerHeader should not trigger blocking
	mockRT := &mockRoundTripper{
		response: &http.Response{
			StatusCode: http.StatusTooManyRequests,
			Body:       io.NopCloser(bytes.NewBufferString("rate limited")),
			Header: http.Header{
				"Retry-After": []string{"60"},
				// Missing enableCircuitBreakerHeader
			},
		},
	}
	rt := NewRoundTripper(mockRT, rdb)

	// First request - gets 429 but should NOT record block
	req := newRequestWithKeyID(t, "user-no-header")
	resp, err := rt.RoundTrip(req)
	require.NoError(t, err)
	assert.Equal(t, http.StatusTooManyRequests, resp.StatusCode)
	resp.Body.Close()

	// Second request - should still go to delegate (not blocked)
	req = newRequestWithKeyID(t, "user-no-header")
	resp, err = rt.RoundTrip(req)
	require.NoError(t, err)

	// Body should be from delegate, not the blocked response
	body, _ := io.ReadAll(resp.Body)
	assert.Equal(t, "rate limited", string(body))
	resp.Body.Close()
}

func TestRoundTrip_MissingKeyID(t *testing.T) {
	rdb := InitRdb(t)

	mockRT := &mockRoundTripper{
		response: &http.Response{
			StatusCode: http.StatusOK,
			Body:       io.NopCloser(bytes.NewBufferString("ok")),
			Header:     make(http.Header),
		},
	}
	rt := NewRoundTripper(mockRT, rdb)

	// Request without key_id in body
	body, _ := json.Marshal(map[string]string{"other": "value"})
	req, _ := http.NewRequest("POST", "http://example.com", bytes.NewBuffer(body))

	resp, err := rt.RoundTrip(req)

	require.NoError(t, err)
	assert.Equal(t, http.StatusOK, resp.StatusCode)
	resp.Body.Close()
}

func TestGetUserKey(t *testing.T) {
	tests := []struct {
		name     string
		body     string
		expected string
	}{
		{
			name:     "with key_id",
			body:     `{"key_id":"123456"}`,
			expected: "123456",
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

			key, _ := getUserKey(req)
			assert.Equal(t, tc.expected, key)

			// Verify body can still be read
			body, err := io.ReadAll(req.Body)
			require.NoError(t, err)
			assert.Equal(t, tc.body, string(body))
		})
	}
}

func TestGetUserKey_NilBody(t *testing.T) {
	req, _ := http.NewRequest("GET", "http://example.com", nil)
	_, err := getUserKey(req)
	assert.Error(t, err)
}

func TestGetUserKey_BodyTooLarge(t *testing.T) {
	largeBodySize := maxBodySize + 10
	largeBody := strings.Repeat("x", largeBodySize*1024)
	req, err := http.NewRequest("POST", "http://example.com", strings.NewReader(largeBody))
	require.NoError(t, err)

	_, err = getUserKey(req)
	require.Error(t, err)
	assert.Contains(t, err.Error(), "key not found")

	// Verify body is reconstructed
	body, err := io.ReadAll(req.Body)
	require.NoError(t, err)
	assert.Len(t, largeBody, len(body))
	assert.Equal(t, largeBody, string(body))
}

func TestRoundTrip_LargeBodyForwardsToDelegate(t *testing.T) {
	rdb := InitRdb(t)

	mockRT := &mockRoundTripper{
		response: &http.Response{
			StatusCode: http.StatusOK,
			Body:       io.NopCloser(bytes.NewBufferString("success")),
			Header:     make(http.Header),
		},
	}
	rt := NewRoundTripper(mockRT, rdb)

	largeBody := strings.Repeat("x", maxBodySize*1024)
	req, err := http.NewRequest("POST", "http://example.com", strings.NewReader(largeBody))
	require.NoError(t, err)

	resp, err := rt.RoundTrip(req)
	require.NoError(t, err)
	assert.Equal(t, http.StatusOK, resp.StatusCode)
	body, err := io.ReadAll(resp.Body)
	require.NoError(t, err)
	assert.Equal(t, "success", string(body))
	resp.Body.Close()
}

func TestParseRetryAfter(t *testing.T) {
	tests := []struct {
		name    string
		value   string
		wantOK  bool
		checkFn func(t *testing.T, blockedUntil time.Time)
	}{
		{
			name:   "valid seconds",
			value:  "60",
			wantOK: true,
			checkFn: func(t *testing.T, blockedUntil time.Time) {
				assert.WithinDuration(t, time.Now().Add(60*time.Second), blockedUntil, 2*time.Second)
			},
		},
		{
			name:   "empty value",
			value:  "",
			wantOK: false,
		},
		{
			name:   "invalid value",
			value:  "not-a-number",
			wantOK: false,
		},
	}

	for _, tc := range tests {
		t.Run(tc.name, func(t *testing.T) {
			blockedUntil, ok := parseRetryAfter(tc.value)

			assert.Equal(t, tc.wantOK, ok)
			if tc.checkFn != nil {
				tc.checkFn(t, blockedUntil)
			}
		})
	}
}

func TestIsBlockApplicable(t *testing.T) {
	tests := []struct {
		name       string
		statusCode int
		header     string
		expected   bool
	}{
		{"429 with header true", http.StatusTooManyRequests, "true", true},
		{"429 with header false", http.StatusTooManyRequests, "false", false},
		{"429 without header", http.StatusTooManyRequests, "", false},
		{"200 with header true", http.StatusOK, "true", false},
	}

	for _, tc := range tests {
		t.Run(tc.name, func(t *testing.T) {
			header := make(http.Header)
			if tc.header != "" {
				header.Set(enableCircuitBreakerHeader, tc.header)
			}

			resp := &http.Response{
				StatusCode: tc.statusCode,
				Header:     header,
			}

			assert.Equal(t, tc.expected, isBlockApplicable(resp))
		})
	}
}

func TestBlockedResponse(t *testing.T) {
	blockedUntil := time.Now().Add(30 * time.Second)
	resp := blockedResponse(blockedUntil, "user-123")

	assert.Equal(t, http.StatusTooManyRequests, resp.StatusCode)
	assert.NotEmpty(t, resp.Header.Get("Retry-After"))

	body, _ := io.ReadAll(resp.Body)
	assert.Equal(t, errorMsg, string(body))
	resp.Body.Close()
}

func TestBlockedResponse_ExpiredBlock(t *testing.T) {
	blockedUntil := time.Now().Add(-10 * time.Second)
	resp := blockedResponse(blockedUntil, "user-123")

	assert.Equal(t, "0", resp.Header.Get("Retry-After"))
	resp.Body.Close()
}

func newRequestWithKeyID(t *testing.T, keyID string) *http.Request {
	body, err := json.Marshal(map[string]string{"key_id": keyID})
	require.NoError(t, err)
	req, err := http.NewRequest("POST", "http://example.com", bytes.NewBuffer(body))
	require.NoError(t, err)
	return req
}

func InitRdb(t *testing.T) *redis.Client {
	buf, err := os.ReadFile("../../config.toml")
	require.NoError(t, err)
	cfg, err := config.LoadConfig(string(buf))
	require.NoError(t, err)
	rdb, err := configRedis.Configure(cfg)
	require.NoError(t, err)
	t.Cleanup(func() {
		rdb.FlushAll(context.Background())
		assert.NoError(t, rdb.Close())
	})
	return rdb
}
