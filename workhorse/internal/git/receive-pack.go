package git

import (
	"fmt"
	"net/http"

	"gitlab.com/gitlab-org/gitaly/v16/proto/go/gitalypb"

	"gitlab.com/gitlab-org/gitlab/workhorse/internal/api"
	"gitlab.com/gitlab-org/gitlab/workhorse/internal/gitaly"
)

// Will not return a non-nil error after the response body has been
// written to.
// and `git push` doesn't provide `gitalypb.PackfileNegotiationStatistics`.
func handleReceivePack(w *HTTPResponseWriter, r *http.Request, a *api.Response) (*gitalypb.PackfileNegotiationStatistics, error) {
	action := getService(r)
	writePostRPCHeader(w, action)

	cr, cw := newWriteAfterReader(r.Body, w)
	defer cw.Flush()

	gitProtocol := r.Header.Get("Git-Protocol")

	ctx, smarthttp, err := gitaly.NewSmartHTTPClient(r.Context(), a.GitalyServer)
	if err != nil {
		return nil, fmt.Errorf("smarthttp.ReceivePack: %v", err)
	}

	if err := smarthttp.ReceivePack(ctx, &a.Repository, a.GL_ID, a.GL_USERNAME, a.GL_REPOSITORY, a.GitConfigOptions, cr, cw, gitProtocol); err != nil {
		return nil, fmt.Errorf("smarthttp.ReceivePack: %w", err)
	}

	return nil, nil
}
