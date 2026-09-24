package git

import (
	"bytes"
	"context"
	"io"
	"net/http"
	"net/http/httptest"
	"testing"
	"time"

	"github.com/stretchr/testify/require"
	"gitlab.com/gitlab-org/gitaly/v18/client"
	"gitlab.com/gitlab-org/gitaly/v18/proto/go/gitalypb"

	"gitlab.com/gitlab-org/gitlab/workhorse/internal/api"
	"gitlab.com/gitlab-org/gitlab/workhorse/internal/helper"
	"gitlab.com/gitlab-org/gitlab/workhorse/internal/testhelper"
)

const (
	sshUploadPackPath  = "/ssh-upload-pack"
	sshReceivePackPath = "/ssh-receive-pack"
)

func TestSSHUploadPack(t *testing.T) {
	addr := setupGitalyServer(t)
	a := &api.Response{GitalyServer: api.GitalyServer{Address: addr}}

	ts := httptest.NewServer(http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		handleSSHUploadPack(w, r, a)
	}))
	defer ts.Close()

	buf := &bytes.Buffer{}
	res, err := http.Post(ts.URL+sshUploadPackPath, "", buf)
	require.NoError(t, err)

	err = res.Body.Close()
	require.NoError(t, err)

	require.Equal(t, http.StatusOK, res.StatusCode)
}

func TestSSHUploadPack_GitalyConnection(t *testing.T) {
	a := &api.Response{GitalyServer: api.GitalyServer{Address: "wrong"}}

	ts := httptest.NewServer(http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		handleSSHUploadPack(w, r, a)
	}))
	defer ts.Close()

	buf := &bytes.Buffer{}
	res, err := http.Post(ts.URL+sshUploadPackPath, "", buf)
	require.NoError(t, err)

	err = res.Body.Close()
	require.NoError(t, err)

	require.Equal(t, http.StatusInternalServerError, res.StatusCode)
}

func TestReceivePack(t *testing.T) {
	addr := setupGitalyServer(t)
	a := &api.Response{GitalyServer: api.GitalyServer{Address: addr}}

	ts := httptest.NewServer(http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		handleSSHReceivePack(w, r, a)
	}))
	defer ts.Close()

	buf := &bytes.Buffer{}
	res, err := http.Post(ts.URL+sshReceivePackPath, "", buf)
	require.NoError(t, err)

	err = res.Body.Close()
	require.NoError(t, err)

	require.Equal(t, http.StatusOK, res.StatusCode)
}

func TestReceivePack_GitalyConnection(t *testing.T) {
	a := &api.Response{GitalyServer: api.GitalyServer{Address: "wrong"}}

	ts := httptest.NewServer(http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		handleSSHReceivePack(w, r, a)
	}))
	defer ts.Close()

	buf := &bytes.Buffer{}
	res, err := http.Post(ts.URL+sshReceivePackPath, "", buf)
	require.NoError(t, err)

	err = res.Body.Close()
	require.NoError(t, err)

	require.Equal(t, http.StatusInternalServerError, res.StatusCode)
}

func TestWithFullDuplex_Unsupported(t *testing.T) {
	next := http.HandlerFunc(func(http.ResponseWriter, *http.Request) {
		t.Fatal("next handler must not run")
	})

	r := httptest.NewRequest(http.MethodPost, sshReceivePackPath, nil)
	w := httptest.NewRecorder()

	withFullDuplex(next).ServeHTTP(w, r)

	res := w.Result()

	err := res.Body.Close()
	require.NoError(t, err)

	require.Equal(t, http.StatusInternalServerError, res.StatusCode)
}

func TestSSHPreAuthorizeRejection_OpenRequestBody(t *testing.T) {
	testhelper.ConfigureSecret()

	rails := httptest.NewServer(http.HandlerFunc(func(w http.ResponseWriter, _ *http.Request) {
		w.WriteHeader(http.StatusNotFound)
		_, _ = io.WriteString(w, "not found")
	}))
	defer rails.Close()

	a := api.NewAPI(helper.URLMustParse(rails.URL), "123", http.DefaultTransport)

	tests := []struct {
		name    string
		handler http.Handler
		path    string
	}{
		{name: "upload pack", handler: SSHUploadPack(a), path: sshUploadPackPath},
		{name: "receive pack", handler: SSHReceivePack(a), path: sshReceivePackPath},
	}

	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			ts := httptest.NewServer(tt.handler)
			defer ts.Close()

			// gitlab-shell streams the SSH client's stdin, which stays silent until
			// the client gets a response.
			body, bodyWriter := io.Pipe()
			defer bodyWriter.Close()

			type result struct {
				status int
				err    error
			}
			done := make(chan result, 1)
			go func() {
				res, err := http.Post(ts.URL+tt.path, "application/octet-stream", body)
				if err != nil {
					done <- result{err: err}
					return
				}
				done <- result{status: res.StatusCode, err: res.Body.Close()}
			}()

			select {
			case r := <-done:
				require.NoError(t, r.err)
				require.Equal(t, http.StatusNotFound, r.status)
			case <-time.After(5 * time.Second):
				t.Fatal("rejection not sent while the request body was open")
			}
		})
	}
}

func setupGitalyServer(t *testing.T) string {
	t.Helper()

	return startSmartHTTPServer(t, &smartHTTPServiceServer{
		handler: func(ctx context.Context, _ *gitalypb.PostUploadPackWithSidechannelRequest) (*gitalypb.PostUploadPackWithSidechannelResponse, error) {
			conn, err := client.OpenServerSidechannel(ctx)
			require.NoError(t, err)

			defer conn.Close()

			_, err = io.Copy(io.Discard, conn)
			require.NoError(t, err)

			return &gitalypb.PostUploadPackWithSidechannelResponse{}, nil
		},
	})
}
