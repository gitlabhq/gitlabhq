package main

import (
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
