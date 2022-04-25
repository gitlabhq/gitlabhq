package server

import (
	"context"
	"crypto/tls"
	"crypto/x509"
	"net/http"
	"testing"
	"time"

	"github.com/stretchr/testify/require"

	"gitlab.com/gitlab-org/gitlab/workhorse/internal/config"
)

const (
	certFile = "testdata/localhost.crt"
	keyFile  = "testdata/localhost.key"
)

func TestRun(t *testing.T) {
	srv := defaultServer()

	require.NoError(t, srv.Run())
	defer srv.Close()

	require.Len(t, srv.servers, 2)

	clients := buildClients(t, srv.servers)
	for url, client := range clients {
		resp, err := client.Get(url)
		require.NoError(t, err)
		require.Equal(t, 200, resp.StatusCode)
	}
}

func TestShutdown(t *testing.T) {
	ready := make(chan bool)
	done := make(chan bool)
	statusCodes := make(chan int)

	srv := defaultServer()
	srv.Handler = http.HandlerFunc(func(rw http.ResponseWriter, r *http.Request) {
		ready <- true
		<-done
		rw.WriteHeader(200)
	})

	require.NoError(t, srv.Run())
	defer srv.Close()

	clients := buildClients(t, srv.servers)

	for url, client := range clients {
		go func(url string, client *http.Client) {
			resp, err := client.Get(url)
			require.NoError(t, err)
			statusCodes <- resp.StatusCode
		}(url, client)
	}

	for range clients {
		<-ready
	} // initiate requests

	shutdownError := make(chan error)
	go func() {
		shutdownError <- srv.Shutdown(context.Background())
	}()

	for url, client := range clients {
		require.Eventually(t, func() bool {
			_, err := client.Get(url)
			return err != nil
		}, time.Second, 10*time.Millisecond, "server must stop accepting new requests")
	}

	for range clients {
		done <- true
	} // finish requests

	require.NoError(t, <-shutdownError)
	require.ElementsMatch(t, []int{200, 200}, []int{<-statusCodes, <-statusCodes})
}

func TestShutdown_withTimeout(t *testing.T) {
	ready := make(chan bool)
	done := make(chan bool)

	srv := defaultServer()
	srv.Handler = http.HandlerFunc(func(rw http.ResponseWriter, r *http.Request) {
		ready <- true
		<-done
		rw.WriteHeader(200)
	})

	require.NoError(t, srv.Run())
	defer srv.Close()

	clients := buildClients(t, srv.servers)

	for url, client := range clients {
		go func(url string, client *http.Client) {
			client.Get(url)
		}(url, client)
	}

	for range clients {
		<-ready
	} // initiate requets

	ctx, cancel := context.WithTimeout(context.Background(), time.Millisecond)
	defer cancel()

	err := srv.Shutdown(ctx)
	require.Error(t, err)
	require.EqualError(t, err, "context deadline exceeded")
}

func defaultServer() Server {
	return Server{
		ListenerConfigs: []config.ListenerConfig{
			{
				Addr:    "127.0.0.1:0",
				Network: "tcp",
			},
			{
				Addr:    "127.0.0.1:0",
				Network: "tcp",
				Tls: &config.TlsConfig{
					Certificate: certFile,
					Key:         keyFile,
				},
			},
		},
		Handler: http.HandlerFunc(func(rw http.ResponseWriter, r *http.Request) {
			rw.WriteHeader(200)
		}),
		Errors: make(chan error),
	}
}

func buildClients(t *testing.T, servers []*http.Server) map[string]*http.Client {
	httpsClient := &http.Client{}
	certpool := x509.NewCertPool()

	tlsCertificate, err := tls.LoadX509KeyPair(certFile, keyFile)
	require.NoError(t, err)

	certificate, err := x509.ParseCertificate(tlsCertificate.Certificate[0])
	require.NoError(t, err)

	certpool.AddCert(certificate)
	httpsClient.Transport = &http.Transport{
		TLSClientConfig: &tls.Config{
			RootCAs: certpool,
		},
	}

	httpServer, httpsServer := servers[0], servers[1]
	return map[string]*http.Client{
		"http://" + httpServer.Addr:   http.DefaultClient,
		"https://" + httpsServer.Addr: httpsClient,
	}
}
