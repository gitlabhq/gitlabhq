package destination

import (
	"fmt"
	"io"
	"strings"
	"testing"
	"testing/iotest"

	"github.com/stretchr/testify/require"
)

func TestHardLimitReader(t *testing.T) {
	const text = "hello world"
	r := iotest.OneByteReader(
		&hardLimitReader{
			r: strings.NewReader(text),
			n: int64(len(text)),
		},
	)

	out, err := io.ReadAll(r)
	require.NoError(t, err)
	require.Equal(t, text, string(out))
}

func TestHardLimitReaderFail(t *testing.T) {
	const text = "hello world"

	for bufSize := len(text) / 2; bufSize < len(text)*2; bufSize++ {
		t.Run(fmt.Sprintf("bufsize:%d", bufSize), func(t *testing.T) {
			r := &hardLimitReader{
				r: iotest.DataErrReader(strings.NewReader(text)),
				n: int64(len(text)) - 1,
			}
			buf := make([]byte, bufSize)

			var err error
			for i := 0; err == nil && i < 1000; i++ {
				_, err = r.Read(buf)
			}

			require.Equal(t, ErrEntityTooLarge, err)
		})
	}
}
