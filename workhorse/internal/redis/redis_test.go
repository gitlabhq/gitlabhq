package redis

import (
	"net"
	"testing"
	"time"

	"github.com/gomodule/redigo/redis"
	"github.com/rafaeljusto/redigomock"
	"github.com/stretchr/testify/require"

	"gitlab.com/gitlab-org/gitlab-workhorse/internal/config"
	"gitlab.com/gitlab-org/gitlab-workhorse/internal/helper"
)

func mockRedisServer(t *testing.T, connectReceived *bool) string {
	ln, err := net.Listen("tcp", "127.0.0.1:0")

	require.Nil(t, err)

	go func() {
		defer ln.Close()
		conn, err := ln.Accept()
		require.Nil(t, err)
		*connectReceived = true
		conn.Write([]byte("OK\n"))
	}()

	return ln.Addr().String()
}

// Setup a MockPool for Redis
//
// Returns a teardown-function and the mock-connection
func setupMockPool() (*redigomock.Conn, func()) {
	conn := redigomock.NewConn()
	cfg := &config.RedisConfig{URL: config.TomlURL{}}
	Configure(cfg, func(_ *config.RedisConfig, _ bool) func() (redis.Conn, error) {
		return func() (redis.Conn, error) {
			return conn, nil
		}
	})
	return conn, func() {
		pool = nil
	}
}

func TestDefaultDialFunc(t *testing.T) {
	testCases := []struct {
		scheme string
	}{
		{
			scheme: "tcp",
		},
		{
			scheme: "redis",
		},
	}

	for _, tc := range testCases {
		t.Run(tc.scheme, func(t *testing.T) {
			connectReceived := false
			a := mockRedisServer(t, &connectReceived)

			parsedURL := helper.URLMustParse(tc.scheme + "://" + a)
			cfg := &config.RedisConfig{URL: config.TomlURL{URL: *parsedURL}}

			dialer := DefaultDialFunc(cfg, true)
			conn, err := dialer()

			require.Nil(t, err)
			conn.Receive()

			require.True(t, connectReceived)
		})
	}
}

func TestConfigureNoConfig(t *testing.T) {
	pool = nil
	Configure(nil, nil)
	require.Nil(t, pool, "Pool should be nil")
}

func TestConfigureMinimalConfig(t *testing.T) {
	cfg := &config.RedisConfig{URL: config.TomlURL{}, Password: ""}
	Configure(cfg, DefaultDialFunc)

	require.NotNil(t, pool, "Pool should not be nil")
	require.Equal(t, 1, pool.MaxIdle)
	require.Equal(t, 1, pool.MaxActive)
	require.Equal(t, 3*time.Minute, pool.IdleTimeout)

	pool = nil
}

func TestConfigureFullConfig(t *testing.T) {
	i, a := 4, 10
	cfg := &config.RedisConfig{
		URL:       config.TomlURL{},
		Password:  "",
		MaxIdle:   &i,
		MaxActive: &a,
	}
	Configure(cfg, DefaultDialFunc)

	require.NotNil(t, pool, "Pool should not be nil")
	require.Equal(t, i, pool.MaxIdle)
	require.Equal(t, a, pool.MaxActive)
	require.Equal(t, 3*time.Minute, pool.IdleTimeout)

	pool = nil
}

func TestGetConnFail(t *testing.T) {
	conn := Get()
	require.Nil(t, conn, "Expected `conn` to be nil")
}

func TestGetConnPass(t *testing.T) {
	_, teardown := setupMockPool()
	defer teardown()
	conn := Get()
	require.NotNil(t, conn, "Expected `conn` to be non-nil")
}

func TestGetStringPass(t *testing.T) {
	conn, teardown := setupMockPool()
	defer teardown()
	conn.Command("GET", "foobar").Expect("baz")
	str, err := GetString("foobar")

	require.NoError(t, err, "Expected `err` to be nil")
	var value string
	require.IsType(t, value, str, "Expected value to be a string")
	require.Equal(t, "baz", str, "Expected it to be equal")
}

func TestGetStringFail(t *testing.T) {
	_, err := GetString("foobar")
	require.Error(t, err, "Expected error when not connected to redis")
}

func TestSentinelConnNoSentinel(t *testing.T) {
	s := sentinelConn("", []config.TomlURL{})

	require.Nil(t, s, "Sentinel without urls should return nil")
}

func TestSentinelConnDialURL(t *testing.T) {
	testCases := []struct {
		scheme string
	}{
		{
			scheme: "tcp",
		},
		{
			scheme: "redis",
		},
	}

	for _, tc := range testCases {
		t.Run(tc.scheme, func(t *testing.T) {
			connectReceived := false
			a := mockRedisServer(t, &connectReceived)

			addrs := []string{tc.scheme + "://" + a}
			var sentinelUrls []config.TomlURL

			for _, a := range addrs {
				parsedURL := helper.URLMustParse(a)
				sentinelUrls = append(sentinelUrls, config.TomlURL{URL: *parsedURL})
			}

			s := sentinelConn("foobar", sentinelUrls)
			require.Equal(t, len(addrs), len(s.Addrs))

			for i := range addrs {
				require.Equal(t, addrs[i], s.Addrs[i])
			}

			conn, err := s.Dial(s.Addrs[0])

			require.Nil(t, err)
			conn.Receive()

			require.True(t, connectReceived)
		})
	}
}

func TestSentinelConnTwoURLs(t *testing.T) {
	addrs := []string{"tcp://10.0.0.1:12345", "tcp://10.0.0.2:12345"}
	var sentinelUrls []config.TomlURL

	for _, a := range addrs {
		parsedURL := helper.URLMustParse(a)
		sentinelUrls = append(sentinelUrls, config.TomlURL{URL: *parsedURL})
	}

	s := sentinelConn("foobar", sentinelUrls)
	require.Equal(t, len(addrs), len(s.Addrs))

	for i := range addrs {
		require.Equal(t, addrs[i], s.Addrs[i])
	}
}

func TestDialOptionsBuildersPassword(t *testing.T) {
	dopts := dialOptionsBuilder(&config.RedisConfig{Password: "foo"}, false)
	require.Equal(t, 1, len(dopts))
}

func TestDialOptionsBuildersSetTimeouts(t *testing.T) {
	dopts := dialOptionsBuilder(nil, true)
	require.Equal(t, 2, len(dopts))
}

func TestDialOptionsBuildersSetTimeoutsConfig(t *testing.T) {
	dopts := dialOptionsBuilder(nil, true)
	require.Equal(t, 2, len(dopts))
}

func TestDialOptionsBuildersSelectDB(t *testing.T) {
	db := 3
	dopts := dialOptionsBuilder(&config.RedisConfig{DB: &db}, false)
	require.Equal(t, 1, len(dopts))
}
