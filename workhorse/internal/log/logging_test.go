package log

import (
	"bytes"
	"fmt"
	"net/http"
	"net/http/httptest"
	"testing"

	"github.com/stretchr/testify/require"
)

func captureLogs(b *Builder, testFn func()) string {
	buf := &bytes.Buffer{}

	logger := b.entry.Logger
	oldOut := logger.Out
	logger.Out = buf
	defer func() {
		logger.Out = oldOut
	}()

	testFn()

	return buf.String()
}

func TestLogInfo(t *testing.T) {
	b := NewBuilder()
	logLine := captureLogs(b, func() {
		b.Info("an observation")
	})

	require.Regexp(t, `level=info msg="an observation"`, logLine)
}

func TestLogError(t *testing.T) {
	b := NewBuilder()
	logLine := captureLogs(b, func() {
		b.WithError(fmt.Errorf("the error")).Error()
	})

	require.Regexp(t, `level=error error="the error"`, logLine)
}

func TestLogErrorWithMessage(t *testing.T) {
	b := NewBuilder()
	logLine := captureLogs(b, func() {
		b.WithError(fmt.Errorf("the error")).Error("an error occurred")
	})

	require.Regexp(t, `level=error msg="an error occurred" error="the error"`, logLine)
}

func TestLogErrorWithRequest(t *testing.T) {
	tests := []struct {
		name        string
		method      string
		uri         string
		err         error
		logMatchers []string
	}{
		{
			name: "nil_request",
			err:  fmt.Errorf("cause"),
			logMatchers: []string{
				`level=error error=cause`,
			},
		},
		{
			name: "nil_request_nil_error",
			err:  nil,
			logMatchers: []string{
				`level=error error="<nil>"`,
			},
		},
		{
			name:   "basic_url",
			method: "GET",
			uri:    "http://localhost:3000/",
			err:    fmt.Errorf("cause"),
			logMatchers: []string{
				`level=error correlation_id= error=cause method=GET uri="http://localhost:3000/"`,
			},
		},
		{
			name:   "secret_url",
			method: "GET",
			uri:    "http://localhost:3000/path?certificate=123&sharedSecret=123&import_url=the_url&my_password_string=password",
			err:    fmt.Errorf("cause"),
			logMatchers: []string{
				`level=error correlation_id= error=cause method=GET uri="http://localhost:3000/path\?certificate=\[FILTERED\]&sharedSecret=\[FILTERED\]&import_url=\[FILTERED\]&my_password_string=\[FILTERED\]"`,
			},
		},
	}

	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			b := NewBuilder()

			var r *http.Request
			if tt.uri != "" {
				r = httptest.NewRequest(tt.method, tt.uri, nil)
			}

			logLine := captureLogs(b, func() {
				b.WithRequest(r).WithError(tt.err).Error()
			})

			for _, v := range tt.logMatchers {
				require.Regexp(t, v, logLine)
			}
		})
	}
}

func TestLogErrorWithFields(t *testing.T) {
	tests := []struct {
		name       string
		request    *http.Request
		err        error
		fields     map[string]interface{}
		logMatcher string
	}{
		{
			name:       "nil_request",
			err:        fmt.Errorf("cause"),
			fields:     map[string]interface{}{"extra_one": 123},
			logMatcher: `level=error error=cause extra_one=123`,
		},
		{
			name:       "nil_request_nil_error",
			err:        nil,
			fields:     map[string]interface{}{"extra_one": 123, "extra_two": "test"},
			logMatcher: `level=error error="<nil>" extra_one=123 extra_two=test`,
		},
		{
			name:       "basic_url",
			request:    httptest.NewRequest("GET", "http://localhost:3000/", nil),
			err:        fmt.Errorf("cause"),
			fields:     map[string]interface{}{"extra_one": 123, "extra_two": "test"},
			logMatcher: `level=error correlation_id= error=cause extra_one=123 extra_two=test method=GET uri="http://localhost:3000/`,
		},
	}

	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			b := NewBuilder()

			logLine := captureLogs(b, func() {
				b.WithRequest(tt.request).WithFields(tt.fields).WithError(tt.err).Error()
			})

			require.Contains(t, logLine, tt.logMatcher)
		})
	}
}
