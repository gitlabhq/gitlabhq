package main

import (
	"context"
	"flag"
	"fmt"
	"log/slog"
	"net"
	"net/http"
	_ "net/http/pprof" // nolint:gosec
	"os"
	"os/signal"
	"syscall"
	"time"

	goredis "github.com/redis/go-redis/v9"
	"github.com/sirupsen/logrus"

	"gitlab.com/gitlab-org/labkit/fips"
	"gitlab.com/gitlab-org/labkit/v2/log"

	"gitlab.com/gitlab-org/labkit/monitoring"
	"gitlab.com/gitlab-org/labkit/tracing"

	"gitlab.com/gitlab-org/gitlab/workhorse/internal/config"
	"gitlab.com/gitlab-org/gitlab/workhorse/internal/gitaly"
	"gitlab.com/gitlab-org/gitlab/workhorse/internal/healthcheck"
	"gitlab.com/gitlab-org/gitlab/workhorse/internal/listener"
	"gitlab.com/gitlab-org/gitlab/workhorse/internal/loadshedding"
	"gitlab.com/gitlab-org/gitlab/workhorse/internal/queueing"
	"gitlab.com/gitlab-org/gitlab/workhorse/internal/redis"
	"gitlab.com/gitlab-org/gitlab/workhorse/internal/secret"
	"gitlab.com/gitlab-org/gitlab/workhorse/internal/upstream"
	"gitlab.com/gitlab-org/gitlab/workhorse/internal/version"
)

// Version is the current version of GitLab Workhorse
var Version = "(unknown version)" // Set at build time in the Makefile

// BuildTime signifies the time the binary was build
var BuildTime = "19700101.000000" // Set at build time in the Makefile

type bootConfig struct {
	secretPath           string
	listenAddr           string
	listenNetwork        string
	listenUmask          int
	pprofListenAddr      string
	prometheusListenAddr string
	logFile              string
	logFormat            string
	printVersion         bool
}

func main() {
	boot, cfg, err := buildConfig(os.Args[0], os.Args[1:])
	if err == (alreadyPrintedError{flag.ErrHelp}) {
		os.Exit(0)
	}
	if err != nil {
		if _, alreadyPrinted := err.(alreadyPrintedError); !alreadyPrinted {
			_, _ = fmt.Fprintln(os.Stderr, err)
		}
		os.Exit(2)
	}

	version.SetVersion(Version, BuildTime)

	if boot.printVersion {
		fmt.Println(version.GetApplicationVersion())
		os.Exit(0)
	}

	if err := run(*boot, *cfg); err != nil {
		fmt.Fprintf(os.Stderr, "shutting down: %v\n", err)
		os.Exit(1)
	}
	fmt.Fprintln(os.Stderr, "shutting down")
	os.Exit(0)
}

type alreadyPrintedError struct{ error }

// setupFlagSet initializes and configures the flag set for command line parsing
func setupFlagSet(arg0 string, boot *bootConfig, cfg *config.Config) (fset *flag.FlagSet, configFile, authBackend, cableBackend, iamServiceBackend *string) {
	fset = flag.NewFlagSet(arg0, flag.ContinueOnError)
	fset.Usage = func() {
		_, _ = fmt.Fprintf(fset.Output(), "Usage of %s:\n", arg0)
		_, _ = fmt.Fprintf(fset.Output(), "\n  %s [OPTIONS]\n\nOptions:\n", arg0)
		fset.PrintDefaults()
	}

	configFile = fset.String("config", "", "TOML file to load config from")

	fset.StringVar(&boot.secretPath, "secretPath", "./.gitlab_workhorse_secret", "File with secret key to authenticate with authBackend")
	fset.StringVar(&boot.listenAddr, "listenAddr", "localhost:8181", "Listen address for HTTP server")
	fset.StringVar(&boot.listenNetwork, "listenNetwork", "tcp", "Listen 'network' (tcp, tcp4, tcp6, unix)")
	fset.IntVar(&boot.listenUmask, "listenUmask", 0, "Umask for Unix socket")
	fset.StringVar(&boot.pprofListenAddr, "pprofListenAddr", "", "pprof listening address, e.g. 'localhost:6060'")
	fset.StringVar(&boot.prometheusListenAddr, "prometheusListenAddr", "", "Prometheus listening address, e.g. 'localhost:9229'")

	fset.StringVar(&boot.logFile, "logFile", "", "Log file location")
	fset.StringVar(&boot.logFormat, "logFormat", "text", "Log format to use defaults to text (text, json, structured, none)")

	fset.BoolVar(&boot.printVersion, "version", false, "Print version and exit")

	// gitlab-rails backend
	authBackend = fset.String("authBackend", upstream.DefaultBackend.String(), "Authentication/authorization backend")
	fset.StringVar(&cfg.Socket, "authSocket", "", "Optional: Unix domain socket to dial authBackend at")

	// actioncable backend
	cableBackend = fset.String("cableBackend", "", "ActionCable backend")
	fset.StringVar(&cfg.CableSocket, "cableSocket", "", "Optional: Unix domain socket to dial cableBackend at")

	// IAM Auth service backend (AUTH-011). When unset, OAuth IAM proxy routing is disabled.
	iamServiceBackend = fset.String("iamServiceURL", "", "Optional: URL of the IAM Auth service for OAuth request routing during the AUTH-011 gradual rollout")

	fset.StringVar(&cfg.DocumentRoot, "documentRoot", "public", "Path to static files content")
	fset.DurationVar(&cfg.ProxyHeadersTimeout, "proxyHeadersTimeout", 5*time.Minute, "How long to wait for response headers when proxying the request")
	fset.BoolVar(&cfg.DevelopmentMode, "developmentMode", false, "Allow the assets to be served from Rails app")
	fset.UintVar(&cfg.APILimit, "apiLimit", 0, "Number of API requests allowed at single time")
	fset.UintVar(&cfg.APIQueueLimit, "apiQueueLimit", 0, "Number of API requests allowed to be queued")
	fset.DurationVar(&cfg.APIQueueTimeout, "apiQueueDuration", queueing.DefaultTimeout, "Maximum queueing duration of requests")
	fset.DurationVar(&cfg.APICILongPollingDuration, "apiCiLongPollingDuration", 50, "Long polling duration for job requesting for runners")
	fset.BoolVar(&cfg.PropagateCorrelationID, "propagateCorrelationID", false, "Reuse existing Correlation-ID from the incoming request header `X-Request-ID` if present")

	return fset, configFile, authBackend, cableBackend, iamServiceBackend
}

