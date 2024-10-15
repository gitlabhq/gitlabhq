package main

import (
	"bytes"
	"flag"
	"fmt"
	"io"
	"net/url"
	"os"
	"path/filepath"
	"testing"
	"time"

	"github.com/BurntSushi/toml"
	"github.com/stretchr/testify/require"

	"gitlab.com/gitlab-org/gitlab/workhorse/internal/config"
	"gitlab.com/gitlab-org/gitlab/workhorse/internal/queueing"
	"gitlab.com/gitlab-org/gitlab/workhorse/internal/testhelper"
	"gitlab.com/gitlab-org/gitlab/workhorse/internal/upstream"
)

func TestDefaultConfig(t *testing.T) {
	_, cfg, err := buildConfig("test", []string{"-config", "/dev/null"})
	require.NoError(t, err, "build config")

	require.Equal(t, 0*time.Second, cfg.ShutdownTimeout.Duration)
}

func TestConfigFile(t *testing.T) {
	f, err := os.CreateTemp("", "workhorse-config-test")
	require.NoError(t, err)
	defer os.Remove(f.Name())

	data := `
shutdown_timeout = "60s"
trusted_cidrs_for_x_forwarded_for = ["127.0.0.1/8", "192.168.0.1/8"]
trusted_cidrs_for_propagation = ["10.0.0.1/8"]

[redis]
Password = "redis password"
SentinelUsername = "sentinel-user"
SentinelPassword = "sentinel password"
[object_storage]
provider = "test provider"
[image_resizer]
max_scaler_procs = 123
[[listeners]]
network = "tcp"
addr = "localhost:3443"
[listeners.tls]
certificate = "/path/to/certificate"
key = "/path/to/private/key"
min_version = "tls1.1"
max_version = "tls1.2"
[[listeners]]
network = "tcp"
addr = "localhost:3444"
[metrics_listener]
network = "tcp"
addr = "localhost:3445"
[metrics_listener.tls]
certificate = "/path/to/certificate"
key = "/path/to/private/key"
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
	require.Equal(t, "sentinel-user", cfg.Redis.SentinelUsername)
	require.Equal(t, "sentinel password", cfg.Redis.SentinelPassword)
	require.Equal(t, "test provider", cfg.ObjectStorageCredentials.Provider)
	require.Equal(t, uint32(123), cfg.ImageResizerConfig.MaxScalerProcs, "image resizer max_scaler_procs")
	require.Equal(t, []string{"127.0.0.1/8", "192.168.0.1/8"}, cfg.TrustedCIDRsForXForwardedFor)
	require.Equal(t, []string{"10.0.0.1/8"}, cfg.TrustedCIDRsForPropagation)
	require.Equal(t, 60*time.Second, cfg.ShutdownTimeout.Duration)

	listenerConfigs := []config.ListenerConfig{
		{
			Network: "tcp",
			Addr:    "localhost:3445",
			TLS: &config.TLSConfig{
				Certificate: "/path/to/certificate",
				Key:         "/path/to/private/key",
			},
		},
		{
			Network: "tcp",
			Addr:    "localhost:3443",
			TLS: &config.TLSConfig{
				Certificate: "/path/to/certificate",
				Key:         "/path/to/private/key",
				MinVersion:  "tls1.1",
				MaxVersion:  "tls1.2",
			},
		},
		{
			Network: "tcp",
			Addr:    "localhost:3444",
		},
	}

	require.Len(t, cfg.Listeners, 2)
	require.NotNil(t, cfg.MetricsListener)

	for i, cfg := range []config.ListenerConfig{*cfg.MetricsListener, cfg.Listeners[0], cfg.Listeners[1]} {
		require.Equal(t, listenerConfigs[i].Network, cfg.Network)
		require.Equal(t, listenerConfigs[i].Addr, cfg.Addr)
	}

	for i, cfg := range []config.ListenerConfig{*cfg.MetricsListener, cfg.Listeners[0]} {
		require.Equal(t, listenerConfigs[i].TLS.Certificate, cfg.TLS.Certificate)
		require.Equal(t, listenerConfigs[i].TLS.Key, cfg.TLS.Key)
		require.Equal(t, listenerConfigs[i].TLS.MinVersion, cfg.TLS.MinVersion)
		require.Equal(t, listenerConfigs[i].TLS.MaxVersion, cfg.TLS.MaxVersion)
	}

	require.Nil(t, cfg.Listeners[1].TLS)
}

func TestTwoMetricsAddrsAreSpecifiedError(t *testing.T) {
	f, err := os.CreateTemp("", "workhorse-config-test")
	require.NoError(t, err)
	defer os.Remove(f.Name())

	data := `
[metrics_listener]
network = "tcp"
addr = "localhost:3445"
`
	_, err = io.WriteString(f, data)
	require.NoError(t, err)
	require.NoError(t, f.Close())

	args := []string{
		"-config", f.Name(),
		"-prometheusListenAddr", "prometheus listen addr",
	}
	_, _, err = buildConfig("test", args)
	require.EqualError(t, err, "configFile: both prometheusListenAddr and metrics_listener can't be specified")
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
		MetadataConfig:           config.DefaultMetadataConfig,
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
		MetadataConfig:           config.DefaultMetadataConfig,
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
		MetadataConfig:           config.DefaultMetadataConfig,
		MetricsListener:          &config.ListenerConfig{Network: "tcp", Addr: "prometheus listen addr"},
	}
	require.Equal(t, expectedCfg, cfg)
}

func TestLoadConfigCommand(t *testing.T) {
	t.Parallel()

	modifyDefaultConfig := func(modify func(cfg *config.Config)) config.Config {
		f, err := os.CreateTemp("", "workhorse-config-test")
		require.NoError(t, err)
		t.Cleanup(func() {
			defer os.Remove(f.Name())
		})

		cfg := &config.Config{}

		modify(cfg)
		return *cfg
	}

	writeScript := func(t *testing.T, script string) string {
		return testhelper.WriteExecutable(t,
			filepath.Join(testhelper.TempDir(t), "script"),
			[]byte("#!/bin/sh\n"+script),
		)
	}

	type setupData struct {
		cfg         config.Config
		expectedErr string
		expectedCfg config.Config
	}

	for _, tc := range []struct {
		desc  string
		setup func(t *testing.T) setupData
	}{
		{
			desc: "nonexistent executable",
			setup: func(_ *testing.T) setupData {
				return setupData{
					cfg: config.Config{
						ConfigCommand: "/does/not/exist",
					},
					expectedErr: "running config command: fork/exec /does/not/exist: no such file or directory",
				}
			},
		},
		{
			desc: "command points to non-executable file",
			setup: func(t *testing.T) setupData {
				cmd := filepath.Join(testhelper.TempDir(t), "script")
				require.NoError(t, os.WriteFile(cmd, nil, 0o600))

				return setupData{
					cfg: config.Config{
						ConfigCommand: cmd,
					},
					expectedErr: fmt.Sprintf(
						"running config command: fork/exec %s: permission denied", cmd,
					),
				}
			},
		},
		{
			desc: "executable returns error",
			setup: func(t *testing.T) setupData {
				return setupData{
					cfg: config.Config{
						ConfigCommand: writeScript(t, "echo error >&2 && exit 1"),
					},
					expectedErr: "running config command: exit status 1, stderr: \"error\\n\"",
				}
			},
		},
		{
			desc: "invalid JSON",
			setup: func(t *testing.T) setupData {
				return setupData{
					cfg: config.Config{
						ConfigCommand: writeScript(t, "echo 'this is not json'"),
					},
					expectedErr: "unmarshalling generated config: invalid character 'h' in literal true (expecting 'r')",
				}
			},
		},
		{
			desc: "mixed stdout and stderr",
			setup: func(t *testing.T) setupData {
				// We want to verify that we're able to correctly parse the output
				// even if the process writes to both its stdout and stderr.
				cmd := writeScript(t, "echo error >&2 && echo '{}'")

				return setupData{
					cfg: config.Config{
						ConfigCommand: cmd,
					},
					expectedCfg: modifyDefaultConfig(func(cfg *config.Config) {
						cfg.ConfigCommand = cmd
					}),
				}
			},
		},
		{
			desc: "empty script",
			setup: func(t *testing.T) setupData {
				cmd := writeScript(t, "echo '{}'")

				return setupData{
					cfg: config.Config{
						ConfigCommand: cmd,
					},
					expectedCfg: modifyDefaultConfig(func(cfg *config.Config) {
						cfg.ConfigCommand = cmd
					}),
				}
			},
		},
		{
			desc: "unknown value",
			setup: func(t *testing.T) setupData {
				cmd := writeScript(t, `echo '{"key_does_not_exist":"value"}'`)

				return setupData{
					cfg: config.Config{
						ConfigCommand: cmd,
					},
					expectedCfg: modifyDefaultConfig(func(cfg *config.Config) {
						cfg.ConfigCommand = cmd
					}),
				}
			},
		},
		{
			desc: "script taking arguments",
			setup: func(t *testing.T) setupData {
				cmd := writeScript(t, `echo "{\"shutdown_timeout\": \"$1s\"}"`)

				return setupData{
					cfg: config.Config{
						ConfigCommand: fmt.Sprintf("%s 200", cmd),
					},
					expectedCfg: modifyDefaultConfig(func(cfg *config.Config) {
						cfg.ConfigCommand = fmt.Sprintf("%s 200", cmd)
						cfg.ShutdownTimeout = config.TomlDuration{Duration: 200 * time.Second}
					}),
				}
			},
		},
		{
			desc: "generated value",
			setup: func(t *testing.T) setupData {
				cmd := writeScript(t, `echo '{"shutdown_timeout": "100s"}'`)

				return setupData{
					cfg: config.Config{
						ConfigCommand: cmd,
					},
					expectedCfg: modifyDefaultConfig(func(cfg *config.Config) {
						cfg.ConfigCommand = cmd
						cfg.ShutdownTimeout = config.TomlDuration{Duration: 100 * time.Second}
					}),
				}
			},
		},
		{
			desc: "overridden value",
			setup: func(t *testing.T) setupData {
				cmd := writeScript(t, `echo '{"shutdown_timeout": "100s"}'`)

				return setupData{
					cfg: config.Config{
						ConfigCommand:   cmd,
						ShutdownTimeout: config.TomlDuration{Duration: 1 * time.Second},
					},
					expectedCfg: modifyDefaultConfig(func(cfg *config.Config) {
						cfg.ConfigCommand = cmd
						cfg.ShutdownTimeout = config.TomlDuration{Duration: 100 * time.Second}
					}),
				}
			},
		},
		{
			desc: "mixed configuration",
			setup: func(t *testing.T) setupData {
				cmd := writeScript(t, `echo '{"redis": { "url": "redis://redis.example.com", "db": 1 } }'`)
				redisURL, err := url.Parse("redis://redis.example.com")
				require.NoError(t, err)
				db := 1

				return setupData{
					cfg: config.Config{
						ConfigCommand:      cmd,
						ImageResizerConfig: config.DefaultImageResizerConfig,
					},
					expectedCfg: modifyDefaultConfig(func(cfg *config.Config) {
						cfg.ConfigCommand = cmd
						cfg.Redis = &config.RedisConfig{
							URL: config.TomlURL{URL: *redisURL},
							DB:  &db,
						}
						cfg.ImageResizerConfig = config.DefaultImageResizerConfig
					}),
				}
			},
		},
		{
			desc: "subsections are being merged",
			setup: func(t *testing.T) setupData {
				redisURL, err := url.Parse("redis://redis.example.com")
				require.NoError(t, err)
				origDB := 1
				scriptDB := 5

				cmd := writeScript(t, `cat <<-EOF
						{
							"redis": {
								"url": "redis://redis.example.com",
								"db": 5
							}
						}
						EOF
					`)

				return setupData{
					cfg: config.Config{
						ConfigCommand: cmd,
						Redis: &config.RedisConfig{
							URL: config.TomlURL{URL: *redisURL},
							DB:  &origDB,
						},
					},
					expectedCfg: modifyDefaultConfig(func(cfg *config.Config) {
						cfg.ConfigCommand = cmd
						cfg.Redis = &config.RedisConfig{
							URL: config.TomlURL{URL: *redisURL},
							DB:  &scriptDB,
						}
					}),
				}
			},
		},
		{
			desc: "listener config",
			setup: func(t *testing.T) setupData {
				cmd := writeScript(t, `cat <<-EOF
							{
								"listeners": [
									{
										"network": "tcp",
										"addr": "127.0.0.1:3443",
										"tls": {
											"certificate": "/path/to/certificate",
											"key": "/path/to/private/key"
										}
									}
								]
							}
							EOF
						`)

				return setupData{
					cfg: config.Config{
						ConfigCommand: cmd,
					},
					expectedCfg: modifyDefaultConfig(func(cfg *config.Config) {
						cfg.ConfigCommand = cmd
						cfg.Listeners = []config.ListenerConfig{
							{
								Network: "tcp",
								Addr:    "127.0.0.1:3443",
								TLS: &config.TLSConfig{
									Certificate: "/path/to/certificate",
									Key:         "/path/to/private/key",
								},
							},
						}
					}),
				}
			},
		},
		{
			desc: "S3 object storage config",
			setup: func(t *testing.T) setupData {
				cmd := writeScript(t, `cat <<-EOF
							{
								"object_storage": {
									"provider": "AWS",
									"s3": {
										"aws_access_key_id": "MY-AWS-ACCESS-KEY",
										"aws_secret_access_key": "MY-AWS-SECRET-ACCESS-KEY"
									}
								}
							}
							EOF
						`)

				return setupData{
					cfg: config.Config{
						ConfigCommand: cmd,
					},
					expectedCfg: modifyDefaultConfig(func(cfg *config.Config) {
						cfg.ConfigCommand = cmd
						cfg.ObjectStorageCredentials = config.ObjectStorageCredentials{
							Provider: "AWS",
							S3Credentials: config.S3Credentials{
								AwsAccessKeyID:     "MY-AWS-ACCESS-KEY",
								AwsSecretAccessKey: "MY-AWS-SECRET-ACCESS-KEY",
							},
						}
					}),
				}
			},
		},
		{
			desc: "Azure object storage config",
			setup: func(t *testing.T) setupData {
				cmd := writeScript(t, `cat <<-EOF
								{
									"object_storage": {
										"provider": "AzureRM",
										"azurerm": {
											"azure_storage_account_name": "MY-STORAGE-ACCOUNT",
											"azure_storage_access_key": "MY-STORAGE-ACCESS-KEY"
										}
									}
								}
								EOF
							`)

				return setupData{
					cfg: config.Config{
						ConfigCommand: cmd,
					},
					expectedCfg: modifyDefaultConfig(func(cfg *config.Config) {
						cfg.ConfigCommand = cmd
						cfg.ObjectStorageCredentials = config.ObjectStorageCredentials{
							Provider: "AzureRM",
							AzureCredentials: config.AzureCredentials{
								AccountName: "MY-STORAGE-ACCOUNT",
								AccountKey:  "MY-STORAGE-ACCESS-KEY",
							},
						}
					}),
				}
			},
		},
		{
			desc: "Google Cloud object storage config",
			setup: func(t *testing.T) setupData {
				cmd := writeScript(t, `cat <<-EOF
								{
									"object_storage": {
										"provider": "Google",
										"google": {
											"google_application_default": true,
											"google_json_key_string": "MY-GOOGLE-JSON-KEY"
										}
									}
								}
								EOF
							`)

				return setupData{
					cfg: config.Config{
						ConfigCommand: cmd,
					},
					expectedCfg: modifyDefaultConfig(func(cfg *config.Config) {
						cfg.ConfigCommand = cmd
						cfg.ObjectStorageCredentials = config.ObjectStorageCredentials{
							Provider: "Google",
							GoogleCredentials: config.GoogleCredentials{
								ApplicationDefault: true,
								JSONKeyString:      "MY-GOOGLE-JSON-KEY",
							},
						}
					}),
				}
			},
		},
	} {
		t.Run(tc.desc, func(t *testing.T) {
			t.Parallel()

			setup := tc.setup(t)

			var cfgBuffer bytes.Buffer
			require.NoError(t, toml.NewEncoder(&cfgBuffer).Encode(setup.cfg))

			cfg, err := config.LoadConfig(cfgBuffer.String())
			// We can't use `require.Equal()` for the error as it's basically impossible
			// to reproduce the exact `exec.ExitError`.
			if setup.expectedErr != "" {
				require.EqualError(t, err, setup.expectedErr)
			} else {
				require.NoError(t, err)
				require.Equal(t, setup.expectedCfg, *cfg)
			}
		})
	}
}
