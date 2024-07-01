package git

import (
	"bytes"
	"context"
	"fmt"
	"io"
	"testing"
	"testing/iotest"
	"time"

	"github.com/stretchr/testify/require"
)

type fakeReader struct {
	n   int
	err error
}

func (f *fakeReader) Read(_ []byte) (int, error) {
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

func (*fakeContextWithTimeout) Value(_ interface{}) interface{} {
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
			cr := newContextReader(tc.ctx, underlyingReader)

			n, err := cr.Read(nil)
			require.Equal(t, tc.expectedN, n)
			require.Equal(t, tc.expectedErr, err)
		})
	}
}

func TestBusyReader(t *testing.T) {
	testData := "test data"
	r := testReader(testData)
	br, _ := newWriteAfterReader(r, &bytes.Buffer{})

	result, err := io.ReadAll(br)
	if err != nil {
		t.Fatal(err)
	}

	if string(result) != testData {
		t.Fatalf("expected %q, got %q", testData, result)
	}
}

func TestFirstWriteAfterReadDone(t *testing.T) {
	writeRecorder := &bytes.Buffer{}
	br, cw := newWriteAfterReader(&bytes.Buffer{}, writeRecorder)
	if _, err := io.Copy(io.Discard, br); err != nil {
		t.Fatalf("copy from busyreader: %v", err)
	}
	testData := "test data"
	if _, err := io.Copy(cw, testReader(testData)); err != nil {
		t.Fatalf("copy test data: %v", err)
	}
	if err := cw.Flush(); err != nil {
		t.Fatalf("flush error: %v", err)
	}
	if result := writeRecorder.String(); result != testData {
		t.Fatalf("expected %q, got %q", testData, result)
	}
}

func TestWriteDelay(t *testing.T) {
	writeRecorder := &bytes.Buffer{}
	w := &complainingWriter{Writer: writeRecorder}
	br, cw := newWriteAfterReader(&bytes.Buffer{}, w)

	testData1 := "1 test"
	if _, err := io.Copy(cw, testReader(testData1)); err != nil {
		t.Fatalf("error on first copy: %v", err)
	}

	// Unblock the coupled writer by draining the reader
	if _, err := io.Copy(io.Discard, br); err != nil {
		t.Fatalf("copy from busyreader: %v", err)
	}
	// Now it is no longer an error if 'w' receives a Write()
	w.CheerUp()

	testData2 := "2 experiment"
	if _, err := io.Copy(cw, testReader(testData2)); err != nil {
		t.Fatalf("error on second copy: %v", err)
	}

	if err := cw.Flush(); err != nil {
		t.Fatalf("flush error: %v", err)
	}

	expected := testData1 + testData2
	if result := writeRecorder.String(); result != expected {
		t.Fatalf("total write: expected %q, got %q", expected, result)
	}
}

func TestComplainingWriterSanity(t *testing.T) {
	recorder := &bytes.Buffer{}
	w := &complainingWriter{Writer: recorder}

	testData := "test data"
	if _, err := io.Copy(w, testReader(testData)); err == nil {
		t.Error("error expected, none received")
	}

	w.CheerUp()
	if _, err := io.Copy(w, testReader(testData)); err != nil {
		t.Errorf("copy after CheerUp: %v", err)
	}

	if result := recorder.String(); result != testData {
		t.Errorf("expected %q, got %q", testData, result)
	}
}

func testReader(data string) io.Reader {
	return iotest.OneByteReader(bytes.NewBuffer([]byte(data)))
}

type complainingWriter struct {
	happy bool
	io.Writer
}

func (comp *complainingWriter) Write(data []byte) (int, error) {
	if comp.happy {
		return comp.Writer.Write(data)
	}

	return 0, fmt.Errorf("I am unhappy about you wanting to write %q", data)
}

func (comp *complainingWriter) CheerUp() {
	comp.happy = true
}
