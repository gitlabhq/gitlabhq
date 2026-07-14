// Package artifacts_test provides test cases for the artifacts package.
package artifacts

import (
	"log/slog"
	"os"
	"testing"

	"gitlab.com/gitlab-org/labkit/v2/log"

	"gitlab.com/gitlab-org/gitlab/workhorse/internal/testhelper"
)

func TestMain(m *testing.M) {
	if err := testhelper.BuildExecutables(); err != nil {
		slog.Error("failed to build test executables", log.Error(err))
		os.Exit(1)
	}

	testhelper.VerifyNoGoroutines(m)
}
