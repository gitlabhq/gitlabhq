package redis

import (
	"errors"
	"fmt"
	"net"
	"net/url"
	"time"

	"github.com/FZambia/sentinel"
	"github.com/gomodule/redigo/redis"
	"github.com/prometheus/client_golang/prometheus"
	"github.com/prometheus/client_golang/prometheus/promauto"
	"gitlab.com/gitlab-org/labkit/log"

	"gitlab.com/gitlab-org/gitlab/workhorse/internal/config"
	"gitlab.com/gitlab-org/gitlab/workhorse/internal/helper"
)

var (
	pool  *redis.Pool
	sntnl *sentinel.Sentinel
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
	// KeepAlivePeriod is to keep a TCP connection open for an extended period of
	//  time without being killed. This is used both in the pool, and in the
	//  worker-connection.
	//  See https://en.wikipedia.org/wiki/Keepalive#TCP_keepalive for more
	//  information.
	defaultKeepAlivePeriod = 5 * time.Minute
)

var (
	totalConnections = promauto.NewCounter(
		prometheus.CounterOpts{
			Name: "gitlab_workhorse_redis_total_connections",
			Help: "How many connections gitlab-workhorse has opened in total. Can be used to track Redis connection rate for this process",
		},
	)

	errorCounter = promauto.NewCounterVec(
		prometheus.CounterOpts{
			Name: "gitlab_workhorse_redis_errors",
			Help: "Counts different types of Redis errors encountered by workhorse, by type and destination (redis, sentinel)",
		},
		[]string{"type", "dst"},
	)
)

func sentinelConn(master string, urls []config.TomlURL) *sentinel.Sentinel {
	if len(urls) == 0 {
		return nil
	}
	var addrs []string
	for _, url := range urls {
		h := url.URL.String()
		log.WithFields(log.Fields{
			"scheme": url.URL.Scheme,
			"host":   url.URL.Host,
		}).Printf("redis: using sentinel")
		addrs = append(addrs, h)
	}
	return &sentinel.Sentinel{
		Addrs:      addrs,
		MasterName: master,
		Dial: func(addr string) (redis.Conn, error) {
			// This timeout is recommended for Sentinel-support according to the guidelines.
			//  https://redis.io/topics/sentinel-clients#redis-service-discovery-via-sentinel
			//  For every address it should try to connect to the Sentinel,
			//  using a short timeout (in the order of a few hundreds of milliseconds).
			timeout := 500 * time.Millisecond
			url := helper.URLMustParse(addr)

			var c redis.Conn
			var err error
			options := []redis.DialOption{
				redis.DialConnectTimeout(timeout),
				redis.DialReadTimeout(timeout),
				redis.DialWriteTimeout(timeout),
			}

			if url.Scheme == "redis" || url.Scheme == "rediss" {
				c, err = redis.DialURL(addr, options...)
			} else {
				c, err = redis.Dial("tcp", url.Host, options...)
			}

			if err != nil {
				errorCounter.WithLabelValues("dial", "sentinel").Inc()
				return nil, err
			}
			return c, nil
		},
	}
}

var poolDialFunc func() (redis.Conn, error)
var workerDialFunc func() (redis.Conn, error)

func timeoutDialOptions(cfg *config.RedisConfig) []redis.DialOption {
	return []redis.DialOption{
		redis.DialReadTimeout(defaultReadTimeout),
		redis.DialWriteTimeout(defaultWriteTimeout),
	}
}

func dialOptionsBuilder(cfg *config.RedisConfig, setTimeouts bool) []redis.DialOption {
	var dopts []redis.DialOption
	if setTimeouts {
		dopts = timeoutDialOptions(cfg)
	}
	if cfg == nil {
		return dopts
	}
	if cfg.Password != "" {
		dopts = append(dopts, redis.DialPassword(cfg.Password))
	}
	if cfg.DB != nil {
		dopts = append(dopts, redis.DialDatabase(*cfg.DB))
	}
	return dopts
}

func keepAliveDialer(network, address string) (net.Conn, error) {
	addr, err := net.ResolveTCPAddr(network, address)
	if err != nil {
		return nil, err
	}
	tc, err := net.DialTCP(network, nil, addr)
	if err != nil {
		return nil, err
	}
	if err := tc.SetKeepAlive(true); err != nil {
		return nil, err
	}
	if err := tc.SetKeepAlivePeriod(defaultKeepAlivePeriod); err != nil {
		return nil, err
	}
	return tc, nil
}

