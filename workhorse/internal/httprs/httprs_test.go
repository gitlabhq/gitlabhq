package httprs

import (
	"fmt"
	"io"
	"io/ioutil"
	"net/http"
	"net/http/httptest"
	"os"
	"path/filepath"
	"testing"
	"time"

	. "github.com/smartystreets/goconvey/convey"
)

type fakeResponseWriter struct {
	code int
	h    http.Header
	tmp  *os.File
}

func (f *fakeResponseWriter) Header() http.Header {
	return f.h
}

func (f *fakeResponseWriter) Write(b []byte) (int, error) {
	return f.tmp.Write(b)
}

func (f *fakeResponseWriter) Close(b []byte) error {
	return f.tmp.Close()
}

func (f *fakeResponseWriter) WriteHeader(code int) {
	f.code = code
}

func (f *fakeResponseWriter) Response() *http.Response {
	f.tmp.Seek(0, io.SeekStart)
	return &http.Response{Body: f.tmp, StatusCode: f.code, Header: f.h}
}

type fakeRoundTripper struct {
	src                    *os.File
	downgradeZeroToNoRange bool
}

func (f *fakeRoundTripper) RoundTrip(r *http.Request) (*http.Response, error) {
	fw := &fakeResponseWriter{h: http.Header{}}
	var err error
	fw.tmp, err = ioutil.TempFile(os.TempDir(), "httprs")
	if err != nil {
		return nil, err
	}
	if err := os.Remove(fw.tmp.Name()); err != nil {
		return nil, err
	}

	if f.downgradeZeroToNoRange {
		// There are implementations that downgrades bytes=0- to a normal un-ranged GET
		if r.Header.Get("Range") == "bytes=0-" {
			r.Header.Del("Range")
		}
	}
	http.ServeContent(fw, r, "temp.txt", time.Now(), f.src)

	return fw.Response(), nil
}

const SZ = 4096

const (
	downgradeZeroToNoRange = 1 << iota
	sendAcceptRanges
)

type RSFactory func() *HttpReadSeeker

func newRSFactory(flags int) RSFactory {
	return func() *HttpReadSeeker {
		tmp, err := ioutil.TempFile(os.TempDir(), "httprs")
		if err != nil {
			return nil
		}
		if err := os.Remove(tmp.Name()); err != nil {
			return nil
		}

		for i := 0; i < SZ; i++ {
			tmp.WriteString(fmt.Sprintf("%04d", i))
		}

		req, err := http.NewRequest("GET", "http://www.example.com", nil)
		if err != nil {
			return nil
		}
		res := &http.Response{
			Request:       req,
			ContentLength: SZ * 4,
		}

		if flags&sendAcceptRanges > 0 {
			res.Header = http.Header{"Accept-Ranges": []string{"bytes"}}
		}

		downgradeZeroToNoRange := (flags & downgradeZeroToNoRange) > 0
		return NewHttpReadSeeker(res, &http.Client{Transport: &fakeRoundTripper{src: tmp, downgradeZeroToNoRange: downgradeZeroToNoRange}})
	}
}

func TestHttpWebServer(t *testing.T) {
	Convey("Scenario: testing WebServer", t, func() {
		dir, err := ioutil.TempDir("", "webserver")
		So(err, ShouldBeNil)
		defer os.RemoveAll(dir)

		err = ioutil.WriteFile(filepath.Join(dir, "file"), make([]byte, 10000), 0755)
		So(err, ShouldBeNil)

		server := httptest.NewServer(http.FileServer(http.Dir(dir)))

		Convey("When requesting /file", func() {
			res, err := http.Get(server.URL + "/file")
			So(err, ShouldBeNil)

			stream := NewHttpReadSeeker(res)
			So(stream, ShouldNotBeNil)

			Convey("Can read 100 bytes from start of file", func() {
				n, err := stream.Read(make([]byte, 100))
				So(err, ShouldBeNil)
				So(n, ShouldEqual, 100)

				Convey("When seeking 4KiB forward", func() {
					pos, err := stream.Seek(4096, io.SeekCurrent)
					So(err, ShouldBeNil)
					So(pos, ShouldEqual, 4096+100)

					Convey("Can read 100 bytes", func() {
						n, err := stream.Read(make([]byte, 100))
						So(err, ShouldBeNil)
						So(n, ShouldEqual, 100)
					})
				})
			})
		})
	})
}

