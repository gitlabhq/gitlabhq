package forwardheaders

import (
	"net/http"
	"net/http/httptest"
	"testing"

	"maps"

	"github.com/stretchr/testify/require"
)

var upstreamHeaders = http.Header{
	"X-Protected-Header1": []string{"protected1_from_upstream"},
	"X-Protected-Header2": []string{"protected2_from_upstream"},
	"X-Custom-Header1":    []string{"custom1_from_upstream"},
	"X-Custom-Header2":    []string{"custom2_from_upstream"},
}

func TestForwardResponseHeaders(t *testing.T) {
	testCases := []struct {
		desc                          string
		params                        Params
		protectedHeaders              []string
		extraHeaders                  http.Header
		upstreamContentType           string
		responseWriterHeaders         http.Header
		expectedResponseWriterHeaders http.Header
	}{
		{
			desc:                  "with restricted headers enabled",
			params:                Params{Enabled: true, AllowList: []string{"content-type", "x-custom-header1"}},
			protectedHeaders:      []string{"x-protected-header1"},
			extraHeaders:          http.Header{"X-Extra-Header": []string{"test"}},
			upstreamContentType:   "multipart/x-mixed-replace",
			responseWriterHeaders: http.Header{"X-Protected-Header1": []string{"protected1_from_response_writer"}},
			expectedResponseWriterHeaders: http.Header{
				"Content-Type":        []string{"application/octet-stream"},
				"X-Protected-Header1": []string{"protected1_from_response_writer"},
				"X-Custom-Header1":    []string{"custom1_from_upstream"},
				"X-Extra-Header":      []string{"test"},
			},
		},
		{
			desc:                  "with restrict headers disabled",
			params:                Params{Enabled: false, AllowList: []string{}},
			protectedHeaders:      []string{"x-protected-header1"},
			extraHeaders:          http.Header{"X-Extra-Header": []string{"test"}},
			upstreamContentType:   "multipart/x-mixed-replace",
			responseWriterHeaders: http.Header{"X-Protected-Header1": []string{"protected1_from_response_writer"}},
			expectedResponseWriterHeaders: http.Header{
				"Content-Type":        []string{"multipart/x-mixed-replace"},
				"X-Protected-Header1": []string{"protected1_from_response_writer"},
				"X-Protected-Header2": []string{"protected2_from_upstream"},
				"X-Custom-Header1":    []string{"custom1_from_upstream"},
				"X-Custom-Header2":    []string{"custom2_from_upstream"},
				"X-Extra-Header":      []string{"test"},
			},
		},
		{
			desc:                  "with no protected headers",
			params:                Params{Enabled: true, AllowList: []string{"content-type"}},
			protectedHeaders:      []string{},
			extraHeaders:          http.Header{"X-Extra-Header": []string{"test"}},
			upstreamContentType:   "multipart/x-mixed-replace",
			responseWriterHeaders: http.Header{"X-Protected-Header1": []string{"protected1_from_response_writer"}},
			expectedResponseWriterHeaders: http.Header{
				"Content-Type":        []string{"application/octet-stream"},
				"X-Protected-Header1": []string{"protected1_from_response_writer"},
				"X-Extra-Header":      []string{"test"},
			},
		},
		{
			desc:                  "with non restricted content-type",
			params:                Params{Enabled: true, AllowList: []string{"content-type"}},
			protectedHeaders:      []string{},
			extraHeaders:          http.Header{},
			upstreamContentType:   "application/xml",
			responseWriterHeaders: http.Header{},
			expectedResponseWriterHeaders: http.Header{
				"Content-Type": []string{"application/xml"},
			},
		},
	}

	for _, tc := range testCases {
		w := httptest.NewRecorder()
		maps.Copy(w.Header(), tc.responseWriterHeaders)

		upstreamResp := &http.Response{Header: upstreamHeaders}
		upstreamResp.Header.Set("Content-Type", tc.upstreamContentType)

		tc.params.ForwardResponseHeaders(w, upstreamResp, tc.protectedHeaders, tc.extraHeaders)

		require.Equal(t, tc.expectedResponseWriterHeaders, w.Header())
	}
}
