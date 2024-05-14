// Package proxy provides functionality for configuring and using a proxy server.
package proxy

import (
	"fmt"
	"net/http"
	"net/http/httputil"
	"net/url"
	"sync"
	"time"

	"gitlab.com/gitlab-org/gitlab/workhorse/internal/helper"
	"gitlab.com/gitlab-org/gitlab/workhorse/internal/helper/nginx"
)

const (
	// matches the default size used in httputil.ReverseProxy
	bufferPoolSize = 32 * 1024
)

var (
	defaultTarget = helper.URLMustParse("http://localhost")

	// pool is a buffer pool that is shared across all Proxy instances to maximize buffer reuse.
	pool = newBufferPool()
)

// Proxy represents a proxy configuration with various settings.
type Proxy struct {
	Version                string
	reverseProxy           *httputil.ReverseProxy
	AllowResponseBuffering bool
	customHeaders          map[string]string
	forceTargetHostHeader  bool
}

// WithCustomHeaders is a function that returns a configuration function to set custom headers for a proxy.
func WithCustomHeaders(customHeaders map[string]string) func(*Proxy) {
	return func(proxy *Proxy) {
		proxy.customHeaders = customHeaders
	}
}

// WithForcedTargetHostHeader is a function that returns a configuration function to force the target host header for a proxy.
func WithForcedTargetHostHeader() func(*Proxy) {
	return func(proxy *Proxy) {
		proxy.forceTargetHostHeader = true
	}
}

// NewProxy creates a new Proxy instance with the provided options.
func NewProxy(myURL *url.URL, version string, roundTripper http.RoundTripper, options ...func(*Proxy)) *Proxy {
	p := Proxy{Version: version, AllowResponseBuffering: true, customHeaders: make(map[string]string)}

	if myURL == nil {
		myURL = defaultTarget
	}

	u := *myURL // Make a copy of p.URL
	u.Path = ""
	p.reverseProxy = httputil.NewSingleHostReverseProxy(&u)
	p.reverseProxy.Transport = roundTripper
	p.reverseProxy.BufferPool = pool
	chainDirector(p.reverseProxy, func(r *http.Request) {
		r.Header.Set("Gitlab-Workhorse", p.Version)
		r.Header.Set("Gitlab-Workhorse-Proxy-Start", fmt.Sprintf("%d", time.Now().UnixNano()))

		for k, v := range p.customHeaders {
			r.Header.Set(k, v)
		}
	})

	for _, option := range options {
		option(&p)
	}

	if p.forceTargetHostHeader {
		// because of https://github.com/golang/go/issues/28168, the
		// upstream won't receive the expected Host header unless this
		// is forced in the Director func here
		chainDirector(p.reverseProxy, func(request *http.Request) {
			// send original host along for the upstream
			// to know it's being proxied under a different Host
			// (for redirects and other stuff that depends on this)
			request.Header.Set("X-Forwarded-Host", request.Host)
			request.Header.Set("Forwarded", fmt.Sprintf("host=%s", request.Host))

			// override the Host with the target
			request.Host = request.URL.Host
		})
	}

	return &p
}

func chainDirector(rp *httputil.ReverseProxy, nextDirector func(*http.Request)) {
	previous := rp.Director
	rp.Director = func(r *http.Request) {
		previous(r)
		nextDirector(r)
	}
}

func (p *Proxy) ServeHTTP(w http.ResponseWriter, r *http.Request) {
	if p.AllowResponseBuffering {
		nginx.AllowResponseBuffering(w)
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

	p.reverseProxy.ServeHTTP(w, r)
}

type bufferPool struct {
	pool sync.Pool
}

func newBufferPool() *bufferPool {
	return &bufferPool{
		pool: sync.Pool{
			New: func() any {
				return make([]byte, bufferPoolSize)
			},
		},
	}
}

func (bp *bufferPool) Get() []byte {
	return bp.pool.Get().([]byte)
}

func (bp *bufferPool) Put(v []byte) {
	bp.pool.Put(v) //lint:ignore SA6002 we either allocate manually to satisfy the linter or let the compiler allocate for us and silence the linter
}
