package main

import (
	"fmt"
	"io"
	goLog "log"
	"os"

	log "github.com/sirupsen/logrus"
	logkit "gitlab.com/gitlab-org/labkit/log"
)

const (
	jsonLogFormat    = "json"
	textLogFormat    = "text"
	structuredFormat = "structured"
	noneLogType      = "none"
)

func startLogging(file string, format string) (io.Closer, error) {
	// Golog always goes to stderr
	goLog.SetOutput(os.Stderr)

	if file == "" {
		file = "stderr"
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
			logkit.WithOutputName("stderr"),
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
		file = "stderr"
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
