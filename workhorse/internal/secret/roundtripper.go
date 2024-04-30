package secret

import (
	"net/http"
)

const (
	// RequestHeader carries the JWT token for gitlab-rails
	RequestHeader = "Gitlab-Workhorse-Api-Request"
)

type roundTripper struct {
	next    http.RoundTripper
	version string
}

// NewRoundTripper creates a RoundTripper that adds the JWT token header to a
// request. This is used to verify that a request came from workhorse
func NewRoundTripper(next http.RoundTripper, version string) http.RoundTripper {
	return &roundTripper{next: next, version: version}
}

func (r *roundTripper) RoundTrip(req *http.Request) (*http.Response, error) {
	tokenString, err := JWTTokenString(DefaultClaims)
	if err != nil {
		return nil, err
	}

	// Set a custom header for the request. This can be used in some
	// configurations (Passenger) to solve auth request routing problems.
	req.Header.Set("Gitlab-Workhorse", r.version)
	req.Header.Set(RequestHeader, tokenString)

	return r.next.RoundTrip(req)
}
