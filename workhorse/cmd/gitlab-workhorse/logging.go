package main

import (
	"errors"
	"fmt"
	"io"
	goLog "log"
	"log/slog"
	"os"

	log "github.com/sirupsen/logrus"
	logkit "gitlab.com/gitlab-org/labkit/log"
	logv2 "gitlab.com/gitlab-org/labkit/v2/log"
)

// multiCloser closes several io.Closers, joining any errors.
type multiCloser []io.Closer

func (m multiCloser) Close() error {
	var errs []error
	for _, c := range m {
		if err := c.Close(); err != nil {
			errs = append(errs, err)
		}
	}
	return errors.Join(errs...)
}

// setupLogging configures both the labkit v1 (logrus) and v2 (slog) loggers,
// installs the v2 logger as the default slog logger, and returns a closer that
// closes both log files.
func setupLogging(file, format string) (io.Closer, error) {
	// Set global labkit v1 logrus logger.
	// NOTE: To be removed after all log call sites are modified to use the
	// labkit v2 logger.
	v1Closer, err := configureLoggingV1(file, format)
	if err != nil {
		return nil, err
	}

	v2Logger, v2Closer, err := configureLoggingV2(file, format)
	if err != nil {
		_ = v1Closer.Close()
		return nil, err
	}
	slog.SetDefault(v2Logger)

	return multiCloser{v1Closer, v2Closer}, nil
}

const (
	jsonLogFormat    = "json"
	textLogFormat    = "text"
	structuredFormat = "structured"
	noneLogType      = "none"
	stderrOutput     = "stderr"
)

// Configure global Labkit v2 slog instance.
func configureLoggingV2(file string, format string) (*slog.Logger, io.Closer, error) {
	if format == noneLogType {
		// Return immediately with a discard logger to avoid overwriting
		// cfg.Writer when a log file is configured.
		cfg := logv2.Config{Writer: io.Discard}
		return logv2.NewWithConfig(&cfg), io.NopCloser(nil), nil
	}

	var cfg logv2.Config
	switch format {
	case jsonLogFormat:
		cfg.UseTextFormat = false
	case textLogFormat:
		cfg.UseTextFormat = true
	case structuredFormat:
		// "structured" is a legacy Workhorse format that mapped to logrus color output.
		// In labkit/v2/log, there is no equivalent; fall back to text with a deprecation warning.
		fmt.Fprintf(os.Stderr,
			"'%s' format is deprecated for labkit/v2/log, falling back to text\n",
			format)
		cfg.UseTextFormat = true
	default:
		return nil, nil, fmt.Errorf("unrecognized format value %q, please use json or text", format)
	}

	var (
		logger *slog.Logger
		closer io.Closer
	)

	switch file {
	case "", stderrOutput:
		// Labkit v2 writes to stderr by default
		logger = logv2.NewWithConfig(&cfg)
		closer = io.NopCloser(nil)
	case "stdout":
		cfg.Writer = os.Stdout
		logger = logv2.NewWithConfig(&cfg)
		closer = io.NopCloser(nil)
	default:
		var err error
		logger, closer, err = logv2.NewWithFile(file, &cfg)
		if err != nil {
			return nil, nil, err
		}
	}

	return logger, closer, nil
}

// Configure global labkit v1 logrus logger
// NOTE: To be removed after all log call sites are modified to use labkit v2 logger
func configureLoggingV1(file string, format string) (io.Closer, error) {
	// Golog always goes to stderr
	goLog.SetOutput(os.Stderr)

	if file == "" {
		file = stderrOutput
	}

	switch format {
	case noneLogType:
		return logkit.Initialize(logkit.WithWriter(io.Discard))
	case jsonLogFormat:
		return logkit.Initialize(
			logkit.WithOutputName(file),
			logkit.WithFormatter("json"),
		)
	case textLogFormat:
		// In this mode, default (non-access) logs will always go to stderr
		return logkit.Initialize(
			logkit.WithOutputName(stderrOutput),
			logkit.WithFormatter("text"),
		)
	case structuredFormat:
		return logkit.Initialize(
			logkit.WithOutputName(file),
			logkit.WithFormatter("color"),
		)
	}

	return nil, fmt.Errorf("unknown logFormat: %v", format)
}

// In text format, we use a separate logger for access logs
func getAccessLogger(file string, format string) (*log.Logger, io.Closer, error) {
	if format != "text" {
		return log.StandardLogger(), io.NopCloser(nil), nil
	}

	if file == "" {
		file = stderrOutput
	}

	accessLogger := log.New()
	accessLogger.SetLevel(log.InfoLevel)
	closer, err := logkit.Initialize(
		logkit.WithLogger(accessLogger),  // Configure `accessLogger`
		logkit.WithFormatter("combined"), // Use the combined formatter
		logkit.WithOutputName(file),
	)

	return accessLogger, closer, err
}
