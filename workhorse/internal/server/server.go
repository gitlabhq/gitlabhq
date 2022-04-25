package server

import (
	"context"
	"crypto/tls"
	"fmt"
	"net"
	"net/http"
	"syscall"

	"gitlab.com/gitlab-org/labkit/log"

	"gitlab.com/gitlab-org/gitlab/workhorse/internal/config"
)

var tlsVersions = map[string]uint16{
	"":       0, // Default value in tls.Config
	"tls1.0": tls.VersionTLS10,
	"tls1.1": tls.VersionTLS11,
	"tls1.2": tls.VersionTLS12,
	"tls1.3": tls.VersionTLS13,
}

type Server struct {
	Handler         http.Handler
	Umask           int
	ListenerConfigs []config.ListenerConfig
	Errors          chan error

	servers []*http.Server
}

func (s *Server) Run() error {
	oldUmask := syscall.Umask(s.Umask)
	defer syscall.Umask(oldUmask)

	for _, cfg := range s.ListenerConfigs {
		listener, err := s.newListener("upstream", cfg)
		if err != nil {
			return fmt.Errorf("server.Run: failed creating a listener: %v", err)
		}

		s.runUpstreamServer(listener)
	}

	return nil
}

func (s *Server) Close() error {
	return s.allServers(func(srv *http.Server) error { return srv.Close() })
}

func (s *Server) Shutdown(ctx context.Context) error {
	return s.allServers(func(srv *http.Server) error { return srv.Shutdown(ctx) })
}

func (s *Server) allServers(callback func(*http.Server) error) error {
	var resultErr error
	errC := make(chan error, len(s.servers))
	for _, server := range s.servers {
		server := server // Capture loop variable
		go func() { errC <- callback(server) }()
	}

	for range s.servers {
		if err := <-errC; err != nil {
			resultErr = err
		}
	}

	return resultErr
}

func (s *Server) runUpstreamServer(listener net.Listener) {
	srv := &http.Server{
		Addr:    listener.Addr().String(),
		Handler: s.Handler,
	}
	go func() {
		s.Errors <- srv.Serve(listener)
	}()

	s.servers = append(s.servers, srv)
}

func (s *Server) newListener(name string, cfg config.ListenerConfig) (net.Listener, error) {
	if cfg.Tls == nil {
		log.WithFields(log.Fields{"address": cfg.Addr, "network": cfg.Network}).Infof("Running %v server", name)

		return net.Listen(cfg.Network, cfg.Addr)
	}

	cert, err := tls.LoadX509KeyPair(cfg.Tls.Certificate, cfg.Tls.Key)
	if err != nil {
		return nil, err
	}

	log.WithFields(log.Fields{"address": cfg.Addr, "network": cfg.Network}).Infof("Running %v server with tls", name)

	tlsConfig := &tls.Config{
		MinVersion:   tlsVersions[cfg.Tls.MinVersion],
		MaxVersion:   tlsVersions[cfg.Tls.MaxVersion],
		Certificates: []tls.Certificate{cert},
	}

	return tls.Listen(cfg.Network, cfg.Addr, tlsConfig)
}
