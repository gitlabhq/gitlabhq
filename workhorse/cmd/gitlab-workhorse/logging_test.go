package main

import (
	"io"
	"os"
	"path/filepath"
	"testing"

	"github.com/sirupsen/logrus"
	"github.com/stretchr/testify/assert"
	"github.com/stretchr/testify/require"
)

func TestStartLoggingValidFormats(t *testing.T) {
	tests := []struct {
		format string
	}{
		{format: jsonLogFormat},
		{format: textLogFormat},
		{format: structuredFormat},
		{format: noneLogType},
	}

	for _, tt := range tests {
		t.Run(tt.format, func(t *testing.T) {
			closer, err := startLogging("", tt.format)
			require.NoError(t, err)
			require.NotNil(t, closer)
			defer closer.Close()
		})
	}
}

func TestStartLoggingUnknownFormat(t *testing.T) {
	closer, err := startLogging("", "unknown-format")
	require.Error(t, err)
	require.Nil(t, closer)
	require.Contains(t, err.Error(), "unknown logFormat")
}

// TestStartLoggingWithStdout verifies that "stdout" is accepted as a log file destination
// and that log output is actually written to stdout.
func TestStartLoggingWithStdout(t *testing.T) {
	logFile := "stdout"
	tests := []struct {
		format string
	}{
		{format: jsonLogFormat},
		{format: structuredFormat},
	}

	for _, tt := range tests {
		t.Run(tt.format, func(t *testing.T) {
			r, w, err := os.Pipe()
			require.NoError(t, err)
			defer r.Close()

			// Replace os.Stdout before calling startLogging
			origStdout := os.Stdout
			os.Stdout = w
			t.Cleanup(func() { os.Stdout = origStdout })

			closer, err := startLogging(logFile, tt.format)
			require.NoError(t, err)
			require.NotNil(t, closer)
			defer closer.Close()

			logrus.Info("test message for stdout")

			w.Close() // signal EOF so ReadAll returns
			output, err := io.ReadAll(r)
			require.NoError(t, err)
			assert.Contains(t, string(output), "test message for stdout")
		})
	}
}

// TestStartLoggingWithStderr verifies that "" and "stderr" are accepted as log file destinations
// and that log output is actually written to stderr.
func TestStartLoggingWithStderr(t *testing.T) {
	tests := []struct {
		name     string
		format   string
		filePath string
	}{
		{name: "json-implicit-stderr", format: jsonLogFormat, filePath: ""},
		{name: "json-explicit-stderr", format: jsonLogFormat, filePath: "stderr"},
		{name: "structured-implicit-stderr", format: structuredFormat, filePath: ""},
		{name: "structured-explicit-stderr", format: structuredFormat, filePath: "stderr"},
	}

	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			r, w, err := os.Pipe()
			require.NoError(t, err)
			defer r.Close()

			// Replace os.Stderr before calling startLogging
			origStderr := os.Stderr
			os.Stderr = w
			t.Cleanup(func() { os.Stderr = origStderr })

			closer, err := startLogging(tt.filePath, tt.format)
			require.NoError(t, err)
			require.NotNil(t, closer)
			defer closer.Close()

			logrus.Info("test message for stderr")

			w.Close() // signal EOF so ReadAll returns
			output, err := io.ReadAll(r)
			require.NoError(t, err)
			assert.Contains(t, string(output), "test message for stderr")
		})
	}
}

// TestStartLoggingNoneDiscardsOutput verifies that noneLogType discards all log output.
func TestStartLoggingNoneDiscardsOutput(t *testing.T) {
	tests := []struct {
		name                 string
		logPath              string
		assertFileNotCreated bool
	}{
		{
			name:    "discard-empty-file-path",
			logPath: "",
		},
		{
			name:    "discard-ignore-stdout",
			logPath: "stdout",
		},
		{
			name:                 "discard-ignore-logpath",
			logPath:              filepath.Join(t.TempDir(), "ignored.log"),
			assertFileNotCreated: true,
		},
	}

	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			rOut, wOut, err := os.Pipe()
			require.NoError(t, err)
			defer rOut.Close()

			rErr, wErr, err := os.Pipe()
			require.NoError(t, err)
			defer rErr.Close()

			origStdout, origStderr := os.Stdout, os.Stderr
			os.Stdout, os.Stderr = wOut, wErr
			t.Cleanup(func() {
				os.Stdout = origStdout
				os.Stderr = origStderr
			})

			closer, err := startLogging(tt.logPath, noneLogType)
			require.NoError(t, err)
			require.NotNil(t, closer)
			defer closer.Close()

			logrus.Info("test message that should be discarded")

			wOut.Close()
			wErr.Close()

			outBytes, err := io.ReadAll(rOut)
			require.NoError(t, err)
			errBytes, err := io.ReadAll(rErr)
			require.NoError(t, err)

			assert.Empty(t, outBytes)
			assert.Empty(t, errBytes)

			if tt.assertFileNotCreated {
				assert.NoFileExists(t, tt.logPath)
			}
		})
	}
}

func TestGetAccessLoggerTextFormat(t *testing.T) {
	logger, closer, err := getAccessLogger("", textLogFormat)
	require.NoError(t, err)
	require.NotNil(t, logger)
	require.NotNil(t, closer)
	defer closer.Close()

	// For text format, a new dedicated logger is returned, not the standard logger
	assert.NotSame(t, logrus.StandardLogger(), logger)
}

func TestGetAccessLoggerNonTextFormats(t *testing.T) {
	tests := []struct {
		format string
	}{
		{format: jsonLogFormat},
		{format: structuredFormat},
		{format: noneLogType},
	}

	for _, tt := range tests {
		t.Run(tt.format, func(t *testing.T) {
			logger, closer, err := getAccessLogger("", tt.format)
			require.NoError(t, err)
			require.NotNil(t, closer)
			defer closer.Close()

			// For non-text formats, the standard logger is returned unchanged
			assert.Same(t, logrus.StandardLogger(), logger)
		})
	}
}

func TestGetAccessLoggerTextFormatHasInfoLevel(t *testing.T) {
	logger, closer, err := getAccessLogger("", textLogFormat)
	require.NoError(t, err)
	defer closer.Close()

	assert.Equal(t, logrus.InfoLevel, logger.GetLevel())
}
