package helper

import (
	"bytes"
	"fmt"
	"io"
	"io/ioutil"
	"testing"
	"testing/iotest"
)

func TestBusyReader(t *testing.T) {
	testData := "test data"
	r := testReader(testData)
	br, _ := NewWriteAfterReader(r, &bytes.Buffer{})

	result, err := ioutil.ReadAll(br)
	if err != nil {
		t.Fatal(err)
	}

	if string(result) != testData {
		t.Fatalf("expected %q, got %q", testData, result)
	}
}

func TestFirstWriteAfterReadDone(t *testing.T) {
	writeRecorder := &bytes.Buffer{}
	br, cw := NewWriteAfterReader(&bytes.Buffer{}, writeRecorder)
	if _, err := io.Copy(ioutil.Discard, br); err != nil {
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
	br, cw := NewWriteAfterReader(&bytes.Buffer{}, w)

	testData1 := "1 test"
	if _, err := io.Copy(cw, testReader(testData1)); err != nil {
		t.Fatalf("error on first copy: %v", err)
	}

	// Unblock the coupled writer by draining the reader
	if _, err := io.Copy(ioutil.Discard, br); err != nil {
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
