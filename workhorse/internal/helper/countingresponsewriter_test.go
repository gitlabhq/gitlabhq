package helper

import (
	"bytes"
	"io"
	"net/http"
	"net/http/httptest"
	"testing"
	"testing/iotest"

	"github.com/stretchr/testify/require"
)

type testResponseWriter struct {
	data []byte
}

func (*testResponseWriter) WriteHeader(int)     {}
func (*testResponseWriter) Header() http.Header { return nil }

func (trw *testResponseWriter) Write(p []byte) (int, error) {
	trw.data = append(trw.data, p...)
	return len(p), nil
}

func TestCountingResponseWriterStatus(t *testing.T) {
	crw := NewCountingResponseWriter(&testResponseWriter{})
	crw.WriteHeader(123)
	crw.WriteHeader(456)
	require.Equal(t, 123, crw.Status())
}

func TestCountingResponseWriterCount(t *testing.T) {
	crw := NewCountingResponseWriter(&testResponseWriter{})
	for _, n := range []int{1, 2, 4, 8, 16, 32} {
		_, err := crw.Write(bytes.Repeat([]byte{'.'}, n))
		require.NoError(t, err)
	}
	require.Equal(t, int64(63), crw.Count())
}

func TestCountingResponseWriterWrite(t *testing.T) {
	trw := &testResponseWriter{}
	crw := NewCountingResponseWriter(trw)

	testData := []byte("test data")
	_, err := io.Copy(crw, iotest.OneByteReader(bytes.NewReader(testData)))
	require.NoError(t, err)

	require.Equal(t, string(testData), string(trw.data))
}

func TestCountingResponseWriterFlushable(t *testing.T) {
	rw := httptest.NewRecorder()

	crw := countingResponseWriter{rw: rw}
	rc := http.NewResponseController(&crw) //nolint:bodyclose // false-positive https://github.com/timakin/bodyclose/issues/52

	err := rc.Flush()
	require.NoError(t, err, "the underlying response writer is not flushable")
	require.True(t, rw.Flushed)
}
