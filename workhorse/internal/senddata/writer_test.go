package senddata

import (
	"io"
	"net/http"
	"net/http/httptest"
	"strings"
	"testing"

	"github.com/stretchr/testify/require"

	"gitlab.com/gitlab-org/gitlab/workhorse/internal/headers"
)

func TestWriter(t *testing.T) {
	upstreamResponse := "hello world"

	testCases := []struct {
		desc        string
		headerValue string
		out         string
	}{
		{
			desc:        "inject",
			headerValue: testInjecterName + ":" + testInjecterName,
			out:         testInjecterData,
		},
		{
			desc:        "pass",
			headerValue: "",
			out:         upstreamResponse,
		},
	}

	for _, tc := range testCases {
		t.Run(tc.desc, func(t *testing.T) {
			recorder := httptest.NewRecorder()
			rw := &sendDataResponseWriter{rw: recorder, injecters: []Injecter{&testInjecter{}}}

			rw.Header().Set(headers.GitlabWorkhorseSendDataHeader, tc.headerValue)

			n, err := rw.Write([]byte(upstreamResponse))
			require.NoError(t, err)
			require.Len(t, upstreamResponse, n, "bytes written")

			recorder.Flush()

			body := recorder.Result().Body
			data, err := io.ReadAll(body)
			require.NoError(t, err)
			require.NoError(t, body.Close())

			require.Equal(t, tc.out, string(data))
		})
	}
}

const (
	testInjecterName = "test-injecter"
	testInjecterData = "hello this is injected data"
)

type testInjecter struct{}

func (ti *testInjecter) Inject(w http.ResponseWriter, _ *http.Request, _ string) {
	io.WriteString(w, testInjecterData)
}

func (ti *testInjecter) Match(s string) bool { return strings.HasPrefix(s, testInjecterName+":") }
func (ti *testInjecter) Name() string        { return testInjecterName }
