package main

import (
	"context"
	"flag"
	"fmt"
	"net"
	"net/http"
	_ "net/http/pprof" // nolint:gosec
	"os"
	"os/signal"
	"syscall"
	"time"

	"gitlab.com/gitlab-org/labkit/fips"
	"gitlab.com/gitlab-org/labkit/log"
	"gitlab.com/gitlab-org/labkit/monitoring"
	"gitlab.com/gitlab-org/labkit/tracing"

	"gitlab.com/gitlab-org/gitlab/workhorse/internal/config"
	"gitlab.com/gitlab-org/gitlab/workhorse/internal/gitaly"
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

	log.WithError(run(*boot, *cfg)).Fatal("shutting down")
}

type alreadyPrintedError struct{ error }

// buildConfig may print messages to os.Stderr if err != nil. If err is
// of type alreadyPrintedError it has already been printed.
func buildConfig(arg0 string, args []string) (*bootConfig, *config.Config, error) {
	boot := &bootConfig{}
	cfg := config.NewDefaultConfig()
	cfg.Version = Version
	fset := flag.NewFlagSet(arg0, flag.ContinueOnError)
	fset.Usage = func() {
		_, _ = fmt.Fprintf(fset.Output(), "Usage of %s:\n", arg0)
		_, _ = fmt.Fprintf(fset.Output(), "\n  %s [OPTIONS]\n\nOptions:\n", arg0)
		fset.PrintDefaults()
	}

	configFile := fset.String("config", "", "TOML file to load config from")

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
	authBackend := fset.String("authBackend", upstream.DefaultBackend.String(), "Authentication/authorization backend")
	fset.StringVar(&cfg.Socket, "authSocket", "", "Optional: Unix domain socket to dial authBackend at")

	// actioncable backend
	cableBackend := fset.String("cableBackend", "", "ActionCable backend")
	fset.StringVar(&cfg.CableSocket, "cableSocket", "", "Optional: Unix domain socket to dial cableBackend at")

	fset.StringVar(&cfg.DocumentRoot, "documentRoot", "public", "Path to static files content")
	fset.DurationVar(&cfg.ProxyHeadersTimeout, "proxyHeadersTimeout", 5*time.Minute, "How long to wait for response headers when proxying the request")
	fset.BoolVar(&cfg.DevelopmentMode, "developmentMode", false, "Allow the assets to be served from Rails app")
	fset.UintVar(&cfg.APILimit, "apiLimit", 0, "Number of API requests allowed at single time")
	fset.UintVar(&cfg.APIQueueLimit, "apiQueueLimit", 0, "Number of API requests allowed to be queued")
	fset.DurationVar(&cfg.APIQueueTimeout, "apiQueueDuration", queueing.DefaultTimeout, "Maximum queueing duration of requests")
	fset.DurationVar(&cfg.APICILongPollingDuration, "apiCiLongPollingDuration", 50, "Long polling duration for job requesting for runners")
	fset.BoolVar(&cfg.PropagateCorrelationID, "propagateCorrelationID", false, "Reuse existing Correlation-ID from the incoming request header `X-Request-ID` if present")

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

	cfgFromFile, err := config.LoadConfigFromFile(configFile)
	if err != nil {
		return nil, nil, fmt.Errorf("configFile: %v", err)
	}

	cfg.MetricsListener = cfgFromFile.MetricsListener
	if boot.prometheusListenAddr != "" {
		if cfg.MetricsListener != nil {
			return nil, nil, fmt.Errorf("configFile: both prometheusListenAddr and metrics_listener can't be specified")
		}
		cfg.MetricsListener = &config.ListenerConfig{Network: "tcp", Addr: boot.prometheusListenAddr}
	}

	cfg.Redis = cfgFromFile.Redis
	cfg.Sentinel = cfgFromFile.Sentinel
	cfg.ObjectStorageCredentials = cfgFromFile.ObjectStorageCredentials
	cfg.ImageResizerConfig = cfgFromFile.ImageResizerConfig
	cfg.AltDocumentRoot = cfgFromFile.AltDocumentRoot
	cfg.ShutdownTimeout = cfgFromFile.ShutdownTimeout
	cfg.TrustedCIDRsForXForwardedFor = cfgFromFile.TrustedCIDRsForXForwardedFor
	cfg.TrustedCIDRsForPropagation = cfgFromFile.TrustedCIDRsForPropagation
	cfg.Listeners = cfgFromFile.Listeners

	return boot, cfg, nil
}

