package redis

import (
	"context"
	"crypto/tls"
	"crypto/x509"
	"errors"
	"fmt"
	"net"
	"os"
	"time"

	"github.com/prometheus/client_golang/prometheus"
	"github.com/prometheus/client_golang/prometheus/promauto"
	redis "github.com/redis/go-redis/v9"

	"gitlab.com/gitlab-org/gitlab/workhorse/internal/config"
	workhorselog "gitlab.com/gitlab-org/gitlab/workhorse/internal/log"
)

var (
	// found in https://github.com/redis/go-redis/blob/c7399b6a17d7d3e2a57654528af91349f2468529/sentinel.go#L626
	errSentinelMasterAddr = errors.New("redis: all sentinels specified in configuration are unreachable")

	// TotalConnections tracks the total number of Redis connections opened by workhorse.
	TotalConnections = promauto.NewCounter(
		prometheus.CounterOpts{
			Name: "gitlab_workhorse_redis_total_connections",
			Help: "How many connections gitlab-workhorse has opened in total. Can be used to track Redis connection rate for this process",
		},
	)

	// ErrorCounter counts different types of Redis errors by type and destination (redis or sentinel).
	ErrorCounter = promauto.NewCounterVec(
		prometheus.CounterOpts{
			Name: "gitlab_workhorse_redis_errors",
			Help: "Counts different types of Redis errors encountered by workhorse, by type and destination (redis, sentinel)",
		},
		[]string{"type", "dst"},
	)

	errSentinelTLSNotDefined       = fmt.Errorf("configuration Sentinel.tls not defined")
	errSentinelInconsistentSchemes = fmt.Errorf("inconsistent sentinel URL schemes: use all non-TLS (redis:// or tcp://) or all TLS (rediss://)")
)

// TLSErrorMessages holds context-specific error messages for TLS configuration
type TLSErrorMessages struct {
	CertificateNotDefined error
	KeyNotDefined         error
	CannotAppendPEM       error
}

var (
	sentinelTLSErrors = TLSErrorMessages{
		CertificateNotDefined: fmt.Errorf("configuration Sentinel.tls.certificate not defined"),
		KeyNotDefined:         fmt.Errorf("configuration Sentinel.tls.key not defined"),
		CannotAppendPEM:       fmt.Errorf("cannot append PEM certificate from from Sentinel.tls.ca_certificate path"),
	}

	redisTLSErrors = TLSErrorMessages{
		CertificateNotDefined: fmt.Errorf("configuration redis.tls.certificate not defined"),
		KeyNotDefined:         fmt.Errorf("configuration redis.tls.key not defined"),
		CannotAppendPEM:       fmt.Errorf("cannot append PEM certificate from redis.tls.ca_certificate path"),
	}
)

const (
	// Max Idle Connections in the pool.
	defaultMaxIdle = 1
	// Max Active Connections in the pool.
	defaultMaxActive = 1
	// Timeout for Read operations on the pool. 1 second is technically overkill,
	//  it's just for sanity.
	defaultReadTimeout = 1 * time.Second
	// Timeout for Write operations on the pool. 1 second is technically overkill,
	//  it's just for sanity.
	defaultWriteTimeout = 1 * time.Second
	// Timeout before killing Idle connections in the pool. 3 minutes seemed good.
	//  If you _actually_ hit this timeout often, you should consider turning of
	//  redis-support since it's not necessary at that point...
	defaultIdleTimeout = 3 * time.Minute
)

// SentinelOptions contains grouped, related values
type SentinelOptions struct {
	SentinelUsername  string
	SentinelPassword  string
	Sentinels         []string
	SentinelTLSConfig *tls.Config
}

type redisClientLogger struct{}

func (w *redisClientLogger) Printf(_ context.Context, format string, v ...interface{}) {
	workhorselog.Info(fmt.Sprintf(format, v...))
}

func init() {
	redis.SetLogger(&redisClientLogger{})
}

// createDialer references https://github.com/redis/go-redis/blob/b1103e3d436b6fe98813ecbbe1f99dc8d59b06c9/options.go#L214
// it intercepts the error and tracks it via a Prometheus counter
func createDialer(sentinels []string, tlsConfig *tls.Config) func(ctx context.Context, network, addr string) (net.Conn, error) {
	return func(ctx context.Context, network, addr string) (net.Conn, error) {
		var isSentinel bool
		for _, sentinelAddr := range sentinels {
			if sentinelAddr == addr {
				isSentinel = true
				break
			}
		}

		dialTimeout := 5 * time.Second // go-redis default
		destination := "redis"
		if isSentinel {
			// This timeout is recommended for Sentinel-support according to the guidelines.
			//  https://redis.io/topics/sentinel-clients#redis-service-discovery-via-sentinel
			//  For every address it should try to connect to the Sentinel,
			//  using a short timeout (in the order of a few hundreds of milliseconds).
			destination = "sentinel"
			dialTimeout = 500 * time.Millisecond
		}

		netDialer := &net.Dialer{
			Timeout:   dialTimeout,
			KeepAlive: 5 * time.Minute,
		}

		var conn net.Conn
		var err error

		if tlsConfig != nil {
			conn, err = tls.DialWithDialer(netDialer, network, addr, tlsConfig)
		} else {
			conn, err = netDialer.DialContext(ctx, network, addr)
		}

		if err != nil {
			ErrorCounter.WithLabelValues("dial", destination).Inc()
		} else if !isSentinel {
			TotalConnections.Inc()
		}

		return conn, err
	}
}

