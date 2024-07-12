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
	"gitlab.com/gitlab-org/gitaly/v16/client"
	"gitlab.com/gitlab-org/gitaly/v16/proto/go/gitalypb"

	"gitlab.com/gitlab-org/gitlab/workhorse/internal/api"
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

func TestSSHUploadPack_FullDuplex(t *testing.T) {
	addr := setupGitalyServer(t)
	a := &api.Response{GitalyServer: api.GitalyServer{Address: addr}}

	time.Sleep(10 * time.Millisecond)
	r := httptest.NewRequest("POST", sshUploadPackPath, nil)
	w := httptest.NewRecorder()

	handleSSHUploadPack(w, r, a)

	res := w.Result()

	err := res.Body.Close()
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

func TestReceive_FullDuplex(t *testing.T) {
	addr := setupGitalyServer(t)
	a := &api.Response{GitalyServer: api.GitalyServer{Address: addr}}

	time.Sleep(10 * time.Millisecond)
	r := httptest.NewRequest("POST", sshReceivePackPath, nil)
	w := httptest.NewRecorder()

	handleSSHReceivePack(w, r, a)

	res := w.Result()

	err := res.Body.Close()
	require.NoError(t, err)

	require.Equal(t, http.StatusInternalServerError, res.StatusCode)
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
