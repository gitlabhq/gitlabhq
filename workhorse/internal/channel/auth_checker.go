package channel

import (
	"errors"
	"net/http"
	"time"

	"gitlab.com/gitlab-org/gitlab/workhorse/internal/api"
)

type AuthCheckerFunc func() *api.ChannelSettings

// Regularly checks that authorization is still valid for a channel, outputting
// to the stopper when it isn't
type AuthChecker struct {
	Checker  AuthCheckerFunc
	Template *api.ChannelSettings
	StopCh   chan error
	Done     chan struct{}
	Count    int64
}

var ErrAuthChanged = errors.New("connection closed: authentication changed or endpoint unavailable")

func NewAuthChecker(f AuthCheckerFunc, template *api.ChannelSettings, stopCh chan error) *AuthChecker {
	return &AuthChecker{
		Checker:  f,
		Template: template,
		StopCh:   stopCh,
		Done:     make(chan struct{}),
	}
}
func (c *AuthChecker) Loop(interval time.Duration) {
	for {
		select {
		case <-time.After(interval):
			settings := c.Checker()
			if !c.Template.IsEqual(settings) {
				c.StopCh <- ErrAuthChanged
				return
			}
			c.Count = c.Count + 1
		case <-c.Done:
			return
		}
	}
}

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
		defer httpResponse.Body.Close()

		if httpResponse.StatusCode != http.StatusOK || authResponse == nil {
			return nil
		}

		return authResponse.Channel
	}
}
