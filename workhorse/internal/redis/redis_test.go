package redis

import (
	"context"
	"crypto/tls"
	"fmt"
	"net"
	"sync/atomic"
	"testing"

	"github.com/stretchr/testify/assert"
	"github.com/stretchr/testify/require"

	"gitlab.com/gitlab-org/gitlab/workhorse/internal/config"
	"gitlab.com/gitlab-org/gitlab/workhorse/internal/helper"
)

const (
	caCert   = "../../testdata/localhost.crt"
	certFile = "../../testdata/localhost.crt"
	keyFile  = "../../testdata/localhost.key"
)

func mockRedisServer(t *testing.T, connectReceived *atomic.Value) string {
	ln, err := net.Listen("tcp", "127.0.0.1:0")

	require.NoError(t, err)

	go func() {
		defer ln.Close()
		conn, err := ln.Accept()
		assert.NoError(t, err)
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

func TestConfigureConfigWithoutRedis(t *testing.T) {
	rdb, err := Configure(&config.Config{})
	require.NoError(t, err)
	require.Nil(t, rdb, "rdb client should be nil")
}

func TestConfigureValidConfigX(t *testing.T) {
	testCases := []struct {
		scheme           string
		username         string
		urlPassword      string
		redisPassword    string
		expectedPassword string
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
		{
			scheme:           "redis",
			username:         "redis-user",
			urlPassword:      "redis-password",
			expectedPassword: "redis-password",
		},
		{
			scheme:           "redis",
			redisPassword:    "override-password",
			expectedPassword: "override-password",
		},
		{
			scheme:           "redis",
			username:         "redis-user",
			urlPassword:      "redis-password",
			redisPassword:    "override-password",
			expectedPassword: "override-password",
		},
	}

	for _, tc := range testCases {
		t.Run(tc.scheme, func(t *testing.T) {
			connectReceived := atomic.Value{}
			a := mockRedisServer(t, &connectReceived)

			var u string
			if tc.username != "" || tc.urlPassword != "" {
				u = fmt.Sprintf("%s://%s:%s@%s", tc.scheme, tc.username, tc.urlPassword, a)
			} else {
				u = fmt.Sprintf("%s://%s", tc.scheme, a)
			}

			parsedURL := helper.URLMustParse(u)
			redisCfg := &config.RedisConfig{
				URL:      config.TomlURL{URL: *parsedURL},
				Password: tc.redisPassword,
			}
			cfg := &config.Config{Redis: redisCfg}

			rdb, err := Configure(cfg)
			require.NoError(t, err)
			defer rdb.Close()

			require.NotNil(t, rdb.Conn(), "Pool should not be nil")
			opt := rdb.Options()
			require.Equal(t, tc.username, opt.Username)
			require.Equal(t, tc.expectedPassword, opt.Password)

			// goredis initialize connections lazily
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

			redisCfg := &config.RedisConfig{Sentinel: sentinelUrls}
			cfg := &config.Config{Redis: redisCfg}
			rdb, err := Configure(cfg)
			require.NoError(t, err)
			defer rdb.Close()

			require.NotNil(t, rdb.Conn(), "Pool should not be nil")

			// goredis initialize connections lazily
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
		sentinelTLSConfig     *config.TLSConfig
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
		{
			description:       "tls defined",
			inputSentinel:     []string{"tcp://localhost:26480", "tcp://localhost:26481"},
			sentinels:         []string{"localhost:26480", "localhost:26481"},
			sentinelTLSConfig: &config.TLSConfig{Certificate: certFile, Key: keyFile},
		},
	}

	for _, tc := range testCases {
		t.Run(tc.description, func(t *testing.T) {
			sentinelUrls := make([]config.TomlURL, len(tc.inputSentinel))

			for i, str := range tc.inputSentinel {
				parsedURL := helper.URLMustParse(str)
				sentinelUrls[i] = config.TomlURL{URL: *parsedURL}
			}

			redisCfg := &config.RedisConfig{
				Sentinel:         sentinelUrls,
				SentinelUsername: tc.inputSentinelUsername,
				SentinelPassword: tc.inputSentinelPassword,
			}

			sentinelCfg := &config.SentinelConfig{
				TLS: tc.sentinelTLSConfig,
			}

			options, err := sentinelOptions(&config.Config{
				Redis:    redisCfg,
				Sentinel: sentinelCfg,
			})

			require.NoError(t, err)
			require.Equal(t, tc.username, options.SentinelUsername)
			require.Equal(t, tc.password, options.SentinelPassword)
			require.Equal(t, tc.sentinels, options.Sentinels)

			if tc.sentinelTLSConfig != nil {
				require.Len(t, options.SentinelTLSConfig.Certificates, 1)
			}
		})
	}
}

func TestSentinelTLSOptions(t *testing.T) {
	testCases := []struct {
		description    string
		sentinelConfig *config.SentinelConfig
		expectedError  error
		expectedCerts  int
		checkRootCAs   func(t *testing.T, tlsConfig *tls.Config)
	}{
		{
			description:    "no tls defined",
			sentinelConfig: &config.SentinelConfig{},
			expectedError:  errSentinelTLSNotDefined,
		},
		{
			description:    "certificate missing",
			sentinelConfig: &config.SentinelConfig{TLS: &config.TLSConfig{Key: keyFile}},
			expectedError:  sentinelTLSErrors.CertificateNotDefined,
		},
		{
			description:    "key missing",
			sentinelConfig: &config.SentinelConfig{TLS: &config.TLSConfig{Certificate: certFile}},
			expectedError:  sentinelTLSErrors.KeyNotDefined,
		},
		{
			description:    "tls defined with certificate and key",
			sentinelConfig: &config.SentinelConfig{TLS: &config.TLSConfig{Certificate: certFile, Key: keyFile, CACertificate: caCert}},
			expectedCerts:  1,
			checkRootCAs: func(t *testing.T, tlsConfig *tls.Config) {
				// When CA certificate is specified, RootCAs should be set
				require.NotNil(t, tlsConfig.RootCAs)
			},
		},
		{
			description:    "tls defined with only CA certificate",
			sentinelConfig: &config.SentinelConfig{TLS: &config.TLSConfig{CACertificate: caCert}},
			expectedCerts:  0,
			checkRootCAs: func(t *testing.T, tlsConfig *tls.Config) {
				// When CA certificate is specified, RootCAs should be set
				require.NotNil(t, tlsConfig.RootCAs)
			},
		},
		{
			description:    "tls defined without CA certificate uses system store",
			sentinelConfig: &config.SentinelConfig{TLS: &config.TLSConfig{}},
			expectedCerts:  0,
			checkRootCAs: func(t *testing.T, tlsConfig *tls.Config) {
				// When no CA certificate is specified, RootCAs should be nil (uses system store)
				require.Nil(t, tlsConfig.RootCAs)
			},
		},
	}

	for _, tc := range testCases {
		t.Run(tc.description, func(t *testing.T) {
			tlsConfig, err := sentinelTLSOptions(tc.sentinelConfig)

			if tc.expectedError != nil {
				require.ErrorIs(t, err, tc.expectedError)
			} else {
				require.NoError(t, err)
				require.Len(t, tlsConfig.Certificates, tc.expectedCerts)
				if tc.checkRootCAs != nil {
					tc.checkRootCAs(t, tlsConfig)
				}
			}
		})
	}
}

func TestSentinelOptionsWithRedissSchemeTLS(t *testing.T) {
	testCases := []struct {
		description       string
		inputSentinel     []string
		sentinelTLSConfig *config.TLSConfig
		expectedTLSConfig bool
		expectedError     bool
	}{
		{
			description:       "rediss:// scheme enables TLS",
			inputSentinel:     []string{"rediss://localhost:26480"},
			expectedTLSConfig: true,
		},
		{
			description:       "redis:// scheme does not enable TLS",
			inputSentinel:     []string{"redis://localhost:26480"},
			expectedTLSConfig: false,
		},
		{
			description:       "multiple rediss:// schemes",
			inputSentinel:     []string{"rediss://localhost:26480", "rediss://localhost:26481"},
			expectedTLSConfig: true,
		},
		{
			description:       "multiple redis:// schemes",
			inputSentinel:     []string{"redis://localhost:26480", "redis://localhost:26481"},
			expectedTLSConfig: false,
		},
		{
			description:   "mixed redis:// and rediss:// schemes fails without explicit TLS config",
			inputSentinel: []string{"redis://localhost:26480", "rediss://localhost:26481"},
			expectedError: true,
		},
		{
			description:       "mixed schemes allowed with explicit TLS config",
			inputSentinel:     []string{"redis://localhost:26480", "rediss://localhost:26481"},
			sentinelTLSConfig: &config.TLSConfig{},
			expectedTLSConfig: true,
		},
	}

	for _, tc := range testCases {
		t.Run(tc.description, func(t *testing.T) {
			sentinelUrls := make([]config.TomlURL, len(tc.inputSentinel))

			for i, str := range tc.inputSentinel {
				parsedURL := helper.URLMustParse(str)
				sentinelUrls[i] = config.TomlURL{URL: *parsedURL}
			}

			redisCfg := &config.RedisConfig{
				Sentinel: sentinelUrls,
			}

			sentinelCfg := &config.SentinelConfig{
				TLS: tc.sentinelTLSConfig,
			}

			options, err := sentinelOptions(&config.Config{
				Redis:    redisCfg,
				Sentinel: sentinelCfg,
			})

			if tc.expectedError {
				require.Error(t, err)
				require.Contains(t, err.Error(), "inconsistent sentinel URL schemes")
			} else {
				require.NoError(t, err)
				if tc.expectedTLSConfig {
					require.NotNil(t, options.SentinelTLSConfig)
				} else {
					require.Nil(t, options.SentinelTLSConfig)
				}
			}
		})
	}
}

func TestRedisTLSOptions(t *testing.T) {
	testCases := []struct {
		description   string
		redisConfig   *config.TLSConfig
		expectedError error
		expectedCerts int
		checkRootCAs  func(t *testing.T, tlsConfig *tls.Config)
	}{
		{
			description:   "no tls defined",
			redisConfig:   nil,
			expectedError: nil,
		},
		{
			description:   "certificate missing",
			redisConfig:   &config.TLSConfig{Key: keyFile},
			expectedError: redisTLSErrors.CertificateNotDefined,
		},
		{
			description:   "key missing",
			redisConfig:   &config.TLSConfig{Certificate: certFile},
			expectedError: redisTLSErrors.KeyNotDefined,
		},
		{
			description:   "tls defined with certificate and key",
			redisConfig:   &config.TLSConfig{Certificate: certFile, Key: keyFile, CACertificate: caCert},
			expectedCerts: 1,
			checkRootCAs: func(t *testing.T, tlsConfig *tls.Config) {
				require.NotNil(t, tlsConfig.RootCAs)
			},
		},
		{
			description:   "tls defined with only CA certificate",
			redisConfig:   &config.TLSConfig{CACertificate: caCert},
			expectedCerts: 0,
			checkRootCAs: func(t *testing.T, tlsConfig *tls.Config) {
				require.NotNil(t, tlsConfig.RootCAs)
			},
		},
		{
			description:   "tls defined without CA certificate uses system store",
			redisConfig:   &config.TLSConfig{},
			expectedCerts: 0,
			checkRootCAs: func(t *testing.T, tlsConfig *tls.Config) {
				require.Nil(t, tlsConfig.RootCAs)
			},
		},
		{
			description:   "tls with min and max versions",
			redisConfig:   &config.TLSConfig{MinVersion: "tls1.2", MaxVersion: "tls1.3"},
			expectedCerts: 0,
			checkRootCAs: func(t *testing.T, tlsConfig *tls.Config) {
				require.Equal(t, uint16(tls.VersionTLS12), tlsConfig.MinVersion)
				require.Equal(t, uint16(tls.VersionTLS13), tlsConfig.MaxVersion)
			},
		},
	}

	for _, tc := range testCases {
		t.Run(tc.description, func(t *testing.T) {
			tlsConfig, err := redisTLSOptions(tc.redisConfig)

			if tc.expectedError != nil {
				require.ErrorIs(t, err, tc.expectedError)
			} else {
				require.NoError(t, err)
				if tlsConfig != nil {
					require.Len(t, tlsConfig.Certificates, tc.expectedCerts)
					if tc.checkRootCAs != nil {
						tc.checkRootCAs(t, tlsConfig)
					}
				}
			}
		})
	}
}

func TestConfigureRedisWithTLS(t *testing.T) {
	testCases := []struct {
		description string
		scheme      string
		tlsConfig   *config.TLSConfig
		expectError bool
	}{
		{
			description: "redis without TLS",
			scheme:      "redis",
			tlsConfig:   nil,
			expectError: false,
		},
		{
			description: "redis with explicit TLS config",
			scheme:      "redis",
			tlsConfig:   &config.TLSConfig{Certificate: certFile, Key: keyFile},
			expectError: false,
		},
		{
			description: "rediss with explicit TLS config",
			scheme:      "rediss",
			tlsConfig:   &config.TLSConfig{Certificate: certFile, Key: keyFile},
			expectError: false,
		},
		{
			description: "redis with TLS CA certificate only",
			scheme:      "redis",
			tlsConfig:   &config.TLSConfig{CACertificate: caCert},
			expectError: false,
		},
		{
			description: "redis with TLS certificate missing key",
			scheme:      "redis",
			tlsConfig:   &config.TLSConfig{Certificate: certFile},
			expectError: true,
		},
		{
			description: "redis with TLS key missing certificate",
			scheme:      "redis",
			tlsConfig:   &config.TLSConfig{Key: keyFile},
			expectError: true,
		},
	}

	for _, tc := range testCases {
		t.Run(tc.description, func(t *testing.T) {
			connectReceived := atomic.Value{}
			a := mockRedisServer(t, &connectReceived)

			parsedURL := helper.URLMustParse(tc.scheme + "://" + a)
			redisCfg := &config.RedisConfig{
				URL: config.TomlURL{URL: *parsedURL},
				TLS: tc.tlsConfig,
			}
			cfg := &config.Config{Redis: redisCfg}

			rdb, err := Configure(cfg)

			if tc.expectError {
				require.Error(t, err)
			} else {
				require.NoError(t, err)
				require.NotNil(t, rdb)
				defer rdb.Close()

				// Verify TLS config is set when provided
				if tc.tlsConfig != nil {
					opt := rdb.Options()
					require.NotNil(t, opt.TLSConfig)
				}
			}
		})
	}
}
