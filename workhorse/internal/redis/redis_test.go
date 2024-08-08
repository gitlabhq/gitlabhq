package redis

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
	rdb, err := Configure(nil)
	require.NoError(t, err)
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
			scheme: "rediss",
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

			rdb, err := Configure(cfg)
			require.NoError(t, err)
			defer rdb.Close()

			require.NotNil(t, rdb.Conn(), "Pool should not be nil")

			// goredis initialise connections lazily
			rdb.Ping(context.Background())
			require.True(t, connectReceived.Load().(bool))
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
			rdb, err := Configure(cfg)
			require.NoError(t, err)
			defer rdb.Close()

			require.NotNil(t, rdb.Conn(), "Pool should not be nil")

			// goredis initialise connections lazily
			rdb.Ping(context.Background())
			require.True(t, connectReceived.Load().(bool))
		})
	}
}

func TestSentinelOptions(t *testing.T) {
	testCases := []struct {
		description           string
		inputSentinelUsername string
		inputSentinelPassword string
		inputSentinel         []string
		username              string
		password              string
		sentinels             []string
	}{
		{
			description:   "no sentinel passwords",
			inputSentinel: []string{"tcp://localhost:26480"},
			sentinels:     []string{"localhost:26480"},
		},
		{
			description:           "specific sentinel password defined",
			inputSentinel:         []string{"tcp://localhost:26480"},
			inputSentinelPassword: "password1",
			sentinels:             []string{"localhost:26480"},
			password:              "password1",
		},
		{
			description:   "specific sentinel password defined in url",
			inputSentinel: []string{"tcp://:password2@localhost:26480", "tcp://:password3@localhost:26481"},
			sentinels:     []string{"localhost:26480", "localhost:26481"},
			password:      "password2",
		},
		{
			description:           "passwords defined specifically and in url",
			inputSentinel:         []string{"tcp://:password2@localhost:26480", "tcp://:password3@localhost:26481"},
			sentinels:             []string{"localhost:26480", "localhost:26481"},
			inputSentinelPassword: "password1",
			password:              "password1",
		},
		{
			description:           "specific sentinel username defined",
			inputSentinel:         []string{"redis://localhost:26480"},
			inputSentinelUsername: "username1",
			inputSentinelPassword: "password1",
			sentinels:             []string{"localhost:26480"},
			username:              "username1",
			password:              "password1",
		},
		{
			description:   "specific sentinel username defined in url",
			inputSentinel: []string{"redis://username2:password2@localhost:26480", "redis://username3:password3@localhost:26481"},
			sentinels:     []string{"localhost:26480", "localhost:26481"},
			username:      "username2",
			password:      "password2",
		},
		{
			description:           "usernames and passwords defined specifically and in url",
			inputSentinel:         []string{"tcp://someuser2:password2@localhost:26480", "tcp://someuser3:password3@localhost:26481"},
			sentinels:             []string{"localhost:26480", "localhost:26481"},
			inputSentinelUsername: "someuser1",
			inputSentinelPassword: "password1",
			username:              "someuser1",
			password:              "password1",
		},
		{
			description:   "username set for first sentinel",
			inputSentinel: []string{"tcp://someuser2@localhost:26480", "tcp://someuser3:password3@localhost:26481"},
			sentinels:     []string{"localhost:26480", "localhost:26481"},
			username:      "someuser3",
			password:      "password3",
		},
	}

	for _, tc := range testCases {
		t.Run(tc.description, func(t *testing.T) {
			sentinelUrls := make([]config.TomlURL, len(tc.inputSentinel))

			for i, str := range tc.inputSentinel {
				parsedURL := helper.URLMustParse(str)
				sentinelUrls[i] = config.TomlURL{URL: *parsedURL}
			}

			options := sentinelOptions(&config.RedisConfig{
				Sentinel:         sentinelUrls,
				SentinelUsername: tc.inputSentinelUsername,
				SentinelPassword: tc.inputSentinelPassword,
			})

			require.Equal(t, tc.username, options.SentinelUsername)
			require.Equal(t, tc.password, options.SentinelPassword)
			require.Equal(t, tc.sentinels, options.Sentinels)
		})
	}
}
