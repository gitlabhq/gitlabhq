package proxy

import (
	"fmt"
	"net/http"
	"net/http/httputil"
	"net/url"
	"time"

	"gitlab.com/gitlab-org/gitlab/workhorse/internal/helper"
)

var (
	defaultTarget = helper.URLMustParse("http://localhost")
)

type Proxy struct {
	Version                string
	reverseProxy           *httputil.ReverseProxy
	AllowResponseBuffering bool
}

func NewProxy(myURL *url.URL, version string, roundTripper http.RoundTripper) *Proxy {
	p := Proxy{Version: version, AllowResponseBuffering: true}

	if myURL == nil {
		myURL = defaultTarget
	}

	u := *myURL // Make a copy of p.URL
	u.Path = ""
	p.reverseProxy = httputil.NewSingleHostReverseProxy(&u)
	p.reverseProxy.Transport = roundTripper
	return &p
}

func (p *Proxy) ServeHTTP(w http.ResponseWriter, r *http.Request) {
	// Clone request
	req := *r
	req.Header = helper.HeaderClone(r.Header)

	// Set Workhorse version
	req.Header.Set("Gitlab-Workhorse", p.Version)
	req.Header.Set("Gitlab-Workhorse-Proxy-Start", fmt.Sprintf("%d", time.Now().UnixNano()))

	if p.AllowResponseBuffering {
		helper.AllowResponseBuffering(w)
	}

	// If the ultimate client disconnects when the response isn't fully written
	// to them yet, httputil.ReverseProxy panics with a net/http.ErrAbortHandler
	// error. We can catch and discard this to keep the error log clean
	defer func() {
		if err := recover(); err != nil {
			if err != http.ErrAbortHandler {
				panic(err)
			}
		}
	}()

	p.reverseProxy.ServeHTTP(w, &req)
}