func initializePprof(listenerAddress string, errors chan error) (*http.Server, error) {
	if listenerAddress != "" {
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

// run() lets us use normal Go error handling; there is no log.Fatal in run().
func run(boot bootConfig, cfg config.Config) error {
	closer, err := startLogging(boot.logFile, boot.logFormat)
	if err != nil {
		return err
	}
	defer closer.Close() //nolint:errcheck

	tracing.Initialize(tracing.WithServiceName("gitlab-workhorse"))
	log.WithField("version", Version).WithField("build_time", BuildTime).Print("Starting")
	fips.Check()

	// Good housekeeping for Unix sockets: unlink before binding
	if boot.listenNetwork == "unix" {
		if err = os.Remove(boot.listenAddr); err != nil && !os.IsNotExist(err) {
			return err
		}
	}

	finalErrors := make(chan error)

	// The profiler will only be activated by HTTP requests. HTTP
	// requests can only reach the profiler if we start a listener. So by
	// having no profiler HTTP listener by default, the profiler is
	// effectively disabled by default.
	_, err = initializePprof(boot.pprofListenAddr, finalErrors)
	if err != nil {
		return err
	}

	var l net.Listener

	monitoringOpts := []monitoring.Option{monitoring.WithBuildInformation(Version, BuildTime)}
	if cfg.MetricsListener != nil {
		l, err = newListener("metrics", *cfg.MetricsListener)
		if err != nil {
			return err
		}
		monitoringOpts = append(monitoringOpts, monitoring.WithListener(l))
	}

	go func() {
		// Unlike http.Serve, which always returns a non-nil error,
		// monitoring.Start may return nil in which case we should not shut down.
		if err = monitoring.Start(monitoringOpts...); err != nil {
			finalErrors <- err
		}
	}()

	secret.SetPath(boot.secretPath)

	log.Info("Using redis/go-redis")

	rdb, err := redis.Configure(&cfg)
	if err != nil {
		log.WithError(err).Error("unable to configure redis client")
	}
	redisKeyWatcher := redis.NewKeyWatcher(rdb)

	if rdb != nil {
		go redisKeyWatcher.Process()
	}

	watchKeyFn := redisKeyWatcher.WatchKey

	if err = cfg.RegisterGoCloudURLOpeners(); err != nil {
		return fmt.Errorf("register cloud credentials: %v", err)
	}

	accessLogger, accessCloser, err := getAccessLogger(boot.logFile, boot.logFormat)
	if err != nil {
		return fmt.Errorf("configure access logger: %v", err)
	}
	defer accessCloser.Close() //nolint:errcheck

	gitaly.InitializeSidechannelRegistry(accessLogger)

	up := wrapRaven(upstream.NewUpstream(cfg, accessLogger, watchKeyFn))

	done := make(chan os.Signal, 1)
	signal.Notify(done, syscall.SIGINT, syscall.SIGTERM)

	listenerFromBootConfig := config.ListenerConfig{
		Network: boot.listenNetwork,
		Addr:    boot.listenAddr,
	}
	var listeners []net.Listener
	oldUmask := syscall.Umask(boot.listenUmask)
	for _, cfg := range append(cfg.Listeners, listenerFromBootConfig) {
		l, err := newListener("upstream", cfg)
		if err != nil {
			return err
		}
		listeners = append(listeners, l)
	}
	syscall.Umask(oldUmask)

	srv := &http.Server{Handler: up}

	for _, l := range listeners {
		go func(l net.Listener) { finalErrors <- srv.Serve(l) }(l)
	}

	select {
	case err := <-finalErrors:
		return err
	case sig := <-done:
		log.WithFields(log.Fields{"shutdown_timeout_s": cfg.ShutdownTimeout.Duration.Seconds(), "signal": sig.String()}).Infof("shutdown initiated")

		ctx, cancel := context.WithTimeout(context.Background(), cfg.ShutdownTimeout.Duration) // lint:allow context.Background
		defer cancel()

		redisKeyWatcher.Shutdown()

		return srv.Shutdown(ctx)
	}
}
