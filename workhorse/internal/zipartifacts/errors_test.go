package zipartifacts

import (
	"errors"
	"testing"

	"github.com/stretchr/testify/require"
)

func TestExitCodeByError(t *testing.T) {
	t.Run("when error has been recognized", func(t *testing.T) {
		code := ExitCodeByError(ErrorCode[CodeLimitsReached])

		require.Equal(t, CodeLimitsReached, code)
		require.Greater(t, code, 10)
	})

	t.Run("when error is an unknown one", func(t *testing.T) {
		code := ExitCodeByError(errors.New("unknown error"))

		require.Equal(t, CodeUnknownError, code)
		require.Greater(t, code, 10)
	})
}

func TestErrorLabels(t *testing.T) {
	for code := range ErrorCode {
		_, ok := ErrorLabel[code]

		require.True(t, ok)
	}
}
