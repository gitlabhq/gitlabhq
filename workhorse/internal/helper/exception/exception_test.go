package exception

import (
	"net/http"
	"testing"

	"github.com/stretchr/testify/require"
)

const (
	URL           = "http://example.com"
	method        = "GET"
	authorization = "Authorization"
	token         = "token"
	secret        = "secret"
	privateToken  = "Private-Token"
	redacted      = "[redacted]"
)

func TestCleanHeaders(t *testing.T) {
	type args struct {
		createNewRequest bool
		key              string
		value            string
		expectedValue    string
	}
	tests := []struct {
		name string
		args args
	}{
		{
			name: "no request",
			args: args{
				createNewRequest: false,
			},
		},
		{
			name: "JSON header",
			args: args{
				createNewRequest: false,
				key:              "Accept",
				value:            "application/json",
				expectedValue:    "application/json",
			},
		},
		{
			name: "Authorization header",
			args: args{
				createNewRequest: true,
				key:              authorization,
				value:            secret,
				expectedValue:    "[redacted]",
			},
		},
		{
			name: "Private-Token header",
			args: args{
				createNewRequest: true,
				key:              privateToken,
				value:            secret,
				expectedValue:    "[redacted]",
			},
		},
	}

	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			var req *http.Request

			if tt.args.createNewRequest {
				req, _ = http.NewRequest(method, URL, nil)
				req.Header.Set(tt.args.key, tt.args.value)
			}

			CleanHeaders(req)

			if tt.args.createNewRequest {
				require.Equal(t, tt.args.expectedValue, req.Header.Get(tt.args.key))
			}
		})
	}
}
