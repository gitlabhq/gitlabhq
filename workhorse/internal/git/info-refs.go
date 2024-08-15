package git

import (
	"compress/gzip"
	"context"
	"fmt"
	"io"
	"net/http"
	"sync"

	"github.com/golang/gddo/httputil"
	grpccodes "google.golang.org/grpc/codes"
	grpcstatus "google.golang.org/grpc/status"

	"gitlab.com/gitlab-org/gitlab/workhorse/internal/api"
	"gitlab.com/gitlab-org/gitlab/workhorse/internal/gitaly"
	"gitlab.com/gitlab-org/gitlab/workhorse/internal/helper/fail"
)

func GetInfoRefsHandler(a *api.API) http.Handler {
	return repoPreAuthorizeHandler(a, handleGetInfoRefs)
}

func handleGetInfoRefs(rw http.ResponseWriter, r *http.Request, a *api.Response) {
	responseWriter := NewHTTPResponseWriter(rw)
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
		status := grpcstatus.Convert(err)
		err = fmt.Errorf("handleGetInfoRefs: %v", err)

		if status == nil {
			fail.Request(responseWriter, r, err)
			return
		}
		switch status.Code() {
		case grpccodes.Unavailable:
			fail.Request(responseWriter, r, err, fail.WithStatus(http.StatusServiceUnavailable),
				fail.WithBody("The git server, Gitaly, is not available at this time. Please contact your administrator."))
		case grpccodes.NotFound:
			fail.Request(responseWriter, r, err, fail.WithStatus(http.StatusNotFound),
				fail.WithBody("Not Found."))
		default:
			fail.Request(responseWriter, r, err)
		}
	}
}

func handleGetInfoRefsWithGitaly(ctx context.Context, responseWriter *HTTPResponseWriter, a *api.Response, rpc, gitProtocol, encoding string) error {
	ctx, smarthttp, err := gitaly.NewSmartHTTPClient(ctx, a.GitalyServer)
	if err != nil {
		return err
	}

	infoRefsResponseReader, err := smarthttp.InfoRefsResponseReader(ctx, &a.Repository, rpc, gitConfigOptions(a), gitProtocol)
	if err != nil {
		return err
	}

	var w io.WriteCloser = nopCloser{responseWriter}
	if encoding == "gzip" {
		gzWriter := getGzWriter(responseWriter)
		defer putGzWriter(gzWriter)

		w = gzWriter
		responseWriter.Header().Set("Content-Encoding", "gzip")
	}

	if _, err = io.Copy(w, infoRefsResponseReader); err != nil {
		return err
	}

	if err := w.Close(); err != nil {
		return err
	}

	return nil
}

var gzipPool = &sync.Pool{New: func() interface{} {
	// Invariant: the inner writer is io.Discard. We do not want to retain
	// response writers of past requests in the pool.
	return gzip.NewWriter(io.Discard)
}}

func getGzWriter(w io.Writer) *gzip.Writer {
	gzWriter := gzipPool.Get().(*gzip.Writer)
	gzWriter.Reset(w)
	return gzWriter
}

func putGzWriter(w *gzip.Writer) {
	w.Reset(io.Discard) // Maintain pool invariant
	gzipPool.Put(w)
}

type nopCloser struct{ io.Writer }

func (nc nopCloser) Close() error { return nil }