// implements the redis.Hook interface for instrumentation
type sentinelInstrumentationHook struct{}

func (s sentinelInstrumentationHook) DialHook(next redis.DialHook) redis.DialHook {
	return func(ctx context.Context, network, addr string) (net.Conn, error) {
		conn, err := next(ctx, network, addr)
		if err != nil && err.Error() == errSentinelMasterAddr.Error() {
			// check for non-dialer error
			ErrorCounter.WithLabelValues("master", "sentinel").Inc()
		}
		return conn, err
	}
}

// ProcessHook is a no-op hook for Redis command processing.
func (s sentinelInstrumentationHook) ProcessHook(next redis.ProcessHook) redis.ProcessHook {
	return func(ctx context.Context, cmd redis.Cmder) error {
		return next(ctx, cmd)
	}
}

// ProcessPipelineHook is a no-op hook for Redis pipeline command processing.
func (s sentinelInstrumentationHook) ProcessPipelineHook(next redis.ProcessPipelineHook) redis.ProcessPipelineHook {
	return func(ctx context.Context, cmds []redis.Cmder) error {
		return next(ctx, cmds)
	}
}

// Configure redis-connection
func Configure(cfg *config.Config) (*redis.Client, error) {
	if cfg == nil {
		return nil, nil
	}

	if cfg.Redis == nil {
		return nil, nil
	}

	var rdb *redis.Client
	var err error

	if len(cfg.Redis.Sentinel) > 0 {
		rdb, err = configureSentinel(cfg)
	} else {
		rdb, err = configureRedis(cfg.Redis)
	}

	return rdb, err
}

func configureRedis(cfg *config.RedisConfig) (*redis.Client, error) {
	if cfg.URL.Scheme == "tcp" {
		cfg.URL.Scheme = "redis"
	}

	opt, err := redis.ParseURL(cfg.URL.String())
	if err != nil {
		return nil, err
	}

	opt.DB = getOrDefault(cfg.DB, 0)
	if cfg.Password != "" {
		opt.Password = cfg.Password
	}

	opt.PoolSize = getOrDefault(cfg.MaxActive, defaultMaxActive)
	opt.MaxIdleConns = getOrDefault(cfg.MaxIdle, defaultMaxIdle)
	opt.ConnMaxIdleTime = defaultIdleTimeout
	opt.ReadTimeout = defaultReadTimeout
	opt.WriteTimeout = defaultWriteTimeout

	// Explicit TLS configuration takes precedence over scheme-based detection
	if cfg.TLS != nil {
		tlsConfig, err := redisTLSOptions(cfg.TLS)
		if err != nil {
			return nil, err
		}
		opt.TLSConfig = tlsConfig
	}

	// ParseURL seeds TLSConfig if scheme is rediss
	opt.Dialer = createDialer([]string{}, opt.TLSConfig)

	return redis.NewClient(opt), nil
}

func configureSentinel(cfg *config.Config) (*redis.Client, error) {
	options, err := sentinelOptions(cfg)
	if err != nil {
		return nil, err
	}

	redisCfg := cfg.Redis

	client := redis.NewFailoverClient(&redis.FailoverOptions{
		MasterName:       redisCfg.SentinelMaster,
		SentinelAddrs:    options.Sentinels,
		Password:         redisCfg.Password,
		SentinelUsername: options.SentinelUsername,
		SentinelPassword: options.SentinelPassword,
		DB:               getOrDefault(redisCfg.DB, 0),

		PoolSize:        getOrDefault(redisCfg.MaxActive, defaultMaxActive),
		MaxIdleConns:    getOrDefault(redisCfg.MaxIdle, defaultMaxIdle),
		ConnMaxIdleTime: defaultIdleTimeout,

		ReadTimeout:  defaultReadTimeout,
		WriteTimeout: defaultWriteTimeout,

		Dialer: createDialer(options.Sentinels, options.SentinelTLSConfig),
	})

	client.AddHook(sentinelInstrumentationHook{})

	return client, nil
}

