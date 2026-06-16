package main

import (
	"bytes"
	"io"
	"os"
	"path/filepath"
	"testing"

	"github.com/sirupsen/logrus"
	"github.com/stretchr/testify/assert"
	"github.com/stretchr/testify/require"
)

func TestConfigureLoggingV2ValidFormats(t *testing.T) {
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
			logger, closer, err := configureLoggingV2("", tt.format)
			require.NoError(t, err)
			require.NotNil(t, logger)
			require.NotNil(t, closer)
			defer closer.Close()
		})
	}
}

// Workhorse has historically been configured to treat "stdout" as a
// stream name, not a file path.
func TestConfigureLoggingV2StdoutFile(t *testing.T) {
	r, w, err := os.Pipe()
	require.NoError(t, err)

	origStdout := os.Stdout
	os.Stdout = w
	t.Cleanup(func() { os.Stdout = origStdout })

	logger, closer, err := configureLoggingV2("stdout", jsonLogFormat)
	require.NoError(t, err)
	require.NotNil(t, logger)
	require.NotNil(t, closer)
	defer closer.Close()

	logger.Info("hello stdout")

	w.Close()
	var buf bytes.Buffer
	_, _ = io.Copy(&buf, r)

	assert.Contains(t, buf.String(), "hello stdout")
}

func TestConfigureLoggingV2NoneFormatIgnoresFile(t *testing.T) {
	// When format is "none", the discard writer must be used regardless of the file argument.
	tmpFile := t.TempDir() + "/test.log"
	logger, closer, err := configureLoggingV2(tmpFile, noneLogType)
	require.NoError(t, err)
	require.NotNil(t, logger)
	require.NotNil(t, closer)
	defer closer.Close()

	logger.Info("this message should be discarded")

	_, statErr := os.Stat(tmpFile)
	require.True(t, os.IsNotExist(statErr), "log file must not be created when format is none")
}

func TestConfigureLoggingV2UnknownFormat(t *testing.T) {
	logger, closer, err := configureLoggingV2("", "unknown-format")
	require.Error(t, err)
	require.Nil(t, logger)
	require.Nil(t, closer)
	require.Contains(t, err.Error(), "unrecognized format value")
}

func TestConfigureLoggingV1ValidFormats(t *testing.T) {
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
			closer, err := configureLoggingV1("", tt.format)
			require.NoError(t, err)
			require.NotNil(t, closer)
			defer closer.Close()
		})
	}
}

func TestConfigureLoggingV1UnknownFormat(t *testing.T) {
	closer, err := configureLoggingV1("", "unknown-format")
	require.Error(t, err)
	require.Nil(t, closer)
	require.Contains(t, err.Error(), "unknown logFormat")
}

// TestConfigureLoggingV1WithStdout verifies that "stdout" is accepted as a log file destination
// and that log output is actually written to stdout.
func TestConfigureLoggingV1WithStdout(t *testing.T) {
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

			// Replace os.Stdout before calling configureLoggingV1
			origStdout := os.Stdout
			os.Stdout = w
			t.Cleanup(func() { os.Stdout = origStdout })

			closer, err := configureLoggingV1(logFile, tt.format)
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
func TestConfigureLoggingV1WithStderr(t *testing.T) {
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

			// Replace os.Stderr before calling configureLoggingV1
			origStderr := os.Stderr
			os.Stderr = w
			t.Cleanup(func() { os.Stderr = origStderr })

			closer, err := configureLoggingV1(tt.filePath, tt.format)
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
func TestConfigureLoggingV1NoneDiscardsOutput(t *testing.T) {
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

			closer, err := configureLoggingV1(tt.logPath, noneLogType)
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