// buildConfig may print messages to os.Stderr if err != nil. If err is
// of type alreadyPrintedError it has already been printed.
func buildConfig(arg0 string, args []string) (*bootConfig, *config.Config, error) {
	boot := &bootConfig{}
	cfg := config.NewDefaultConfig()
	cfg.Version = Version

	fset, configFile, authBackend, cableBackend, iamServiceBackend := setupFlagSet(arg0, boot, cfg)

	if err := fset.Parse(args); err != nil {
		return nil, nil, alreadyPrintedError{err}
	}
	if fset.NArg() > 0 {
		err := alreadyPrintedError{fmt.Errorf("unexpected arguments: %v", fset.Args())}
		_, _ = fmt.Fprintln(fset.Output(), err)
		fset.Usage()
		return nil, nil, err
	}

	var err error
	cfg.Backend, err = parseAuthBackend(*authBackend)
	if err != nil {
		return nil, nil, fmt.Errorf("authBackend: %v", err)
	}

	if *cableBackend != "" {
		// A custom -cableBackend has been specified
		cfg.CableBackend, err = parseAuthBackend(*cableBackend)
		if err != nil {
			return nil, nil, fmt.Errorf("cableBackend: %v", err)
		}
	} else {
		cfg.CableBackend = cfg.Backend
	}

	// Allow the IAM service URL to be set via env var as well as CLI flag,
	// so cloud-native deployments can configure it through standard container
	// env injection without templating a CLI arg. CLI flag wins when both are
	// set. The bare IAM_SERVICE_URL name follows the convention established
	// by the auth-architecture sandbox-config (see !27), where the same name
	// was first introduced. Reusing this name lets a follow-up sandbox MR
	// re-add it to global.extraEnv without introducing a new convention.
	iamURL := *iamServiceBackend
	if iamURL == "" {
		iamURL = os.Getenv("IAM_SERVICE_URL")
	}
	if iamURL != "" {
		cfg.IAMServiceURL, err = parseAuthBackend(iamURL)
		if err != nil {
			return nil, nil, fmt.Errorf("iamServiceURL: %v", err)
		}
	}

	cfgFromFile, err := config.LoadConfigFromFile(configFile)
	if err != nil {
		return nil, nil, fmt.Errorf("configFile: %v", err)
	}

	if err := cfg.MergeFromFile(cfgFromFile, boot.prometheusListenAddr); err != nil {
		return nil, nil, err
	}

	return boot, cfg, nil
}

// initializePprof starts the profiler HTTP listener. The profiler is only
// activated by HTTP requests, which can only reach it if a listener is started.
// With no listener address configured (the default), the profiler is
// effectively disabled.
func initializePprof(listenerAddress string, errors chan error) (*http.Server, error) {
	if listenerAddress == "" {
		return nil, nil
	}

	l, err := net.Listen("tcp", listenerAddress)
	if err != nil {
		return nil, fmt.Errorf("pprofListenAddr: %v", err)
	}

	server := &http.Server{
		Addr:         listenerAddress,
		Handler:      nil,
		ReadTimeout:  10 * time.Second,
		WriteTimeout: 10 * time.Second,
		IdleTimeout:  10 * time.Second,
	}

	go func() {
		errors <- server.Serve(l)
	}()

	return server, nil
}

