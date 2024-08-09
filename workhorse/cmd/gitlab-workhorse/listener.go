package main

import (
	"crypto/tls"
	"net"

	"gitlab.com/gitlab-org/labkit/log"

	"gitlab.com/gitlab-org/gitlab/workhorse/internal/config"
)

func newListener(name string, cfg config.ListenerConfig) (net.Listener, error) {
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
		MinVersion:   config.TLSVersions[cfg.Tls.MinVersion],
		MaxVersion:   config.TLSVersions[cfg.Tls.MaxVersion],
		Certificates: []tls.Certificate{cert},
	}

	return tls.Listen(cfg.Network, cfg.Addr, tlsConfig)
}
