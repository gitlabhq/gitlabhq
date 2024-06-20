// Package artifacts_test provides test cases for the artifacts package.
package artifacts

import (
	"testing"

	"gitlab.com/gitlab-org/labkit/log"

	"gitlab.com/gitlab-org/gitlab/workhorse/internal/testhelper"
)

func TestMain(m *testing.M) {
	if err := testhelper.BuildExecutables(); err != nil {
		log.WithError(err).Fatal()
	}

	testhelper.VerifyNoGoroutines(m)
}
