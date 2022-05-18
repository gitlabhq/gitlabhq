package main

import (
	"crypto/tls"
	"net"

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
		MinVersion:   tlsVersions[cfg.Tls.MinVersion],
		MaxVersion:   tlsVersions[cfg.Tls.MaxVersion],
		Certificates: []tls.Certificate{cert},
	}

	return tls.Listen(cfg.Network, cfg.Addr, tlsConfig)
}