func buildListeners(boot bootConfig, cfg config.Config) ([]net.Listener, error) {
	listenerFromBootConfig := config.ListenerConfig{
		Network: boot.listenNetwork,
		Addr:    boot.listenAddr,
	}

	var listeners []net.Listener
	oldUmask := syscall.Umask(boot.listenUmask)
	defer syscall.Umask(oldUmask)

	for _, listenerCfg := range append(cfg.Listeners, listenerFromBootConfig) {
		l, err := listener.New("upstream", listenerCfg)
		if err != nil {
			return nil, err
		}
		listeners = append(listeners, l)
	}

	return listeners, nil
}

func gracefulShutdown(
	srv *http.Server,
	cfg config.Config,
	redisKeyWatcher *redis.KeyWatcher,
	healthCheckServer *healthcheck.Server,
	shutdownCh chan struct{},
	upgradedConnsManager *upstream.UpgradedConnsManager,
) error {
	if healthCheckServer != nil {
		healthCheckServer.InitiateShutdown()
		// Signal upstream to stop accepting long polling requests because
		// requests can arrive during the graceful shutdown time.
		close(shutdownCh)
		// Kick out any long poll requests
		redisKeyWatcher.Shutdown()

		// Wait for the graceful shutdown delay to complete before shutting down the server
		gracefulShutdownDelay := healthCheckServer.GetGracefulShutdownDelay()
		if gracefulShutdownDelay > 0 {
			slog.With(
				"shutdown_delay_s", gracefulShutdownDelay.Seconds(),
			).Info("Waiting for graceful shutdown delay")

			go upgradedConnsManager.Shutdown(gracefulShutdownDelay)

			time.Sleep(gracefulShutdownDelay)
		}
	} else {
		redisKeyWatcher.Shutdown()
	}

	ctx, cancel := context.WithTimeout(context.Background(), cfg.ShutdownTimeout.Duration) // lint:allow context.Background
	defer cancel()

	return srv.Shutdown(ctx)
}

func setupMonitoring(cfg config.Config, finalErrors chan<- error) error {
	monitoringOpts := []monitoring.Option{monitoring.WithBuildInformation(Version, BuildTime)}
	if cfg.MetricsListener != nil {
		l, err := listener.New("metrics", *cfg.MetricsListener)
		if err != nil {
			return err
		}
		monitoringOpts = append(monitoringOpts, monitoring.WithListener(l))
	}

	go func() {
		// Unlike http.Serve, which always returns a non-nil error,
		// monitoring.Start may return nil in which case we should not shut down.
		if err := monitoring.Start(monitoringOpts...); err != nil {
			finalErrors <- err
		}
	}()

	return nil
}

// setupLoadShedding initializes the load shedding service when it is enabled in
// the configuration, starting it in the background and returning its shedder.
// It returns a nil shedder (and no error) when load shedding is not configured.
func setupLoadShedding(cfg config.Config, accessLogger *logrus.Logger) (*loadshedding.LoadShedder, error) {
	if cfg.LoadSheddingConfig == nil || !cfg.LoadSheddingConfig.Enabled {
		return nil, nil
	}

	cfg.ApplyLoadSheddingDefaults()

	loadSheddingService, shedder, err := loadshedding.NewLoadSheddingService(cfg.LoadSheddingConfig, accessLogger)
	if err != nil {
		return nil, fmt.Errorf("failed to create load shedding service: %v", err)
	}

	// Start load shedding service in background
	go loadSheddingService.Start(context.Background()) // lint:allow context.Background

	return shedder, nil
}

// setupRedis configures the Redis client and its key watcher, starting the
// watcher in the background when a client is available. A nil client is not
// fatal: the key watcher tolerates it and Workhorse continues without Redis.
func setupRedis(cfg *config.Config) (*goredis.Client, *redis.KeyWatcher) {
	slog.Info("Using redis/go-redis")

	rdb, err := redis.Configure(cfg)
	if err != nil {
		// #nosec G706 -- Log taint false positive due to old golangci version
		slog.Error("unable to configure redis client", log.Error(err))
	}

	redisKeyWatcher := redis.NewKeyWatcher(rdb)
	if rdb != nil {
		go redisKeyWatcher.Process()
	}

	return rdb, redisKeyWatcher
}

