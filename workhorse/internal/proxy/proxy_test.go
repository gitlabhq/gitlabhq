package proxy

import (
	"crypto/tls"
	"net/http"
	"net/http/httptest"
	"net/url"
	"testing"

	"github.com/stretchr/testify/assert"
	"github.com/stretchr/testify/require"
	"gitlab.com/gitlab-org/labkit/correlation"
)

func TestBufferPool(t *testing.T) {
	bp := newBufferPool()

	b := bp.Get()
	assert.Len(t, b, bufferPoolSize)

	bp.Put(b) // just test that it doesn't panic or something like that
}

func TestXForwardedProto(t *testing.T) {
	tests := []struct {
		name          string
		tls           bool
		existingProto string
		expectedProto string
	}{
		{
			name:          "sets https when TLS is used",
			tls:           true,
			expectedProto: "https",
		},
		{
			name:          "sets http when TLS is not used",
			tls:           false,
			expectedProto: "http",
		},
		{
			name:          "does not override existing header",
			tls:           false,
			existingProto: "https",
			expectedProto: "https",
		},
		{
			name:          "does not override existing header when TLS is used",
			tls:           true,
			existingProto: "http",
			expectedProto: "http",
		},
	}

	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			var receivedProto string

			backend := httptest.NewServer(http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
				receivedProto = r.Header.Get("X-Forwarded-Proto")
				w.WriteHeader(http.StatusOK)
			}))
			defer backend.Close()

			backendURL, err := url.Parse(backend.URL)
			require.NoError(t, err)

			p := NewProxy(backendURL, "test", http.DefaultTransport)

			req := httptest.NewRequest(http.MethodGet, "/", nil)
			if tt.tls {
				req.TLS = &tls.ConnectionState{}
			}
			if tt.existingProto != "" {
				req.Header.Set("X-Forwarded-Proto", tt.existingProto)
			}

			rr := httptest.NewRecorder()
			p.ServeHTTP(rr, req)

			assert.Equal(t, tt.expectedProto, receivedProto)
		})
	}
}

func TestWithCorrelationID(t *testing.T) {
	testCorrelationID := "test-correlation-id-123"

	var receivedCorrelationID string
	backend := httptest.NewServer(http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		receivedCorrelationID = r.Header.Get("X-Request-ID")
		w.WriteHeader(http.StatusOK)
	}))
	defer backend.Close()

	backendURL, err := http.NewRequest("GET", backend.URL, nil)
	require.NoError(t, err)

	proxy := NewProxy(
		backendURL.URL,
		"test-version",
		http.DefaultTransport,
		WithCorrelationID(),
	)

	// Create a request with correlation ID in context
	req := httptest.NewRequest("GET", "/test", nil)
	ctx := correlation.ContextWithCorrelation(req.Context(), testCorrelationID)
	req = req.WithContext(ctx)

	rr := httptest.NewRecorder()
	proxy.ServeHTTP(rr, req)

	assert.Equal(t, testCorrelationID, receivedCorrelationID, "X-Request-ID should be forwarded to backend")
}

func TestWithCorrelationIDNotSet(t *testing.T) {
	var receivedCorrelationID string
	backend := httptest.NewServer(http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		receivedCorrelationID = r.Header.Get("X-Request-ID")
		w.WriteHeader(http.StatusOK)
	}))
	defer backend.Close()

	backendURL, err := http.NewRequest("GET", backend.URL, nil)
	require.NoError(t, err)

	proxy := NewProxy(
		backendURL.URL,
		"test-version",
		http.DefaultTransport,
		WithCorrelationID(),
	)

	// Create a request without correlation ID in context
	req := httptest.NewRequest("GET", "/test", nil)

	rr := httptest.NewRecorder()
	proxy.ServeHTTP(rr, req)

	assert.Empty(t, receivedCorrelationID, "no X-Request-ID should be set when not in context")
}

func TestWithoutCorrelationIDOption(t *testing.T) {
	testCorrelationID := "test-correlation-id-456"

	var receivedCorrelationID string
	backend := httptest.NewServer(http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		receivedCorrelationID = r.Header.Get("X-Request-ID")
		w.WriteHeader(http.StatusOK)
	}))
	defer backend.Close()

	backendURL, err := http.NewRequest("GET", backend.URL, nil)
	require.NoError(t, err)

	// Create proxy WITHOUT WithCorrelationID option
	proxy := NewProxy(
		backendURL.URL,
		"test-version",
		http.DefaultTransport,
	)

	// Create a request with correlation ID in context
	req := httptest.NewRequest("GET", "/test", nil)
	ctx := correlation.ContextWithCorrelation(req.Context(), testCorrelationID)
	req = req.WithContext(ctx)

	rr := httptest.NewRecorder()
	proxy.ServeHTTP(rr, req)

	assert.Empty(t, receivedCorrelationID, "X-Request-ID should not be forwarded without WithCorrelationID option")
}
