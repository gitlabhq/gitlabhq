package log

import (
	"net/http"

	"github.com/sirupsen/logrus"
	"gitlab.com/gitlab-org/labkit/log"
	"gitlab.com/gitlab-org/labkit/mask"
	"golang.org/x/net/context"

	"gitlab.com/gitlab-org/gitlab/workhorse/internal/helper"
)

type Fields = log.Fields

type Builder struct {
	entry  *logrus.Entry
	fields log.Fields
	req    *http.Request
	err    error
}

func NewBuilder() *Builder {
	return &Builder{entry: log.WithFields(nil)}
}

func WithRequest(r *http.Request) *Builder {
	return NewBuilder().WithRequest(r)
}

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

func WithFields(fields Fields) *Builder {
	return NewBuilder().WithFields(fields)
}

func (b *Builder) WithFields(fields Fields) *Builder {
	b.fields = fields
	b.entry = b.entry.WithFields(fields)
	return b
}

func WithContextFields(ctx context.Context, fields Fields) *Builder {
	return WithFields(log.ContextFields(ctx)).WithFields(fields)
}

func WithError(err error) *Builder {
	return NewBuilder().WithError(err)
}

func (b *Builder) WithError(err error) *Builder {
	b.err = err
	b.entry = b.entry.WithError(err)
	return b
}

func Info(args ...interface{}) {
	NewBuilder().Info(args...)
}

func (b *Builder) Info(args ...interface{}) {
	b.entry.Info(args...)
}

func Error(args ...interface{}) {
	NewBuilder().Error(args...)
}

func (b *Builder) Error(args ...interface{}) {
	b.entry.Error(args...)

	if b.req != nil && b.err != nil {
		helper.CaptureRavenError(b.req, b.err, b.fields)
	}
}
