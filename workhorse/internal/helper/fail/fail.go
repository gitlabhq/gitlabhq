// Package fail provides functionality for handling failure responses in HTTP requests
package fail

import (
	"net/http"

	"gitlab.com/gitlab-org/gitlab/workhorse/internal/log"
)

type failure struct {
	status int
	body   string
	fields log.Fields
}

// Option represents a function that modifies a failure object
type Option func(*failure)

// WithStatus sets the HTTP status and body text of the failure response.
func WithStatus(status int) Option {
	return func(f *failure) {
		f.status = status
		f.body = http.StatusText(status)
	}
}

// WithBody sets the body text of the failure response. Note that
// subsequent applications of WithStatus will override the response body.
func WithBody(body string) Option { return func(f *failure) { f.body = body } }

// WithFields adds log fields to the failure log message.
func WithFields(fields log.Fields) Option { return func(f *failure) { f.fields = fields } }

// Request combines error handling actions for a failed HTTP request. By
// default it writes a generic HTTP 500 response to w. The status code
// and response body can be modified by passing options. The value of
// err, if non nil, is logged and reported to Sentry.
func Request(w http.ResponseWriter, r *http.Request, err error, options ...Option) {
	f := &failure{}
	WithStatus(http.StatusInternalServerError)(f)
	for _, opt := range options {
		opt(f)
	}

	http.Error(w, f.body, f.status)
	log.WithRequest(r).WithFields(f.fields).WithError(err).Error()
}
