package git

import (
	"compress/gzip"
	"context"
	"fmt"
	"io"
	"net/http"

	"github.com/golang/gddo/httputil"

	"gitlab.com/gitlab-org/labkit/log"

	"gitlab.com/gitlab-org/gitlab/workhorse/internal/api"
	"gitlab.com/gitlab-org/gitlab/workhorse/internal/gitaly"
	"gitlab.com/gitlab-org/gitlab/workhorse/internal/helper"
)

func GetInfoRefsHandler(a *api.API) http.Handler {
	return repoPreAuthorizeHandler(a, handleGetInfoRefs)
}

func handleGetInfoRefs(rw http.ResponseWriter, r *http.Request, a *api.Response) {
	responseWriter := NewHttpResponseWriter(rw)
	// Log 0 bytes in because we ignore the request body (and there usually is none anyway).
	defer responseWriter.Log(r, 0)

	rpc := getService(r)
	if !(rpc == "git-upload-pack" || rpc == "git-receive-pack") {
		// The 'dumb' Git HTTP protocol is not supported
		http.Error(responseWriter, "Not Found", 404)
		return
	}

	responseWriter.Header().Set("Content-Type", fmt.Sprintf("application/x-%s-advertisement", rpc))
	responseWriter.Header().Set("Cache-Control", "no-cache")

	gitProtocol := r.Header.Get("Git-Protocol")

	offers := []string{"gzip", "identity"}
	encoding := httputil.NegotiateContentEncoding(r, offers)

	if err := handleGetInfoRefsWithGitaly(r.Context(), responseWriter, a, rpc, gitProtocol, encoding); err != nil {
		helper.Fail500(responseWriter, r, fmt.Errorf("handleGetInfoRefs: %v", err))
	}
}

func handleGetInfoRefsWithGitaly(ctx context.Context, responseWriter *HttpResponseWriter, a *api.Response, rpc, gitProtocol, encoding string) error {
	ctx, smarthttp, err := gitaly.NewSmartHTTPClient(ctx, a.GitalyServer)
	if err != nil {
		return fmt.Errorf("GetInfoRefsHandler: %v", err)
	}

	infoRefsResponseReader, err := smarthttp.InfoRefsResponseReader(ctx, &a.Repository, rpc, gitConfigOptions(a), gitProtocol)
	if err != nil {
		return fmt.Errorf("GetInfoRefsHandler: %v", err)
	}

	var w io.Writer

	if encoding == "gzip" {
		gzWriter := gzip.NewWriter(responseWriter)
		w = gzWriter
		defer gzWriter.Close()

		responseWriter.Header().Set("Content-Encoding", "gzip")
	} else {
		w = responseWriter
	}

	if _, err = io.Copy(w, infoRefsResponseReader); err != nil {
		log.WithError(err).Error("GetInfoRefsHandler: error copying gitaly response")
	}

	return nil
}
