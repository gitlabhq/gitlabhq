package version

import (
	"testing"

	"github.com/stretchr/testify/require"
)

func TestVersion(t *testing.T) {
	require.Equal(t, "gitlab-workhorse (unknown)-(unknown)", GetApplicationVersion())

	SetVersion("15.3", "123.123")

	require.Equal(t, "gitlab-workhorse (15.3)-(123.123)", GetApplicationVersion())

	SetVersion("", "123.123")

	require.Equal(t, "gitlab-workhorse ()-(123.123)", GetApplicationVersion())
}
