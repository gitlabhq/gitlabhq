// Package transport provides a roundtripper for HTTP clients with Workhorse integration.
package transport

import (
	"fmt"
	"net"
	"net/http"
	"strings"
	"syscall"
	"time"

	"gitlab.com/gitlab-org/labkit/correlation"
	"gitlab.com/gitlab-org/labkit/tracing"

	"gitlab.com/gitlab-org/gitlab/workhorse/internal/helper"
	"gitlab.com/gitlab-org/gitlab/workhorse/internal/version"
)

var unspecifiedNetworks = []net.IPNet{
	parseCIDR("0.0.0.0/8"), /* Current network (only valid as source address) - RFC 1122, Section 3.2.1.3 */
	parseCIDR("::/128"),    /* Unspecified Address - RFC 4291 */
}

var loopbackNetworks = []net.IPNet{
	parseCIDR("127.0.0.0/8"), /* Loopback - RFC 1122, Section 3.2.1.3 */
	parseCIDR("::1/128"),     /* Loopback - RFC 4291 */
}

var privateNetworks = []net.IPNet{
	// ipv4 sourced form https://www.rfc-editor.org/rfc/rfc5735
	parseCIDR("10.0.0.0/8"),      /* Private network - RFC 1918 */
	parseCIDR("172.16.0.0/12"),   /* Private network - RFC 1918 */
	parseCIDR("192.168.0.0/16"),  /* Private network - RFC 1918 */
	parseCIDR("192.0.0.0/24"),    /* IETF Protocol Assignments - RFC 5736 */
	parseCIDR("192.0.2.0/24"),    /* TEST-NET-1, documentation and examples - RFC 5737 */
	parseCIDR("198.51.100.0/24"), /* TEST-NET-2, documentation and examples - RFC 5737 */
	parseCIDR("203.0.113.0/24"),  /* TEST-NET-3, documentation and examples - RFC 5737 */
	parseCIDR("192.88.99.0/24"),  /* IPv6 to IPv4 relay (includes 2002::/16) - RFC 3068 */
	parseCIDR("198.18.0.0/15"),   /* Network benchmark tests - RFC 2544 */
	parseCIDR("240.0.0.0/4"),     /* Reserved (former Class E network) - RFC 1112, Section 4 */
	parseCIDR("100.64.0.0/10"),   /* Shared Address Space - RFC 6598 */
	// ipv6 sourced from https://www.iana.org/assignments/iana-ipv6-special-registry/iana-ipv6-special-registry.xhtml
	parseCIDR("100::/64"),      /* Discard prefix - RFC 6666 */
	parseCIDR("2001::/23"),     /* IETF Protocol Assignments - RFC 2928 */
	parseCIDR("2001:2::/48"),   /* Benchmarking - RFC5180 */
	parseCIDR("2001:db8::/32"), /* Addresses used in documentation and example source code - RFC 3849 */
	parseCIDR("2001::/32"),     /* Teredo tunneling - RFC4380 - RFC8190 */
	parseCIDR("fc00::/7"),      /* Unique local address - RFC 4193 - RFC 8190 */
	parseCIDR("fe80::/10"),     /* Link-local address - RFC 4291 */
	parseCIDR("fec0::/10"),     /* Site-local address - RFC 3513 */
	parseCIDR("ff00::/8"),      /* Multicast - RFC 3513 */
	parseCIDR("2002::/16"),     /* 6to4 - RFC 3056 */
	parseCIDR("64:ff9b::/96"),  /* IPv4/IPv6 translation - RFC 6052 */
	parseCIDR("2001:10::/28"),  /* Deprecated (previously ORCHID) - RFC 4843 */
	parseCIDR("2001:20::/28"),  /* ORCHIDv2 - RFC7343 */
}

var lookupIPFunc = net.LookupIP

// AllowedIPError represents an error that occurs when an IP address
// is not allowed according to the security policy.
type AllowedIPError struct {
	IP      net.IP
	Message string
}

func (e *AllowedIPError) Error() string {
	return fmt.Sprintf("IP %s is not allowed: %s", e.IP.String(), e.Message)
}

// NewDefaultTransport creates a new default transport that has Workhorse's User-Agent header set.
func NewDefaultTransport() http.RoundTripper {
	return &DefaultTransport{Next: http.DefaultTransport}
}

// NewRestrictedTransport defines a http.Transport with values that are more restrictive than for
// http.DefaultTransport, they define shorter TLS Handshake, and more
// aggressive connection closing to prevent the connection hanging and reduce
// FD usage
func NewRestrictedTransport(options ...Option) http.RoundTripper {
	return &DefaultTransport{Next: newRestrictedTransport(options...)}
}

// DefaultTransport is a roundtripper that sets the User-Agent header in requests
type DefaultTransport struct {
	Next http.RoundTripper
}

// RoundTrip sets the User-Agent header in the request and then forwards the request to the next RoundTripper.
func (t DefaultTransport) RoundTrip(req *http.Request) (*http.Response, error) {
	req.Header.Set("User-Agent", version.GetUserAgent())

	return t.Next.RoundTrip(req)
}

// Option is a functional option to configure the restricted transport.
type Option func(*http.Transport)

// WithDisabledCompression disables compression for the transport.
func WithDisabledCompression() Option {
	return func(t *http.Transport) {
		t.DisableCompression = true
	}
}