// serveAndWait wires up the upstream handler, starts the HTTP server on every
// listener, and blocks until either a listener fails or a shutdown signal
// arrives, in which case it performs a graceful shutdown. The shutdown channel
// and upgraded-connections manager created here are shared between the upstream
// and the graceful shutdown.
func serveAndWait(cfg config.Config, accessLogger *logrus.Logger, redisKeyWatcher *redis.KeyWatcher, rdb *goredis.Client, healthCheckServer *healthcheck.Server, loadShedder *loadshedding.LoadShedder, listeners []net.Listener, finalErrors chan error, done chan os.Signal) error {
	shutdownCh := make(chan struct{})
	upgradedConnsManager := &upstream.UpgradedConnsManager{}
	deps := upstream.Dependencies{
		AccessLogger:         accessLogger,
		WatchKeyHandler:      redisKeyWatcher.WatchKey,
		Rdb:                  rdb,
		HealthCheckServer:    healthCheckServer,
		ShutdownChan:         shutdownCh,
		UpgradedConnsManager: upgradedConnsManager,
		LoadShedder:          loadShedder,
	}

	srv := startServer(wrapRaven(upstream.NewUpstream(cfg, deps)), listeners, finalErrors)

	select {
	case err := <-finalErrors:
		return err
	case sig := <-done:
		slog.With(
			"shutdown_timeout_s", cfg.ShutdownTimeout.Duration.Seconds(),
			"signal", sig.String(),
		).Info("shutdown initiated")
		return gracefulShutdown(srv, cfg, redisKeyWatcher, healthCheckServer, shutdownCh, upgradedConnsManager)
	}
}

// startServer builds the HTTP server and starts serving on every listener,
// funneling serve errors into finalErrors. It returns the server so the caller
// can shut it down.
func startServer(handler http.Handler, listeners []net.Listener, finalErrors chan<- error) *http.Server {
	srv := &http.Server{
		Handler: handler,
		// ReadHeaderTimeout bounds the time spent reading request headers to
		// mitigate Slowloris-style attacks (gosec G112). It does not limit the
		// time to read the request body, so large uploads are unaffected.
		ReadHeaderTimeout: 1 * time.Minute,
	}

	for _, l := range listeners {
		go func(l net.Listener) { finalErrors <- srv.Serve(l) }(l)
	}

	return srv
}

// announceStartup initializes tracing, logs the running version, and runs the
// FIPS self-check.
func announceStartup() {
	tracing.Initialize(tracing.WithServiceName("gitlab-workhorse"))
	slog.With(
		"version", Version,
		"build_time", BuildTime,
	).Info("Starting")
	fips.Check()
}

// unlinkUnixSocket removes a stale Unix socket before binding. Good
// housekeeping so a previous unclean shutdown does not block the new listener.
// It is a no-op for non-unix networks.
func unlinkUnixSocket(network, addr string) error {
	if network != "unix" {
		return nil
	}
	if err := os.Remove(addr); err != nil && !os.IsNotExist(err) {
		return err
	}
	return nil
}

// notifyShutdownSignals returns a channel that receives SIGINT and SIGTERM.
func notifyShutdownSignals() chan os.Signal {
	done := make(chan os.Signal, 1)
	signal.Notify(done, syscall.SIGINT, syscall.SIGTERM)
	return done
}

// run() lets us use normal Go error handling; there is no log.Fatal in run().
func run(boot bootConfig, cfg config.Config) error {
	logCloser, err := setupLogging(boot.logFile, boot.logFormat)
	if err != nil {
		return err
	}
	defer logCloser.Close() //nolint:errcheck

	announceStartup()

	if err = unlinkUnixSocket(boot.listenNetwork, boot.listenAddr); err != nil {
		return err
	}

	finalErrors := make(chan error)

	if _, err = initializePprof(boot.pprofListenAddr, finalErrors); err != nil {
		return err
	}

	if err = setupMonitoring(cfg, finalErrors); err != nil {
		return err
	}

	secret.SetPath(boot.secretPath)

	rdb, redisKeyWatcher := setupRedis(&cfg)

	if err = cfg.RegisterGoCloudURLOpeners(); err != nil {
		return fmt.Errorf("register cloud credentials: %v", err)
	}

	accessLogger, accessCloser, err := getAccessLogger(boot.logFile, boot.logFormat)
	if err != nil {
		return fmt.Errorf("configure access logger: %v", err)
	}
	defer accessCloser.Close() //nolint:errcheck

	gitaly.InitializeSidechannelRegistry(accessLogger)

	// Initialize health check server
	healthCheckServer, healthCancel, err := healthcheck.InitializeAndStart(cfg, accessLogger, finalErrors)
	if err != nil {
		return err
	}
	if healthCancel != nil {
		defer healthCancel()
	}

	loadShedder, err := setupLoadShedding(cfg, accessLogger)
	if err != nil {
		return err
	}

	done := notifyShutdownSignals()

	listeners, err := buildListeners(boot, cfg)
	if err != nil {
		return err
	}

	return serveAndWait(cfg, accessLogger, redisKeyWatcher, rdb, healthCheckServer, loadShedder, listeners, finalErrors, done)
}
