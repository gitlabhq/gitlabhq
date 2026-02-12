package proxy

import (
	"crypto/tls"
	"net/http"
	"net/http/httptest"
	"net/url"
	"testing"

	"github.com/stretchr/testify/assert"
	"github.com/stretchr/testify/require"
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
