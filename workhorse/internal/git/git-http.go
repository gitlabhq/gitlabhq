/*
In this file we handle the Git 'smart HTTP' protocol
*/

package git

import (
	"fmt"
	"io"
	"net/http"
	"path/filepath"
	"sync"

	"gitlab.com/gitlab-org/gitlab/workhorse/internal/api"
	"gitlab.com/gitlab-org/gitlab/workhorse/internal/log"
)

const (
	// We have to use a negative transfer.hideRefs since this is the only way
	// to undo an already set parameter: https://www.spinics.net/lists/git/msg256772.html
	GitConfigShowAllRefs = "transfer.hideRefs=!refs"
)

func ReceivePack(a *api.API) http.Handler {
	return postRPCHandler(a, "handleReceivePack", handleReceivePack)
}

func UploadPack(a *api.API) http.Handler {
	return postRPCHandler(a, "handleUploadPack", handleUploadPack)
}

func gitConfigOptions(a *api.Response) []string {
	var out []string

	if a.ShowAllRefs {
		out = append(out, GitConfigShowAllRefs)
	}

	return out
}

func postRPCHandler(a *api.API, name string, handler func(*HttpResponseWriter, *http.Request, *api.Response) error) http.Handler {
	return repoPreAuthorizeHandler(a, func(rw http.ResponseWriter, r *http.Request, ar *api.Response) {
		cr := &countReadCloser{ReadCloser: r.Body}
		r.Body = cr

		w := NewHttpResponseWriter(rw)
		defer func() {
			w.Log(r, cr.Count())
		}()

		if err := handler(w, r, ar); err != nil {
			// If the handler already wrote a response this WriteHeader call is a
			// no-op. It never reaches net/http because GitHttpResponseWriter calls
			// WriteHeader on its underlying ResponseWriter at most once.
			w.WriteHeader(500)
			log.WithRequest(r).WithError(fmt.Errorf("%s: %v", name, err)).Error()
		}
	})
}

func repoPreAuthorizeHandler(myAPI *api.API, handleFunc api.HandleFunc) http.Handler {
	return myAPI.PreAuthorizeHandler(func(w http.ResponseWriter, r *http.Request, a *api.Response) {
		handleFunc(w, r, a)
	}, "")
}

func writePostRPCHeader(w http.ResponseWriter, action string) {
	w.Header().Set("Content-Type", fmt.Sprintf("application/x-%s-result", action))
	w.Header().Set("Cache-Control", "no-cache")
}

func getService(r *http.Request) string {
	if r.Method == "GET" {
		return r.URL.Query().Get("service")
	}
	return filepath.Base(r.URL.Path)
}

type countReadCloser struct {
	n int64
	io.ReadCloser
	sync.Mutex
}

func (c *countReadCloser) Read(p []byte) (n int, err error) {
	n, err = c.ReadCloser.Read(p)

	c.Lock()
	defer c.Unlock()
	c.n += int64(n)

	return n, err
}

func (c *countReadCloser) Count() int64 {
	c.Lock()
	defer c.Unlock()
	return c.n
}
