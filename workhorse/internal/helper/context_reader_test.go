package helper

import (
	"context"
	"io"
	"testing"
	"time"

	"github.com/stretchr/testify/require"
)

type fakeReader struct {
	n   int
	err error
}

func (f *fakeReader) Read(b []byte) (int, error) {
	return f.n, f.err
}

type fakeContextWithTimeout struct {
	n         int
	threshold int
}

func (*fakeContextWithTimeout) Deadline() (deadline time.Time, ok bool) {
	return
}

func (*fakeContextWithTimeout) Done() <-chan struct{} {
	return nil
}

func (*fakeContextWithTimeout) Value(key interface{}) interface{} {
	return nil
}

func (f *fakeContextWithTimeout) Err() error {
	f.n++
	if f.n > f.threshold {
		return context.DeadlineExceeded
	}

	return nil
}

func TestContextReaderRead(t *testing.T) {
	underlyingReader := &fakeReader{n: 1, err: io.EOF}

	for _, tc := range []struct {
		desc        string
		ctx         *fakeContextWithTimeout
		expectedN   int
		expectedErr error
	}{
		{
			desc:        "Before and after read deadline checks are fine",
			ctx:         &fakeContextWithTimeout{n: 0, threshold: 2},
			expectedN:   underlyingReader.n,
			expectedErr: underlyingReader.err,
		},
		{
			desc:        "Before read deadline check fails",
			ctx:         &fakeContextWithTimeout{n: 0, threshold: 0},
			expectedN:   0,
			expectedErr: context.DeadlineExceeded,
		},
		{
			desc:        "After read deadline check fails",
			ctx:         &fakeContextWithTimeout{n: 0, threshold: 1},
			expectedN:   underlyingReader.n,
			expectedErr: context.DeadlineExceeded,
		},
	} {
		t.Run(tc.desc, func(t *testing.T) {
			cr := NewContextReader(tc.ctx, underlyingReader)

			n, err := cr.Read(nil)
			require.Equal(t, tc.expectedN, n)
			require.Equal(t, tc.expectedErr, err)
		})
	}
}