// WithDialTimeout sets the dial timeout for the transport.
func WithDialTimeout(timeout time.Duration) Option {
	return func(t *http.Transport) {
		t.DialContext = (&net.Dialer{
			Timeout: timeout,
		}).DialContext
	}
}

// WithResponseHeaderTimeout sets the response header timeout for the transport.
func WithResponseHeaderTimeout(timeout time.Duration) Option {
	return func(t *http.Transport) {
		t.ResponseHeaderTimeout = timeout
	}
}

// WithSSRFFilter sets IP restrictions for the transport.
func WithSSRFFilter(allowLocalhost bool, allowedEndpoints []string) Option {
	return func(t *http.Transport) {
		t.DialContext = (&net.Dialer{
			Control: validateIPAddress(allowLocalhost, allowedEndpoints),
		}).DialContext
	}
}

func newRestrictedTransport(options ...Option) http.RoundTripper {
	t := http.DefaultTransport.(*http.Transport).Clone()

	// To avoid keep around TCP connections to http servers we're done with
	t.MaxIdleConns = 2

	// A stricter timeout for fetching from external sources that can be slow
	t.ResponseHeaderTimeout = 30 * time.Second

	for _, option := range options {
		option(t)
	}

	return tracing.NewRoundTripper(correlation.NewInstrumentedRoundTripper(t))
}

func validateIPAddress(allowLocalhost bool, allowedEndpoints []string) func(network, address string, c syscall.RawConn) error {
	return func(_, address string, _ syscall.RawConn) error {
		host, _, _ := net.SplitHostPort(address)

		ipAddress := net.ParseIP(host)

		allowed, err := ipMatchesAllowedEndpoints(ipAddress, allowedEndpoints)
		if err != nil {
			return err
		}
		if allowed {
			return nil
		}

		return checkRestrictedIP(ipAddress, allowLocalhost)
	}
}

// ipMatchesAllowedEndpoints reports whether ipAddress matches any of the
// configured allowed endpoints, resolving hostnames via DNS when necessary.
func ipMatchesAllowedEndpoints(ipAddress net.IP, allowedEndpoints []string) (bool, error) {
	for _, allowedEndpoint := range allowedEndpoints {
		hostname, err := allowedEndpointHostname(allowedEndpoint)
		if err != nil {
			return false, err
		}

		// Check if it's an IP address itself
		if ip := net.ParseIP(hostname); ip != nil {
			if ip.Equal(ipAddress) {
				return true, nil
			}
			continue // Skip DNS lookup for IP addresses
		}

		// Check if it's an IP range
		if _, network, cidrErr := net.ParseCIDR(hostname); cidrErr == nil {
			if network.Contains(ipAddress) {
				return true, nil
			}
			continue // Skip DNS lookup for IP addresses
		}

		// Perform DNS lookup
		ips, err := lookupIPFunc(hostname)
		if err != nil {
			return false, fmt.Errorf("error resolving IP address for %s: %v", hostname, err)
		}

		for _, ip := range ips {
			if ip.Equal(ipAddress) {
				return true, nil
			}
		}
	}

	return false, nil
}

// allowedEndpointHostname extracts the hostname (or IP/CIDR) portion from a
// configured endpoint, which may be a URL, a host:port pair or a bare host.
func allowedEndpointHostname(allowedEndpoint string) (string, error) {
	switch {
	case strings.Contains(allowedEndpoint, "://"):
		// It's already a URL
		return helper.URLMustParse(allowedEndpoint).Hostname(), nil
	case strings.Contains(allowedEndpoint, ":"):
		// It's a host:port format
		hostPart, _, err := net.SplitHostPort(allowedEndpoint)
		if err != nil {
			return "", fmt.Errorf("invalid host:port format: %v", err)
		}
		return hostPart, nil
	default:
		// It's a hostname
		return allowedEndpoint, nil
	}
}

// checkRestrictedIP returns an AllowedIPError when ipAddress falls into a
// network range that is not permitted for outbound connections.
func checkRestrictedIP(ipAddress net.IP, allowLocalhost bool) error {
	if ipAddress.Equal(net.IPv4bcast) {
		return &AllowedIPError{IP: ipAddress, Message: "limited broadcast IPs are not allowed"}
	}

	for _, network := range privateNetworks {
		if network.Contains(ipAddress) {
			return &AllowedIPError{IP: ipAddress, Message: "private IPs are not allowed"}
		}
	}

	if !allowLocalhost {
		for _, network := range loopbackNetworks {
			if network.Contains(ipAddress) {
				return &AllowedIPError{IP: ipAddress, Message: "loopback IPs are not allowed"}
			}
		}

		for _, network := range unspecifiedNetworks {
			if network.Contains(ipAddress) {
				return &AllowedIPError{IP: ipAddress, Message: "unspecified IPs are not allowed"}
			}
		}
	}

	if ipAddress.IsLinkLocalMulticast() || ipAddress.IsLinkLocalUnicast() {
		return &AllowedIPError{IP: ipAddress, Message: "link-local unicast and multicast IPs are not allowed"}
	}

	return nil
}

func parseCIDR(s string) net.IPNet {
	_, network, err := net.ParseCIDR(s)
	if err != nil {
		panic(fmt.Sprintf("error parsing %v: %v", s, err))
	}
	return *network
}
