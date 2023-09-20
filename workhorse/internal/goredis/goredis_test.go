package goredis

import (
	"context"
	"net"
	"sync/atomic"
	"testing"

	"github.com/stretchr/testify/require"

	"gitlab.com/gitlab-org/gitlab/workhorse/internal/config"
	"gitlab.com/gitlab-org/gitlab/workhorse/internal/helper"
)

func mockRedisServer(t *testing.T, connectReceived *atomic.Value) string {
	ln, err := net.Listen("tcp", "127.0.0.1:0")

	require.Nil(t, err)

	go func() {
		defer ln.Close()
		conn, err := ln.Accept()
		require.Nil(t, err)
		connectReceived.Store(true)
		conn.Write([]byte("OK\n"))
	}()

	return ln.Addr().String()
}

func TestConfigureNoConfig(t *testing.T) {
	rdb = nil
	Configure(nil)
	require.Nil(t, rdb, "rdb client should be nil")
}

func TestConfigureValidConfigX(t *testing.T) {
	testCases := []struct {
		scheme string
	}{
		{
			scheme: "redis",
		},
		{
			scheme: "tcp",
		},
	}

	for _, tc := range testCases {
		t.Run(tc.scheme, func(t *testing.T) {
			connectReceived := atomic.Value{}
			a := mockRedisServer(t, &connectReceived)

			parsedURL := helper.URLMustParse(tc.scheme + "://" + a)
			cfg := &config.RedisConfig{URL: config.TomlURL{URL: *parsedURL}}

			Configure(cfg)

			require.NotNil(t, GetRedisClient().Conn(), "Pool should not be nil")

			// goredis initialise connections lazily
			rdb.Ping(context.Background())
			require.True(t, connectReceived.Load().(bool))

			rdb = nil
		})
	}
}

func TestConnectToSentinel(t *testing.T) {
	testCases := []struct {
		scheme string
	}{
		{
			scheme: "redis",
		},
		{
			scheme: "tcp",
		},
	}

	for _, tc := range testCases {
		t.Run(tc.scheme, func(t *testing.T) {
			connectReceived := atomic.Value{}
			a := mockRedisServer(t, &connectReceived)

			addrs := []string{tc.scheme + "://" + a}
			var sentinelUrls []config.TomlURL

			for _, a := range addrs {
				parsedURL := helper.URLMustParse(a)
				sentinelUrls = append(sentinelUrls, config.TomlURL{URL: *parsedURL})
			}

			cfg := &config.RedisConfig{Sentinel: sentinelUrls}
			Configure(cfg)

			require.NotNil(t, GetRedisClient().Conn(), "Pool should not be nil")

			// goredis initialise connections lazily
			rdb.Ping(context.Background())
			require.True(t, connectReceived.Load().(bool))

			rdb = nil
		})
	}
}
