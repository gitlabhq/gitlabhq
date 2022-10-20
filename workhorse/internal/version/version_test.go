package version

import (
	"testing"

	"github.com/stretchr/testify/require"
)

func TestVersion(t *testing.T) {
	require.Equal(t, GetApplicationVersion(), "gitlab-workhorse (unknown)-(unknown)")

	SetVersion("15.3", "123.123")

	require.Equal(t, GetApplicationVersion(), "gitlab-workhorse (15.3)-(123.123)")

	SetVersion("", "123.123")

	require.Equal(t, GetApplicationVersion(), "gitlab-workhorse ()-(123.123)")
}
