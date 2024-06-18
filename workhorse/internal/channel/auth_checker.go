// Package channel provides functionality for handling authentication and channel settings.
package channel

import (
	"errors"
	"net/http"
	"time"

	"gitlab.com/gitlab-org/gitlab/workhorse/internal/api"
)

// AuthCheckerFunc represents a function type used for checking authentication.
type AuthCheckerFunc func() *api.ChannelSettings

// AuthChecker represents an object responsible for checking authentication.
type AuthChecker struct {
	Checker  AuthCheckerFunc
	Template *api.ChannelSettings
	StopCh   chan error
	Done     chan struct{}
	Count    int64
}

// ErrAuthChanged represents an error indicating that the connection was closed due to authentication changes or an unavailable endpoint.
var ErrAuthChanged = errors.New("connection closed: authentication changed or endpoint unavailable")

// NewAuthChecker creates a new instance of AuthChecker with the provided parameters.
func NewAuthChecker(f AuthCheckerFunc, template *api.ChannelSettings, stopCh chan error) *AuthChecker {
	return &AuthChecker{
		Checker:  f,
		Template: template,
		StopCh:   stopCh,
		Done:     make(chan struct{}),
	}
}

// Loop continuously checks authentication and updates the channel settings.
func (c *AuthChecker) Loop(interval time.Duration) {
	for {
		select {
		case <-time.After(interval):
			settings := c.Checker()
			if !c.Template.IsEqual(settings) {
				c.StopCh <- ErrAuthChanged
				return
			}
			c.Count++
		case <-c.Done:
			return
		}
	}
}

// Close closes the AuthChecker and releases any resources.
func (c *AuthChecker) Close() error {
	close(c.Done)
	return nil
}

// Generates a CheckerFunc from an *api.API + request needing authorization
func authCheckFunc(myAPI *api.API, r *http.Request, suffix string) AuthCheckerFunc {
	return func() *api.ChannelSettings {
		httpResponse, authResponse, err := myAPI.PreAuthorize(suffix, r)
		if err != nil {
			return nil
		}
		defer func() { _ = httpResponse.Body.Close() }()

		if httpResponse.StatusCode != http.StatusOK || authResponse == nil {
			return nil
		}

		return authResponse.Channel
	}
}
