package limit

import (
	"strings"
	"testing"

	"github.com/stretchr/testify/require"
)

func TestReadAt(t *testing.T) {
	t.Run("when limit has not been reached", func(t *testing.T) {
		r := strings.NewReader("some string to read")
		buf := make([]byte, 11)

		reader := NewLimitedReaderAt(r, 32, func(n int64) {
			require.Zero(t, n)
		})
		p, err := reader.ReadAt(buf, 0)

		require.NoError(t, err)
		require.Equal(t, 11, p)
		require.Equal(t, "some string", string(buf))
	})

	t.Run("when read limit is exceeded", func(t *testing.T) {
		r := strings.NewReader("some string to read")
		buf := make([]byte, 11)

		reader := NewLimitedReaderAt(r, 9, func(n int64) {
			require.Equal(t, 9, int(n))
		})
		p, err := reader.ReadAt(buf, 0)

		require.Error(t, err)
		require.Equal(t, 9, p)
		require.Equal(t, "some stri\x00\x00", string(buf))
	})

	t.Run("when offset is higher than a limit", func(t *testing.T) {
		r := strings.NewReader("some string to read")
		buf := make([]byte, 4)

		reader := NewLimitedReaderAt(r, 5, func(n int64) {
			require.Zero(t, n)
		})

		p, err := reader.ReadAt(buf, 15)

		require.NoError(t, err)
		require.Equal(t, 4, p)
		require.Equal(t, "read", string(buf))
	})

	t.Run("when a read starts at the limit", func(t *testing.T) {
		r := strings.NewReader("some string to read")
		buf := make([]byte, 11)

		reader := NewLimitedReaderAt(r, 10, func(n int64) {
			require.Equal(t, 10, int(n))
		})

		reader.ReadAt(buf, 0)
		p, err := reader.ReadAt(buf, 0)

		require.EqualError(t, err, ErrLimitExceeded.Error())
		require.Equal(t, 0, p)
		require.Equal(t, "some strin\x00", string(buf))
	})
}
