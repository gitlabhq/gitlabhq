package upstream

import (
	"io"
	"io/ioutil"
	"net/http"
	"net/http/httptest"
	"testing"

	"github.com/sirupsen/logrus"
	"github.com/stretchr/testify/require"

	"gitlab.com/gitlab-org/gitlab/workhorse/internal/config"
)

func TestRouting(t *testing.T) {
	handle := func(u *upstream, regex string) routeEntry {
		handler := http.HandlerFunc(func(w http.ResponseWriter, _ *http.Request) {
			io.WriteString(w, regex)
		})
		return u.route("", regex, handler)
	}

	const (
		foobar = `\A/foobar\z`
		quxbaz = `\A/quxbaz\z`
		main   = ""
	)

	u := newUpstream(config.Config{}, logrus.StandardLogger(), func(u *upstream) {
		u.Routes = []routeEntry{
			handle(u, foobar),
			handle(u, quxbaz),
			handle(u, main),
		}
	})

	ts := httptest.NewServer(u)
	defer ts.Close()

	testCases := []struct {
		desc  string
		path  string
		route string
	}{
		{"main route works", "/", main},
		{"foobar route works", "/foobar", foobar},
		{"quxbaz route works", "/quxbaz", quxbaz},
		{"path traversal works, ends up in quxbaz", "/foobar/../quxbaz", quxbaz},
		{"escaped path traversal does not match any route", "/foobar%2f%2e%2e%2fquxbaz", main},
		{"double escaped path traversal does not match any route", "/foobar%252f%252e%252e%252fquxbaz", main},
	}

	for _, tc := range testCases {
		t.Run(tc.desc, func(t *testing.T) {
			resp, err := http.Get(ts.URL + tc.path)
			require.NoError(t, err)
			defer resp.Body.Close()

			body, err := ioutil.ReadAll(resp.Body)
			require.NoError(t, err)

			require.Equal(t, 200, resp.StatusCode, "response code")
			require.Equal(t, tc.route, string(body))
		})
	}
}
