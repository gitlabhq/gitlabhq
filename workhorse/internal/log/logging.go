// Package log provides logging utilities
package log

import (
	"net/http"

	"github.com/sirupsen/logrus"
	"gitlab.com/gitlab-org/labkit/log"
	"gitlab.com/gitlab-org/labkit/mask"
	"golang.org/x/net/context"

	"gitlab.com/gitlab-org/gitlab/workhorse/internal/helper/exception"
)

// Fields represents logrus fields
type Fields = log.Fields

// Builder provides a fluent API for logging
type Builder struct {
	entry  *logrus.Entry
	fields log.Fields
	req    *http.Request
	err    error
}

// NewBuilder creates a new log builder
func NewBuilder() *Builder {
	return &Builder{entry: log.WithFields(nil)}
}

// WithRequest sets the request for logging
func WithRequest(r *http.Request) *Builder {
	return NewBuilder().WithRequest(r)
}

// WithRequest sets the request for logging
func (b *Builder) WithRequest(r *http.Request) *Builder {
	if r == nil {
		return b
	}

	b.req = r
	b.WithFields(log.ContextFields(r.Context())).WithFields(
		Fields{
			"method": r.Method,
			"uri":    mask.URL(r.RequestURI),
		},
	)
	return b
}

// WithFields sets the additional fields for logging
func WithFields(fields Fields) *Builder {
	return NewBuilder().WithFields(fields)
}

// WithFields sets the additional fields for logging
func (b *Builder) WithFields(fields Fields) *Builder {
	b.fields = fields
	b.entry = b.entry.WithFields(fields)
	return b
}

// WithContextFields sets the context fields for logging
func WithContextFields(ctx context.Context, fields Fields) *Builder {
	return WithFields(log.ContextFields(ctx)).WithFields(fields)
}

// WithError sets the error for logging
func WithError(err error) *Builder {
	return NewBuilder().WithError(err)
}

// WithError sets the error for logging
func (b *Builder) WithError(err error) *Builder {
	b.err = err
	b.entry = b.entry.WithError(err)
	return b
}

// Info logs informational messages
func Info(args ...interface{}) {
	NewBuilder().Info(args...)
}

// Info logs informational messages
func (b *Builder) Info(args ...interface{}) {
	b.entry.Info(args...)
}

// Error logs error messages
func Error(args ...interface{}) {
	NewBuilder().Error(args...)
}

func (b *Builder) trackException() {
	if b.err != nil {
		exception.Track(b.req, b.err, b.fields)
	}
}

// Error logs error messages
func (b *Builder) Error(args ...interface{}) {
	b.trackException()
	b.entry.Error(args...)
}

// Fatal logs fatal messages
func (b *Builder) Fatal(args ...interface{}) {
	b.trackException()
	b.entry.Fatal(args...)
}
