package transport

import (
	"net"
	"testing"

	"github.com/stretchr/testify/require"
)

func TestNewDefaultTransport(t *testing.T) {
	require.IsType(t, &DefaultTransport{}, NewDefaultTransport())
}

func TestValidateIpAddress(t *testing.T) {
	// Save the original lookup IP function to restore later
	originalLookupIP := lookupIPFunc
	defer func() { lookupIPFunc = originalLookupIP }()

	lookupIPFunc = func(_ string) ([]net.IP, error) {
		return []net.IP{net.ParseIP("192.0.2.1")}, nil
	}

	tests := []struct {
		name             string
		address          string
		allowedEndpoints []string
		allowLocal       bool
		errorMessage     string
	}{
		{
			name:             "Public IP Address",
			address:          "93.184.215.14:80",
			allowedEndpoints: nil,
			allowLocal:       false,
		},
		{
			name:             "Private IP Address",
			address:          "192.168.0.0:80",
			allowedEndpoints: nil,
			allowLocal:       false,
			errorMessage:     "IP 192.168.0.0 is not allowed: private IPs are not allowed",
		},
		{
			name:             "Private IP Address",
			address:          "172.16.0.0:80",
			allowedEndpoints: nil,
			allowLocal:       false,
			errorMessage:     "IP 172.16.0.0 is not allowed: private IPs are not allowed",
		},
		{
			name:             "Private IP Address with allowed endpoint in URL format",
			address:          "172.16.123.1:9000",
			allowedEndpoints: []string{"http://172.16.123.1:9000"},
			allowLocal:       false,
		},
		{
			name:             "Private IP Address with allowed endpoint in host:port format",
			address:          "172.16.123.1:9000",
			allowedEndpoints: []string{"172.16.123.1:9000"},
			allowLocal:       false,
		},
		{
			name:             "Private IP Address with allowed endpoint as IP address",
			address:          "172.16.123.1:9000",
			allowedEndpoints: []string{"172.16.123.1"},
			allowLocal:       false,
		},
		{
			name:             "Private IP Address with allowed endpoint as host",
			address:          "192.0.2.1:9000",
			allowedEndpoints: []string{"example.com"},
			allowLocal:       false,
		},
		{
			name:             "Private IPv6 Address",
			address:          "[fd00::1]:80",
			allowedEndpoints: nil,
			allowLocal:       false,
			errorMessage:     "IP fd00::1 is not allowed: private IPs are not allowed",
		},
		{
			name:             "Loopback IP Address",
			address:          "127.0.0.1:80",
			allowedEndpoints: nil,
			allowLocal:       false,
			errorMessage:     "IP 127.0.0.1 is not allowed: loopback IPs are not allowed",
		},
		{
			name:             "Loopback IP Address with Allow Localhost",
			address:          "127.0.0.1:80",
			allowedEndpoints: nil,
			allowLocal:       true,
		},
		{
			name:             "Loopback IPv6 Address",
			address:          "[0000:0000:0000:0000:0000:0000:0000:0001]:80",
			allowedEndpoints: nil,
			allowLocal:       false,
			errorMessage:     "IP ::1 is not allowed: loopback IPs are not allowed",
		},
		{
			name:             "Loopback IPv6 Address",
			address:          "[::1]:80",
			allowedEndpoints: nil,
			allowLocal:       false,
			errorMessage:     "IP ::1 is not allowed: loopback IPs are not allowed",
		},
		{
			name:             "Localhost IP Address",
			address:          "0.0.0.0:80",
			allowedEndpoints: nil,
			allowLocal:       false,
			errorMessage:     "IP 0.0.0.0 is not allowed: unspecified IPs are not allowed",
		},
		{
			name:             "Localhost IP Address with Allow Localhost",
			address:          "0.0.0.0:80",
			allowedEndpoints: nil,
			allowLocal:       true,
		},
		{
			name:             "Link-Local Multicast IP Address",
			address:          "224.0.0.0:80",
			allowedEndpoints: nil,
			allowLocal:       false,
			errorMessage:     "IP 224.0.0.0 is not allowed: link-local unicast and multicast IPs are not allowed",
		},
		{
			name:             "Link-Local Unicast IP Address",
			address:          "169.254.0.0:80",
			allowedEndpoints: nil,
			allowLocal:       false,
			errorMessage:     "IP 169.254.0.0 is not allowed: link-local unicast and multicast IPs are not allowed",
		},
		{
			name:             "Broadcast IP Address",
			address:          "255.255.255.255:80",
			allowedEndpoints: nil,
			allowLocal:       false,
			errorMessage:     "IP 255.255.255.255 is not allowed: limited broadcast IPs are not allowed",
		},
	}

	for _, tc := range tests {
		t.Run(tc.name, func(t *testing.T) {
			err := validateIPAddress(tc.allowLocal, tc.allowedEndpoints)("", tc.address, nil)
			if tc.errorMessage != "" {
				require.EqualError(t, err, tc.errorMessage)
			} else {
				require.NoError(t, err)
			}
		})
	}
}

func TestParseCIDR(t *testing.T) {
	network := parseCIDR("192.168.0.0/24")
	require.True(t, network.Contains(net.ParseIP("192.168.0.0")))
}

func TestParseCIDRPanic(t *testing.T) {
	defer func() {
		if r := recover(); r == nil {
			t.Fatal("expected panic")
		}
	}()
	parseCIDR("192.168")
}
