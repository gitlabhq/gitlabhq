package redis

import (
	"context"
	"crypto/tls"
	"fmt"
	"net"
	"sync/atomic"
	"testing"

	"github.com/prometheus/client_golang/prometheus"
	"github.com/prometheus/client_golang/prometheus/testutil"
	redis "github.com/redis/go-redis/v9"
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

func mockRedisServer(t *testing.T) (string, *atomic.Value) {
	connectReceived := &atomic.Value{}
	ln, err := net.Listen("tcp", "127.0.0.1:0")

	require.NoError(t, err)

	go func() {
		defer ln.Close()
		conn, err := ln.Accept()
		assert.NoError(t, err)
		connectReceived.Store(true)
		conn.Write([]byte("OK\n"))
	}()

	return ln.Addr().String(), connectReceived
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
			a, connectReceived := mockRedisServer(t)

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
			a, connectReceived := mockRedisServer(t)

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
			a, _ := mockRedisServer(t)

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

func TestProcessHookIncrementsTotalRequests(t *testing.T) {
	before := testutil.ToFloat64(TotalRequests)

	process := noopProcessHook()

	err := process(context.Background(), redis.NewCmd(context.Background(), "get", "key"))
	require.NoError(t, err)

	after := testutil.ToFloat64(TotalRequests)
	require.InDelta(t, before+1, after, 0.001)
}

func TestProcessHookObservesDurationForRegularCommands(t *testing.T) {
	before := histogramSampleCount(t, TotalRequestDuration)

	process := noopProcessHook()

	err := process(context.Background(), redis.NewCmd(context.Background(), "get", "key"))
	require.NoError(t, err)

	after := histogramSampleCount(t, TotalRequestDuration)
	require.Equal(t, before+1, after, "regular command should observe duration")
}

func TestProcessHookSkipsDurationForBlockingCommands(t *testing.T) {
	before := histogramSampleCount(t, TotalRequestDuration)

	process := noopProcessHook()

	err := process(context.Background(), redis.NewCmd(context.Background(), "brpop", "key", "0"))
	require.NoError(t, err)

	after := histogramSampleCount(t, TotalRequestDuration)
	require.Equal(t, before, after, "blocking command should not observe duration")
}

func TestProcessPipelineHookCountsAllCommands(t *testing.T) {
	before := testutil.ToFloat64(TotalRequests)

	pipeline := noopProcessPipelineHook()

	cmds := []redis.Cmder{
		redis.NewCmd(context.Background(), "get", "a"),
		redis.NewCmd(context.Background(), "set", "b", "1"),
		redis.NewCmd(context.Background(), "get", "c"),
	}

	err := pipeline(context.Background(), cmds)
	require.NoError(t, err)

	after := testutil.ToFloat64(TotalRequests)
	require.InDelta(t, before+3, after, 0.001)
}

func TestProcessPipelineHookObservesDurationPerCommand(t *testing.T) {
	before := histogramSampleCount(t, TotalRequestDuration)

	pipeline := noopProcessPipelineHook()

	cmds := []redis.Cmder{
		redis.NewCmd(context.Background(), "get", "a"),
		redis.NewCmd(context.Background(), "set", "b", "1"),
		redis.NewCmd(context.Background(), "get", "c"),
	}

	err := pipeline(context.Background(), cmds)
	require.NoError(t, err)

	after := histogramSampleCount(t, TotalRequestDuration)
	require.Equal(t, before+3, after, "should observe duration once per command in pipeline")
}

func TestProcessPipelineHookSkipsDurationWhenBlockingCommandPresent(t *testing.T) {
	before := histogramSampleCount(t, TotalRequestDuration)

	pipeline := noopProcessPipelineHook()

	cmds := []redis.Cmder{
		redis.NewCmd(context.Background(), "get", "a"),
		redis.NewCmd(context.Background(), "blpop", "queue", "0"),
	}

	err := pipeline(context.Background(), cmds)
	require.NoError(t, err)

	after := histogramSampleCount(t, TotalRequestDuration)
	require.Equal(t, before, after, "pipeline with blocking command should not observe duration")
}

func noopProcessHook() redis.ProcessHook {
	hook := instrumentationHook{isSentinel: false}
	return hook.ProcessHook(func(_ context.Context, _ redis.Cmder) error {
		return nil
	})
}

func noopProcessPipelineHook() redis.ProcessPipelineHook {
	hook := instrumentationHook{isSentinel: false}
	return hook.ProcessPipelineHook(func(_ context.Context, _ []redis.Cmder) error {
		return nil
	})
}

// histogramSampleCount returns the current sample count from a Prometheus histogram.
func histogramSampleCount(t *testing.T, h prometheus.Histogram) uint64 {
	t.Helper()

	reg := prometheus.NewRegistry()
	require.NoError(t, reg.Register(h))

	families, err := reg.Gather()
	require.NoError(t, err)
	require.Len(t, families, 1)

	metrics := families[0].GetMetric()
	require.NotEmpty(t, metrics)

	return metrics[0].GetHistogram().GetSampleCount()
}

func TestDialHookIncrementsSentinelMasterErrorCounter(t *testing.T) {
	testCases := []struct {
		name        string
		isSentinel  bool
		dialErr     error
		expectedInc float64
		description string
	}{
		{
			name:        "sentinel hook with sentinel master addr error increments counter",
			isSentinel:  true,
			dialErr:     errSentinelMasterAddr,
			expectedInc: 1,
		},
		{
			name:        "sentinel hook with different error does not increment counter",
			isSentinel:  true,
			dialErr:     fmt.Errorf("some other error"),
			expectedInc: 0,
		},
		{
			name:        "sentinel hook with nil error does not increment counter",
			isSentinel:  true,
			dialErr:     nil,
			expectedInc: 0,
		},
		{
			name:        "non-sentinel hook with sentinel master addr error does not increment counter",
			isSentinel:  false,
			dialErr:     errSentinelMasterAddr,
			expectedInc: 0,
		},
	}

	for _, tc := range testCases {
		t.Run(tc.name, func(t *testing.T) {
			before := testutil.ToFloat64(ErrorCounter.WithLabelValues("master", "sentinel"))

			hook := instrumentationHook{isSentinel: tc.isSentinel}
			dial := hook.DialHook(func(_ context.Context, _, _ string) (net.Conn, error) {
				return nil, tc.dialErr
			})

			conn, err := dial(context.Background(), "tcp", "127.0.0.1:6379")

			if tc.dialErr != nil {
				require.Error(t, err)
				require.Nil(t, conn)
			} else {
				require.NoError(t, err)
			}

			after := testutil.ToFloat64(ErrorCounter.WithLabelValues("master", "sentinel"))
			require.InDelta(t, tc.expectedInc, after-before, 0.001)
		})
	}
}

func TestConfigureSentinelWithRedisTLS(t *testing.T) {
	testCases := []struct {
		description    string
		redisTLSCfg    *config.TLSConfig
		sentinelTLSCfg *config.TLSConfig
		expectError    bool
	}{
		{
			description:    "Sentinel without TLS, Redis without TLS",
			redisTLSCfg:    nil,
			sentinelTLSCfg: nil,
			expectError:    false,
		},
		{
			description:    "Sentinel without TLS, Redis with TLS",
			redisTLSCfg:    &config.TLSConfig{Certificate: certFile, Key: keyFile},
			sentinelTLSCfg: nil,
			expectError:    false,
		},
		{
			description:    "Sentinel with TLS, Redis with TLS",
			redisTLSCfg:    &config.TLSConfig{Certificate: certFile, Key: keyFile},
			sentinelTLSCfg: &config.TLSConfig{Certificate: certFile, Key: keyFile},
			expectError:    false,
		},
		{
			description:    "Sentinel with TLS, Redis without TLS",
			redisTLSCfg:    nil,
			sentinelTLSCfg: &config.TLSConfig{Certificate: certFile, Key: keyFile},
			expectError:    false,
		},
		{
			description:    "Redis with invalid TLS config",
			redisTLSCfg:    &config.TLSConfig{Certificate: certFile},
			sentinelTLSCfg: nil,
			expectError:    true,
		},
	}

	for _, tc := range testCases {
		t.Run(tc.description, func(t *testing.T) {
			a, _ := mockRedisServer(t)

			scheme := "redis://"
			if tc.sentinelTLSCfg != nil {
				scheme = "rediss://"
			}
			sentinelURL := helper.URLMustParse(scheme + a)
			redisCfg := &config.RedisConfig{
				Sentinel:       []config.TomlURL{{URL: *sentinelURL}},
				SentinelMaster: "mymaster",
				TLS:            tc.redisTLSCfg,
			}

			sentinelCfg := &config.SentinelConfig{
				TLS: tc.sentinelTLSCfg,
			}

			cfg := &config.Config{
				Redis:    redisCfg,
				Sentinel: sentinelCfg,
			}

			rdb, err := Configure(cfg)

			if tc.expectError {
				require.Error(t, err)
			} else {
				require.NoError(t, err)
				require.NotNil(t, rdb)
				defer rdb.Close()

				// TLS configs are passed to the dialer, not stored in options.
				// The best we can do is ensure the Configure worked without errors.
				opt := rdb.Options()
				require.NotNil(t, opt.Dialer)
			}
		})
	}
}
