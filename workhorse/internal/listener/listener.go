// Package listener contains utilities for creating network listeners with optional TLS support.
package listener

import (
	"crypto/tls"
	"net"

	"gitlab.com/gitlab-org/labkit/log"

	"gitlab.com/gitlab-org/gitlab/workhorse/internal/config"
)

// New creates a network listener with optional TLS support
func New(name string, cfg config.ListenerConfig) (net.Listener, error) {
	if cfg.TLS == nil {
		log.WithFields(log.Fields{"address": cfg.Addr, "network": cfg.Network}).Infof("Running %v server", name)

		return net.Listen(cfg.Network, cfg.Addr)
	}

	cert, err := tls.LoadX509KeyPair(cfg.TLS.Certificate, cfg.TLS.Key)
	if err != nil {
		return nil, err
	}

	log.WithFields(log.Fields{"address": cfg.Addr, "network": cfg.Network}).Infof("Running %v server with tls", name)

	tlsConfig := &tls.Config{
		MinVersion:   config.TLSVersions[cfg.TLS.MinVersion],
		MaxVersion:   config.TLSVersions[cfg.TLS.MaxVersion],
		Certificates: []tls.Certificate{cert},
	}

	return tls.Listen(cfg.Network, cfg.Addr, tlsConfig)
}
