package log

import (
	"bytes"
	"context"
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

// captureLogsFromStdLogger redirects the standard logger (which backs NewBuilder)
// and returns output produced during fn's execution.
func captureLogsFromStdLogger(fn func()) string {
	b := NewBuilder()
	return captureLogs(b, fn)
}

func TestPackageLevelInfo(t *testing.T) {
	logLine := captureLogsFromStdLogger(func() {
		Info("package level observation")
	})

	require.Contains(t, logLine, "level=info")
	require.Contains(t, logLine, "package level observation")
}

func TestPackageLevelError(t *testing.T) {
	logLine := captureLogsFromStdLogger(func() {
		Error("package level error")
	})

	require.Contains(t, logLine, "level=error")
	require.Contains(t, logLine, "package level error")
}

func TestPackageLevelWithError(t *testing.T) {
	logLine := captureLogsFromStdLogger(func() {
		WithError(fmt.Errorf("pkg error")).Error("something failed")
	})

	require.Contains(t, logLine, "level=error")
	require.Contains(t, logLine, `error="pkg error"`)
	require.Contains(t, logLine, "something failed")
}

func TestPackageLevelWithRequest(t *testing.T) {
	r := httptest.NewRequest("POST", "http://localhost:3000/upload", nil)
	logLine := captureLogsFromStdLogger(func() {
		WithRequest(r).Info("handling upload")
	})

	require.Contains(t, logLine, "level=info")
	require.Contains(t, logLine, "method=POST")
	require.Contains(t, logLine, `uri="http://localhost:3000/upload"`)
	require.Contains(t, logLine, "handling upload")
}

func TestPackageLevelWithFields(t *testing.T) {
	logLine := captureLogsFromStdLogger(func() {
		WithFields(Fields{"component": "proxy", "backend": "rails"}).Info("forwarding request")
	})

	require.Contains(t, logLine, "level=info")
	require.Contains(t, logLine, "component=proxy")
	require.Contains(t, logLine, "backend=rails")
	require.Contains(t, logLine, "forwarding request")
}

func TestWithContextFields(t *testing.T) {
	ctx := context.Background()
	b := NewBuilder()

	logLine := captureLogs(b, func() {
		WithContextFields(ctx, Fields{"traced_component": "upload"}).Info("context fields log")
	})

	require.Contains(t, logLine, "level=info")
	require.Contains(t, logLine, "traced_component=upload")
	require.Contains(t, logLine, "context fields log")
}

func TestBuilderWithRequestMasksSecretURLParams(t *testing.T) {
	tests := []struct {
		name        string
		uri         string
		wantMasked  []string
		wantPresent []string
	}{
		{
			name:        "certificate param is filtered",
			uri:         "http://localhost/path?certificate=secret-cert",
			wantMasked:  []string{"secret-cert"},
			wantPresent: []string{"certificate=[FILTERED]"},
		},
		{
			name:        "sharedSecret param is filtered",
			uri:         "http://localhost/path?sharedSecret=topsecret",
			wantMasked:  []string{"topsecret"},
			wantPresent: []string{"sharedSecret=[FILTERED]"},
		},
		{
			name:        "non-sensitive params are preserved",
			uri:         "http://localhost/path?page=2&per_page=50",
			wantMasked:  []string{},
			wantPresent: []string{"page=2", "per_page=50"},
		},
	}

	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			r := httptest.NewRequest("GET", tt.uri, nil)
			b := NewBuilder()

			logLine := captureLogs(b, func() {
				b.WithRequest(r).Info("request received")
			})

			for _, secret := range tt.wantMasked {
				require.NotContains(t, logLine, secret)
			}
			for _, want := range tt.wantPresent {
				require.Contains(t, logLine, want)
			}
		})
	}
}
