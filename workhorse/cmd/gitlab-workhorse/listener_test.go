package main

import (
	"crypto/tls"
	"crypto/x509"
	"io"
	"net"
	"os"
	"testing"

	"github.com/stretchr/testify/require"

	"gitlab.com/gitlab-org/gitlab/workhorse/internal/config"
)

func TestNewListener(t *testing.T) {
	const unixSocket = "../../testdata/sock"

	require.NoError(t, os.RemoveAll(unixSocket))

	testCases := []struct {
		network, addr string
	}{
		{"tcp", "127.0.0.1:0"},
		{"unix", unixSocket},
	}

	for _, tc := range testCases {
		t.Run(tc.network+"+"+tc.addr, func(t *testing.T) {
			l, err := newListener("test", config.ListenerConfig{
				Addr:    tc.addr,
				Network: tc.network,
			})
			require.NoError(t, err)
			defer l.Close()
			go pingServer(l)

			c, err := net.Dial(tc.network, l.Addr().String())
			require.NoError(t, err)
			defer c.Close()
			pingClient(t, c)
		})
	}
}

func pingServer(l net.Listener) {
	c, err := l.Accept()
	if err != nil {
		return
	}
	io.WriteString(c, "ping")
	c.Close()
}

func pingClient(t *testing.T, c net.Conn) {
	t.Helper()
	buf, err := io.ReadAll(c)
	require.NoError(t, err)
	require.Equal(t, "ping", string(buf))
}

func TestNewListener_TLS(t *testing.T) {
	const (
		certFile = "../../testdata/localhost.crt"
		keyFile  = "../../testdata/localhost.key"
	)

	cfg := config.ListenerConfig{Addr: "127.0.0.1:0",
		Network: "tcp",
		TLS: &config.TLSConfig{
			Certificate: certFile,
			Key:         keyFile,
		},
	}

	l, err := newListener("test", cfg)
	require.NoError(t, err)
	defer l.Close()
	go pingServer(l)

	tlsCertificate, err := tls.LoadX509KeyPair(certFile, keyFile)
	require.NoError(t, err)

	certificate, err := x509.ParseCertificate(tlsCertificate.Certificate[0])
	require.NoError(t, err)
	certpool := x509.NewCertPool()
	certpool.AddCert(certificate)

	c, err := tls.Dial("tcp", l.Addr().String(), &tls.Config{RootCAs: certpool})
	require.NoError(t, err)
	defer c.Close()

	pingClient(t, c)
}
