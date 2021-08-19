package git

import (
	"fmt"
	"net/http"

	"gitlab.com/gitlab-org/gitlab/workhorse/internal/api"
	"gitlab.com/gitlab-org/gitlab/workhorse/internal/gitaly"
	"gitlab.com/gitlab-org/gitlab/workhorse/internal/helper"
)

// Will not return a non-nil error after the response body has been
// written to.
func handleReceivePack(w *HttpResponseWriter, r *http.Request, a *api.Response) error {
	action := getService(r)
	writePostRPCHeader(w, action)

	cr, cw := helper.NewWriteAfterReader(r.Body, w)
	defer cw.Flush()

	gitProtocol := r.Header.Get("Git-Protocol")

	ctx, smarthttp, err := gitaly.NewSmartHTTPClient(r.Context(), a.GitalyServer)
	if err != nil {
		return fmt.Errorf("smarthttp.ReceivePack: %v", err)
	}

	if err := smarthttp.ReceivePack(ctx, &a.Repository, a.GL_ID, a.GL_USERNAME, a.GL_REPOSITORY, a.GitConfigOptions, cr, cw, gitProtocol); err != nil {
		return fmt.Errorf("smarthttp.ReceivePack: %v", err)
	}

	return nil
}
