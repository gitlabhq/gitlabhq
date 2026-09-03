package origincheck

import (
	"net/http"
	"testing"

	"github.com/stretchr/testify/require"
)

func TestByForwardedHost(t *testing.T) {
	tests := []struct {
		name           string
		origin         string
		host           string
		xForwardedHost string
		trustedHosts   []string
		wantAllow      bool
	}{
		{
			name:      "allows when Origin is absent",
			host:      "internal.example.com:3333",
			wantAllow: true,
		},
		{
			name:           "allows when Origin matches trusted X-Forwarded-Host",
			origin:         "https://gitlab.com",
			host:           "internal.example.com:3333",
			xForwardedHost: "gitlab.com",
			trustedHosts:   []string{"gitlab.com"},
			wantAllow:      true,
		},
		{
			name:      "allows when Origin matches Host and X-Forwarded-Host is absent",
			origin:    "https://gdk.test:3000",
			host:      "gdk.test:3000",
			wantAllow: true,
		},
		{
			name:           "rejects when X-Forwarded-Host is not trusted",
			origin:         "https://gdk.test:3000",
			host:           "gdk.test:3000",
			xForwardedHost: "other.example.com",
			trustedHosts:   []string{"gitlab.com"},
			wantAllow:      false,
		},
		{
			name:           "rejects when no trusted hosts are configured, even if X-Forwarded-Host matches Origin",
			origin:         "https://gitlab.com",
			host:           "internal.example.com:3333",
			xForwardedHost: "gitlab.com",
			trustedHosts:   nil,
			wantAllow:      false,
		},
		{
			name:           "rejects when Origin does not match trusted X-Forwarded-Host",
			origin:         "https://evil.example.com",
			host:           "internal.example.com:3333",
			xForwardedHost: "gitlab.com",
			trustedHosts:   []string{"gitlab.com"},
			wantAllow:      false,
		},
		{
			name:      "rejects when Origin does not match Host and X-Forwarded-Host is absent",
			origin:    "https://evil.example.com",
			host:      "gdk.test:3000",
			wantAllow: false,
		},
		{
			name:      "rejects when Origin is an invalid URL",
			origin:    "://not-a-url",
			host:      "gdk.test:3000",
			wantAllow: false,
		},
		{
			name:           "comparison is case-insensitive",
			origin:         "https://GitLab.COM",
			host:           "internal.example.com:3333",
			xForwardedHost: "gitlab.com",
			trustedHosts:   []string{"gitlab.com"},
			wantAllow:      true,
		},
	}

	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			r, err := http.NewRequest(http.MethodGet, "/", nil)
			require.NoError(t, err)

			r.Host = tt.host
			if tt.origin != "" {
				r.Header.Set("Origin", tt.origin)
			}
			if tt.xForwardedHost != "" {
				r.Header.Set("X-Forwarded-Host", tt.xForwardedHost)
			}

			got := ByForwardedHost(tt.trustedHosts)(r)
			require.Equal(t, tt.wantAllow, got)
		})
	}
}
