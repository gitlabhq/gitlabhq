package duoworkflow

import (
	"context"
	"net/http"
	"net/http/httptest"
	"testing"

	"github.com/stretchr/testify/require"
)

func TestSession_Context(t *testing.T) {
	t.Run("ends with the request", func(t *testing.T) {
		ctx, cancel := context.WithCancel(context.Background())
		sess := newSession(httptest.NewRequest(http.MethodGet, "/", nil).WithContext(ctx))

		require.NoError(t, sess.Context().Err())
		cancel()
		require.ErrorIs(t, sess.Context().Err(), context.Canceled)
	})

	t.Run("ends when the session is closed", func(t *testing.T) {
		sess := newSession(httptest.NewRequest(http.MethodGet, "/", nil))

		sess.Close()
		require.ErrorIs(t, sess.Context().Err(), context.Canceled)
	})
}

func TestSession_WorkflowID(t *testing.T) {
	sess := newSession(httptest.NewRequest(http.MethodGet, "/", nil))
	require.Empty(t, sess.WorkflowID())

	sess.setWorkflowID("wf-123")
	require.Equal(t, "wf-123", sess.WorkflowID())
}

func TestForwardedFor(t *testing.T) {
	tests := []struct {
		name       string
		remoteAddr string
		prior      []string
		want       string
	}{
		{name: "client IP only", remoteAddr: "192.0.2.1:1234", want: "192.0.2.1"},
		{name: "appends to a prior chain", remoteAddr: "192.0.2.1:1234", prior: []string{"10.0.0.1"}, want: "10.0.0.1, 192.0.2.1"},
		{name: "folds multiple headers", remoteAddr: "192.0.2.1:1234", prior: []string{"10.0.0.1", "10.0.0.2"}, want: "10.0.0.1, 10.0.0.2, 192.0.2.1"},
		{name: "empty without a port", remoteAddr: "invalid-address", want: ""},
	}

	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			r := httptest.NewRequest(http.MethodGet, "/", nil)
			r.RemoteAddr = tt.remoteAddr
			for _, v := range tt.prior {
				r.Header.Add("X-Forwarded-For", v)
			}

			require.Equal(t, tt.want, forwardedFor(r))
		})
	}
}