// sentinelOptions extracts the sentinel username and password from the URLs
// and addresses in <host>:<port> format.
// the order of priority for the passwords is: SentinelPassword -> first password-in-url
// SentinelUsername will be the username associated with SentinelPassword.
// TLS is automatically enabled if any Sentinel URL uses the rediss:// scheme.
// Explicit [Sentinel.tls] configuration takes precedence over scheme-based detection.
// When auto-detecting TLS from schemes, all Sentinel URLs must use consistent schemes
// (all redis:// or all rediss://). If explicit [Sentinel.tls] is defined, mixed schemes
// are allowed since the user is explicitly requesting TLS for all connections.
func sentinelOptions(cfg *config.Config) (SentinelOptions, error) {
	redisCfg := cfg.Redis

	sentinels := make([]string, len(redisCfg.Sentinel))
	sentinelUsername := redisCfg.SentinelUsername
	sentinelPassword := redisCfg.SentinelPassword
	hasTLS := false
	hasNonTLS := false

	for i := range redisCfg.Sentinel {
		sentinelDetails := redisCfg.Sentinel[i]
		sentinels[i] = fmt.Sprintf("%s:%s", sentinelDetails.Hostname(), sentinelDetails.Port())

		// Detect TLS from rediss:// scheme
		if sentinelDetails.Scheme == "rediss" {
			hasTLS = true
		} else {
			hasNonTLS = true
		}

		if pw, exist := sentinelDetails.User.Password(); exist && len(sentinelPassword) == 0 {
			// sets password using the first non-empty password
			sentinelPassword = pw

			// If a password is specified, a username is optional. Ensure that we use the
			// username associated with the password.
			if username := sentinelDetails.User.Username(); username != "" && sentinelUsername == "" {
				sentinelUsername = username
			}
		}
	}

	var err error
	var sentinelTLSConfig *tls.Config
	sentinelCfg := cfg.Sentinel

	// Explicit TLS configuration takes precedence
	if sentinelCfg != nil && sentinelCfg.TLS != nil {
		sentinelTLSConfig, err = sentinelTLSOptions(sentinelCfg)
		if err != nil {
			return SentinelOptions{}, err
		}
	} else {
		// Only validate scheme consistency when auto-detecting TLS from schemes
		if hasTLS && hasNonTLS {
			return SentinelOptions{}, errSentinelInconsistentSchemes
		}

		if hasTLS {
			// Auto-enable TLS if rediss:// scheme is detected
			// Use empty TLS config which will use system cert pool
			sentinelTLSConfig = &tls.Config{} //nolint:gosec
		}
	}

	return SentinelOptions{sentinelUsername, sentinelPassword, sentinels, sentinelTLSConfig}, nil
}

// buildTLSConfig constructs a tls.Config from TLSConfig settings.
// The errs parameter provides context-specific error messages for different scenarios.
func buildTLSConfig(tlsCfg *config.TLSConfig, errs TLSErrorMessages) (*tls.Config, error) {
	if tlsCfg == nil {
		return nil, nil
	}

	tlsConfig := &tls.Config{ //nolint:gosec
		MinVersion: config.TLSVersions[tlsCfg.MinVersion],
		MaxVersion: config.TLSVersions[tlsCfg.MaxVersion],
	}

	// By default, use the system store if a CA certificate is not specified
	if tlsCfg.CACertificate != "" {
		certPool := x509.NewCertPool()

		certs, err := os.ReadFile(tlsCfg.CACertificate)
		if err != nil {
			return nil, err
		}

		ok := certPool.AppendCertsFromPEM(certs)
		if !ok {
			return nil, errs.CannotAppendPEM
		}

		tlsConfig.RootCAs = certPool
	}

	// Client certificates are optional
	if tlsCfg.Certificate == "" && tlsCfg.Key == "" {
		return tlsConfig, nil
	}

	if tlsCfg.Certificate == "" {
		return nil, errs.CertificateNotDefined
	}

	if tlsCfg.Key == "" {
		return nil, errs.KeyNotDefined
	}

	cert, err := tls.LoadX509KeyPair(tlsCfg.Certificate, tlsCfg.Key)
	if err != nil {
		return nil, err
	}
	tlsConfig.Certificates = []tls.Certificate{cert}

	return tlsConfig, nil
}

func redisTLSOptions(tlsCfg *config.TLSConfig) (*tls.Config, error) {
	return buildTLSConfig(tlsCfg, redisTLSErrors)
}

func sentinelTLSOptions(sentinelCfg *config.SentinelConfig) (*tls.Config, error) {
	if sentinelCfg == nil || sentinelCfg.TLS == nil {
		return nil, errSentinelTLSNotDefined
	}

	return buildTLSConfig(sentinelCfg.TLS, sentinelTLSErrors)
}

func getOrDefault(ptr *int, val int) int {
	if ptr != nil {
		return *ptr
	}
	return val
}
