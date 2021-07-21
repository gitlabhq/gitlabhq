package main

import (
	"flag"
	"io"
	"io/ioutil"
	"net/url"
	"os"
	"testing"
	"time"

	"github.com/stretchr/testify/require"

	"gitlab.com/gitlab-org/gitlab/workhorse/internal/config"
	"gitlab.com/gitlab-org/gitlab/workhorse/internal/queueing"
	"gitlab.com/gitlab-org/gitlab/workhorse/internal/upstream"
)

func TestDefaultConfig(t *testing.T) {
	_, cfg, err := buildConfig("test", []string{"-config", "/dev/null"})
	require.NoError(t, err, "build config")

	require.Equal(t, 0*time.Second, cfg.ShutdownTimeout.Duration)
}

func TestConfigFile(t *testing.T) {
	f, err := ioutil.TempFile("", "workhorse-config-test")
	require.NoError(t, err)
	defer os.Remove(f.Name())

	data := `
shutdown_timeout = "60s"
[redis]
password = "redis password"
[object_storage]
provider = "test provider"
[image_resizer]
max_scaler_procs = 123
`
	_, err = io.WriteString(f, data)
	require.NoError(t, err)
	require.NoError(t, f.Close())

	_, cfg, err := buildConfig("test", []string{"-config", f.Name()})
	require.NoError(t, err, "build config")

	// These are integration tests: we want to see that each section in the
	// config file ends up in the config struct. We do not test all the
	// fields in each section; that should happen in the tests of the
	// internal/config package.
	require.Equal(t, "redis password", cfg.Redis.Password)
	require.Equal(t, "test provider", cfg.ObjectStorageCredentials.Provider)
	require.Equal(t, uint32(123), cfg.ImageResizerConfig.MaxScalerProcs, "image resizer max_scaler_procs")
	require.Equal(t, 60*time.Second, cfg.ShutdownTimeout.Duration)
}

func TestConfigErrorHelp(t *testing.T) {
	for _, f := range []string{"-h", "-help"} {
		t.Run(f, func(t *testing.T) {
			_, _, err := buildConfig("test", []string{f})
			require.Equal(t, alreadyPrintedError{flag.ErrHelp}, err)
		})
	}
}

func TestConfigError(t *testing.T) {
	for _, arg := range []string{"-foobar", "foobar"} {
		t.Run(arg, func(t *testing.T) {
			_, _, err := buildConfig("test", []string{arg})

			require.Error(t, err)
			require.IsType(t, alreadyPrintedError{}, err)
		})
	}
}

func TestConfigDefaults(t *testing.T) {
	boot, cfg, err := buildConfig("test", nil)
	require.NoError(t, err, "build config")

	expectedBoot := &bootConfig{
		secretPath:    "./.gitlab_workhorse_secret",
		listenAddr:    "localhost:8181",
		listenNetwork: "tcp",
		logFormat:     "text",
	}

	require.Equal(t, expectedBoot, boot)

	expectedCfg := &config.Config{
		Backend:                  upstream.DefaultBackend,
		CableBackend:             upstream.DefaultBackend,
		Version:                  "(unknown version)",
		DocumentRoot:             "public",
		ProxyHeadersTimeout:      5 * time.Minute,
		APIQueueTimeout:          queueing.DefaultTimeout,
		APICILongPollingDuration: 50 * time.Nanosecond, // TODO this is meant to be 50*time.Second but it has been wrong for ages
		ImageResizerConfig:       config.DefaultImageResizerConfig,
	}

	require.Equal(t, expectedCfg, cfg)
}

func TestCableConfigDefault(t *testing.T) {
	backendURL, err := url.Parse("http://localhost:1234")
	require.NoError(t, err)

	args := []string{
		"-authBackend", backendURL.String(),
	}
	boot, cfg, err := buildConfig("test", args)
	require.NoError(t, err, "build config")

	expectedBoot := &bootConfig{
		secretPath:    "./.gitlab_workhorse_secret",
		listenAddr:    "localhost:8181",
		listenNetwork: "tcp",
		logFormat:     "text",
	}

	require.Equal(t, expectedBoot, boot)

	expectedCfg := &config.Config{
		Backend:                  backendURL,
		CableBackend:             backendURL,
		Version:                  "(unknown version)",
		DocumentRoot:             "public",
		ProxyHeadersTimeout:      5 * time.Minute,
		APIQueueTimeout:          queueing.DefaultTimeout,
		APICILongPollingDuration: 50 * time.Nanosecond,
		ImageResizerConfig:       config.DefaultImageResizerConfig,
	}
	require.Equal(t, expectedCfg, cfg)
}

func TestConfigFlagParsing(t *testing.T) {
	backendURL, err := url.Parse("http://localhost:1234")
	require.NoError(t, err)
	cableURL, err := url.Parse("http://localhost:5678")
	require.NoError(t, err)

	args := []string{
		"-version",
		"-secretPath", "secret path",
		"-listenAddr", "listen addr",
		"-listenNetwork", "listen network",
		"-listenUmask", "123",
		"-pprofListenAddr", "pprof listen addr",
		"-prometheusListenAddr", "prometheus listen addr",
		"-logFile", "log file",
		"-logFormat", "log format",
		"-documentRoot", "document root",
		"-developmentMode",
		"-authBackend", backendURL.String(),
		"-authSocket", "auth socket",
		"-cableBackend", cableURL.String(),
		"-cableSocket", "cable socket",
		"-proxyHeadersTimeout", "10m",
		"-apiLimit", "234",
		"-apiQueueLimit", "345",
		"-apiQueueDuration", "123s",
		"-apiCiLongPollingDuration", "234s",
		"-propagateCorrelationID",
	}
	boot, cfg, err := buildConfig("test", args)
	require.NoError(t, err, "build config")

	expectedBoot := &bootConfig{
		secretPath:           "secret path",
		listenAddr:           "listen addr",
		listenNetwork:        "listen network",
		listenUmask:          123,
		pprofListenAddr:      "pprof listen addr",
		prometheusListenAddr: "prometheus listen addr",
		logFile:              "log file",
		logFormat:            "log format",
		printVersion:         true,
	}
	require.Equal(t, expectedBoot, boot)

	expectedCfg := &config.Config{
		DocumentRoot:             "document root",
		DevelopmentMode:          true,
		Backend:                  backendURL,
		Socket:                   "auth socket",
		CableBackend:             cableURL,
		CableSocket:              "cable socket",
		Version:                  "(unknown version)",
		ProxyHeadersTimeout:      10 * time.Minute,
		APILimit:                 234,
		APIQueueLimit:            345,
		APIQueueTimeout:          123 * time.Second,
		APICILongPollingDuration: 234 * time.Second,
		PropagateCorrelationID:   true,
		ImageResizerConfig:       config.DefaultImageResizerConfig,
	}
	require.Equal(t, expectedCfg, cfg)
}