type redisDialerFunc func() (redis.Conn, error)

func sentinelDialer(dopts []redis.DialOption) redisDialerFunc {
	return func() (redis.Conn, error) {
		address, err := sntnl.MasterAddr()
		if err != nil {
			errorCounter.WithLabelValues("master", "sentinel").Inc()
			return nil, err
		}
		dopts = append(dopts, redis.DialNetDial(keepAliveDialer))
		return redisDial("tcp", address, dopts...)
	}
}

func defaultDialer(dopts []redis.DialOption, url url.URL) redisDialerFunc {
	return func() (redis.Conn, error) {
		if url.Scheme == "unix" {
			return redisDial(url.Scheme, url.Path, dopts...)
		}

		dopts = append(dopts, redis.DialNetDial(keepAliveDialer))

		// redis.DialURL only works with redis[s]:// URLs
		if url.Scheme == "redis" || url.Scheme == "rediss" {
			return redisURLDial(url, dopts...)
		}

		return redisDial(url.Scheme, url.Host, dopts...)
	}
}

func redisURLDial(url url.URL, options ...redis.DialOption) (redis.Conn, error) {
	log.WithFields(log.Fields{
		"scheme":  url.Scheme,
		"address": url.Host,
	}).Printf("redis: dialing")

	return redis.DialURL(url.String(), options...)
}

func redisDial(network, address string, options ...redis.DialOption) (redis.Conn, error) {
	log.WithFields(log.Fields{
		"network": network,
		"address": address,
	}).Printf("redis: dialing")

	return redis.Dial(network, address, options...)
}

func countDialer(dialer redisDialerFunc) redisDialerFunc {
	return func() (redis.Conn, error) {
		c, err := dialer()
		if err != nil {
			errorCounter.WithLabelValues("dial", "redis").Inc()
		} else {
			totalConnections.Inc()
		}
		return c, err
	}
}

// DefaultDialFunc should always used. Only exception is for unit-tests.
func DefaultDialFunc(cfg *config.RedisConfig, setReadTimeout bool) func() (redis.Conn, error) {
	dopts := dialOptionsBuilder(cfg, setReadTimeout)
	if sntnl != nil {
		return countDialer(sentinelDialer(dopts))
	}
	return countDialer(defaultDialer(dopts, cfg.URL.URL))
}

// Configure redis-connection
func Configure(cfg *config.RedisConfig, dialFunc func(*config.RedisConfig, bool) func() (redis.Conn, error)) {
	if cfg == nil {
		return
	}
	maxIdle := defaultMaxIdle
	if cfg.MaxIdle != nil {
		maxIdle = *cfg.MaxIdle
	}
	maxActive := defaultMaxActive
	if cfg.MaxActive != nil {
		maxActive = *cfg.MaxActive
	}
	sntnl = sentinelConn(cfg.SentinelMaster, cfg.Sentinel)
	workerDialFunc = dialFunc(cfg, false)
	poolDialFunc = dialFunc(cfg, true)
	pool = &redis.Pool{
		MaxIdle:     maxIdle,            // Keep at most X hot connections
		MaxActive:   maxActive,          // Keep at most X live connections, 0 means unlimited
		IdleTimeout: defaultIdleTimeout, // X time until an unused connection is closed
		Dial:        poolDialFunc,
		Wait:        true,
	}
	if sntnl != nil {
		pool.TestOnBorrow = func(c redis.Conn, t time.Time) error {
			if !sentinel.TestRole(c, "master") {
				return errors.New("role check failed")
			}
			return nil
		}
	}
}

// Get a connection for the Redis-pool
func Get() redis.Conn {
	if pool != nil {
		return pool.Get()
	}
	return nil
}

// GetString fetches the value of a key in Redis as a string
func GetString(key string) (string, error) {
	conn := Get()
	if conn == nil {
		return "", fmt.Errorf("redis: could not get connection from pool")
	}
	defer conn.Close()

	return redis.String(conn.Do("GET", key))
}
