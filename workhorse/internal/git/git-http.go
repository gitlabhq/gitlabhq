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

	"gitlab.com/gitlab-org/gitaly/v16/proto/go/gitalypb"

	"gitlab.com/gitlab-org/gitlab/workhorse/internal/api"
	"gitlab.com/gitlab-org/gitlab/workhorse/internal/log"
)

const (
	// We have to use a negative transfer.hideRefs since this is the only way
	// to undo an already set parameter: https://www.spinics.net/lists/git/msg256772.html
	GitConfigShowAllRefs = "transfer.hideRefs=!refs"
)

func ReceivePack(a *api.API) http.Handler {
	return postRPCHandler(a, "handleReceivePack", handleReceivePack, sendGitAuditEvent("git-receive-pack"), writeReceivePackError)
}

func UploadPack(a *api.API) http.Handler {
	return postRPCHandler(a, "handleUploadPack", handleUploadPack, sendGitAuditEvent("git-upload-pack"), writeUploadPackError)
}

func gitConfigOptions(a *api.Response) []string {
	var out []string

	if a.ShowAllRefs {
		out = append(out, GitConfigShowAllRefs)
	}

	return out
}

func postRPCHandler(
	a *api.API,
	name string,
	handler func(*HTTPResponseWriter, *http.Request, *api.Response) (*gitalypb.PackfileNegotiationStatistics, error),
	postFunc func(*api.API, *http.Request, *api.Response, *gitalypb.PackfileNegotiationStatistics),
	errWriter func(io.Writer) error,
) http.Handler {
	return repoPreAuthorizeHandler(a, func(rw http.ResponseWriter, r *http.Request, ar *api.Response) {
		cr := &countReadCloser{ReadCloser: r.Body}
		r.Body = cr

		w := NewHTTPResponseWriter(rw)
		defer func() {
			w.Log(r, cr.Count())
		}()

		stats, err := handler(w, r, ar)
		if err != nil {
			handleLimitErr(err, w, errWriter)
			// If the handler, or handleLimitErr already wrote a response this WriteHeader call is a
			// no-op. It never reaches net/http because GitHttpResponseWriter calls
			// WriteHeader on its underlying ResponseWriter at most once.
			w.WriteHeader(500)
			log.WithRequest(r).WithError(fmt.Errorf("%s: %v", name, err)).Error()
		}

		postFunc(a, r, ar, stats)
	})
}

func repoPreAuthorizeHandler(myAPI *api.API, handleFunc api.HandleFunc) http.Handler {
	return myAPI.PreAuthorizeHandler(func(w http.ResponseWriter, r *http.Request, a *api.Response) {
		handleFunc(w, r, a)
	}, "")
}

func sendGitAuditEvent(action string) func(*api.API, *http.Request, *api.Response, *gitalypb.PackfileNegotiationStatistics) {
	return func(a *api.API, r *http.Request, response *api.Response, stats *gitalypb.PackfileNegotiationStatistics) {
		if !response.NeedAudit {
			return
		}

		ctx := r.Context()
		err := a.SendGitAuditEvent(ctx, api.GitAuditEventRequest{
			Action:        action,
			Protocol:      "http",
			Repo:          response.GL_REPOSITORY,
			Username:      response.GL_USERNAME,
			PackfileStats: stats,
		})
		if err != nil {
			log.WithContextFields(ctx, log.Fields{
				"repo":     response.GL_REPOSITORY,
				"action":   action,
				"username": response.GL_USERNAME,
			}).WithError(err).Error("failed to send git audit event")
		}
	}
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
