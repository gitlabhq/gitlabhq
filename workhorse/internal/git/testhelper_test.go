package git

import (
	"os"
	"testing"

	"github.com/sirupsen/logrus"

	"gitlab.com/gitlab-org/gitlab/workhorse/internal/gitaly"
)

func TestMain(m *testing.M) {
	gitaly.InitializeSidechannelRegistry(logrus.StandardLogger())
	os.Exit(m.Run())
}