func TestHttpReaderSeeker(t *testing.T) {
	tests := []struct {
		name  string
		newRS func() *HttpReadSeeker
	}{
		{name: "with no flags", newRS: newRSFactory(0)},
		{name: "with only Accept-Ranges", newRS: newRSFactory(sendAcceptRanges)},
		{name: "downgrade 0-range to no range", newRS: newRSFactory(downgradeZeroToNoRange)},
		{name: "downgrade 0-range with Accept-Ranges", newRS: newRSFactory(downgradeZeroToNoRange | sendAcceptRanges)},
	}

	for _, test := range tests {
		t.Run(test.name, func(t *testing.T) {
			testHttpReaderSeeker(t, test.newRS)
		})
	}
}

func testHttpReaderSeeker(t *testing.T, newRS RSFactory) {
	Convey("Scenario: testing HttpReaderSeeker", t, func() {

		Convey("Read should start at the beginning", func() {
			r := newRS()
			So(r, ShouldNotBeNil)
			defer r.Close()
			buf := make([]byte, 4)
			n, err := io.ReadFull(r, buf)
			So(n, ShouldEqual, 4)
			So(err, ShouldBeNil)
			So(string(buf), ShouldEqual, "0000")
		})

		Convey("Seek w SEEK_SET should seek to right offset", func() {
			r := newRS()
			So(r, ShouldNotBeNil)
			defer r.Close()
			s, err := r.Seek(4*64, io.SeekStart)
			So(s, ShouldEqual, 4*64)
			So(err, ShouldBeNil)
			buf := make([]byte, 4)
			n, err := io.ReadFull(r, buf)
			So(n, ShouldEqual, 4)
			So(err, ShouldBeNil)
			So(string(buf), ShouldEqual, "0064")
		})

		Convey("Read + Seek w SEEK_CUR should seek to right offset", func() {
			r := newRS()
			So(r, ShouldNotBeNil)
			defer r.Close()
			buf := make([]byte, 4)
			io.ReadFull(r, buf)
			s, err := r.Seek(4*64, os.SEEK_CUR)
			So(s, ShouldEqual, 4*64+4)
			So(err, ShouldBeNil)
			n, err := io.ReadFull(r, buf)
			So(n, ShouldEqual, 4)
			So(err, ShouldBeNil)
			So(string(buf), ShouldEqual, "0065")
		})

		Convey("Seek w SEEK_END should seek to right offset", func() {
			r := newRS()
			So(r, ShouldNotBeNil)
			defer r.Close()
			buf := make([]byte, 4)
			io.ReadFull(r, buf)
			s, err := r.Seek(4, os.SEEK_END)
			So(s, ShouldEqual, SZ*4-4)
			So(err, ShouldBeNil)
			n, err := io.ReadFull(r, buf)
			So(n, ShouldEqual, 4)
			So(err, ShouldBeNil)
			So(string(buf), ShouldEqual, fmt.Sprintf("%04d", SZ-1))
		})

		Convey("Short seek should consume existing request", func() {
			r := newRS()
			So(r, ShouldNotBeNil)
			defer r.Close()
			buf := make([]byte, 4)
			So(r.Requests, ShouldEqual, 0)
			io.ReadFull(r, buf)
			So(r.Requests, ShouldEqual, 1)
			s, err := r.Seek(shortSeekBytes, os.SEEK_CUR)
			So(r.Requests, ShouldEqual, 1)
			So(s, ShouldEqual, shortSeekBytes+4)
			So(err, ShouldBeNil)
			n, err := io.ReadFull(r, buf)
			So(n, ShouldEqual, 4)
			So(err, ShouldBeNil)
			So(string(buf), ShouldEqual, "0257")
			So(r.Requests, ShouldEqual, 1)
		})

		Convey("Long seek should do a new request", func() {
			r := newRS()
			So(r, ShouldNotBeNil)
			defer r.Close()
			buf := make([]byte, 4)
			So(r.Requests, ShouldEqual, 0)
			io.ReadFull(r, buf)
			So(r.Requests, ShouldEqual, 1)
			s, err := r.Seek(shortSeekBytes+1, os.SEEK_CUR)
			So(r.Requests, ShouldEqual, 1)
			So(s, ShouldEqual, shortSeekBytes+4+1)
			So(err, ShouldBeNil)
			n, err := io.ReadFull(r, buf)
			So(n, ShouldEqual, 4)
			So(err, ShouldBeNil)
			So(string(buf), ShouldEqual, "2570")
			So(r.Requests, ShouldEqual, 2)
		})
	})
}
