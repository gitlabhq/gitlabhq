package artifacts

import (
	"os"
	"testing"

	"gitlab.com/gitlab-org/labkit/log"

	"gitlab.com/gitlab-org/gitlab/workhorse/internal/testhelper"
)

func TestMain(m *testing.M) {
	if err := testhelper.BuildExecutables(); err != nil {
		log.WithError(err).Fatal()
	}

	os.Exit(m.Run())

}
