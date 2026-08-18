package main

import (
	"io"
	"net"
	"net/http"
	"net/http/httptest"
	"os"
	"path/filepath"
	"syscall"
	"testing"
	"time"

	"github.com/sirupsen/logrus"
	"github.com/stretchr/testify/require"
	"go.uber.org/goleak"

	"gitlab.com/gitlab-org/gitlab/workhorse/internal/config"
	"gitlab.com/gitlab-org/gitlab/workhorse/internal/redis"
	"gitlab.com/gitlab-org/gitlab/workhorse/internal/testhelper"
)

func newLocalListener(t *testing.T) net.Listener {
	t.Helper()

	l, err := net.Listen("tcp", "127.0.0.1:0")
	require.NoError(t, err)
	t.Cleanup(func() { _ = l.Close() })

	return l
}

func TestStartServerServesEveryListener(t *testing.T) {
	listeners := []net.Listener{newLocalListener(t), newLocalListener(t)}

	handler := http.HandlerFunc(func(w http.ResponseWriter, _ *http.Request) {
		w.WriteHeader(http.StatusTeapot)
		_, _ = io.WriteString(w, "brewing")
	})

	finalErrors := make(chan error, len(listeners))
	srv := startServer(handler, listeners, finalErrors)

	// ReadHeaderTimeout must be set to mitigate Slowloris-style attacks (gosec G112).
	require.Equal(t, time.Minute, srv.ReadHeaderTimeout)

	for _, l := range listeners {
		resp, err := http.Get("http://" + l.Addr().String() + "/")
		require.NoError(t, err)

		// io.ReadAll drains the body, so close it immediately rather than with
		// a defer that would hold every iteration's body open until the test
		// returns. Closing before the error check still closes on a read error.
		body, err := io.ReadAll(resp.Body)
		_ = resp.Body.Close()
		require.NoError(t, err)

		require.Equal(t, http.StatusTeapot, resp.StatusCode)
		require.Equal(t, "brewing", string(body))
	}

	require.NoError(t, srv.Close())

	// Every listener's Serve goroutine reports http.ErrServerClosed once the
	// server is closed.
	for range listeners {
		require.ErrorIs(t, <-finalErrors, http.ErrServerClosed)
	}
}

// TestServeAndWaitServesThenShutsDown drives the run() server lifecycle
// end-to-end: serveAndWait brings up the HTTP server on a real listener, serves
// a request, and then shuts down gracefully when a signal is delivered.
func TestServeAndWaitServesThenShutsDown(t *testing.T) {
	testhelper.ConfigureSecret()
	goleakOptions := append(testhelper.GoleakOptions(),
		goleak.IgnoreCurrent(),
		// Other tests in this package keep cached Gitaly/Orbit gRPC
		// connections open until TestMain teardown; ignore their reconnect
		// goroutines so this check stays scoped to serveAndWait.
		goleak.IgnoreTopFunction("google.golang.org/grpc.(*addrConn).resetTransportAndUnlock"),
		goleak.IgnoreTopFunction("google.golang.org/grpc.(*addrConn).connect"),
	)
	t.Cleanup(func() {
		goleak.VerifyNone(t, goleakOptions...)
	})

	backend := httptest.NewServer(http.HandlerFunc(func(w http.ResponseWriter, _ *http.Request) {
		w.WriteHeader(http.StatusOK)
	}))
	t.Cleanup(backend.Close)

	cfg := newUpstreamConfig(backend.URL)
	cfg.ShutdownTimeout = config.TomlDuration{Duration: time.Second}

	l := newLocalListener(t)
	finalErrors := make(chan error, 1)
	done := make(chan os.Signal, 1)

	returned := make(chan error, 1)
	go func() {
		// No health check server or load shedder: the graceful shutdown path
		// just stops the (client-less) key watcher and the HTTP server.
		returned <- serveAndWait(*cfg, logrus.StandardLogger(), redis.NewKeyWatcher(nil), nil, nil, nil, []net.Listener{l}, finalErrors, done)
	}()

	// The server accepts connections once serveAndWait has started serving.
	require.Eventually(t, func() bool {
		resp, err := http.Get("http://" + l.Addr().String() + "/")
		if err != nil {
			return false
		}
		return resp.Body.Close() == nil
	}, 5*time.Second, 20*time.Millisecond)

	// A shutdown signal triggers a graceful shutdown and serveAndWait returns.
	done <- syscall.SIGTERM
	select {
	case err := <-returned:
		require.NoError(t, err)
	case <-time.After(5 * time.Second):
		t.Fatal("serveAndWait did not return after shutdown signal")
	}

	// The listener has been shut down, so new requests fail.
	resp, err := http.Get("http://" + l.Addr().String() + "/")
	require.Error(t, err)
	if resp != nil {
		_ = resp.Body.Close()
	}
}

func TestUnlinkUnixSocket(t *testing.T) {
	t.Run("non-unix network is a no-op", func(t *testing.T) {
		require.NoError(t, unlinkUnixSocket("tcp", "127.0.0.1:0"))
	})

	t.Run("missing socket is not an error", func(t *testing.T) {
		require.NoError(t, unlinkUnixSocket("unix", filepath.Join(t.TempDir(), "missing.sock")))
	})

	t.Run("stale socket is removed", func(t *testing.T) {
		sock := filepath.Join(t.TempDir(), "workhorse.sock")
		require.NoError(t, os.WriteFile(sock, nil, 0o600))

		require.NoError(t, unlinkUnixSocket("unix", sock))

		_, err := os.Stat(sock)
		require.True(t, os.IsNotExist(err))
	})
}

func TestSetupLoadShedding(t *testing.T) {
	t.Run("nil LoadSheddingConfig returns no shedder", func(t *testing.T) {
		shedder, err := setupLoadShedding(config.Config{}, logrus.New())
		require.NoError(t, err)
		require.Nil(t, shedder)
	})

	t.Run("disabled config returns no shedder", func(t *testing.T) {
		cfg := config.Config{LoadSheddingConfig: &config.LoadSheddingConfig{Enabled: false}}
		shedder, err := setupLoadShedding(cfg, logrus.New())
		require.NoError(t, err)
		require.Nil(t, shedder)
	})
}
