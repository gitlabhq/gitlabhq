package httprs

import (
	"fmt"
	"io"
	"net/http"
	"net/http/httptest"
	"os"
	"path/filepath"
	"testing"
	"time"

	"github.com/stretchr/testify/require"
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

func (f *fakeResponseWriter) Close(_ []byte) error {
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
	fw.tmp, err = os.CreateTemp(os.TempDir(), "httprs")
	if err != nil {
		return nil, err
	}
	if err := os.Remove(fw.tmp.Name()); err != nil {
		return nil, err
	}

	if f.downgradeZeroToNoRange {
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

type RSFactory func() *HTTPReadSeeker

func newRSFactory(flags int) RSFactory {
	return func() *HTTPReadSeeker {
		tmp, err := os.CreateTemp(os.TempDir(), "httprs")
		if err != nil {
			return nil
		}
		if os.Remove(tmp.Name()) != nil {
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
		return NewHTTPReadSeeker(res, &http.Client{Transport: &fakeRoundTripper{src: tmp, downgradeZeroToNoRange: downgradeZeroToNoRange}})
	}
}

func TestHttpWebServer(t *testing.T) {
	dir := t.TempDir()

	err := os.WriteFile(filepath.Join(dir, "file"), make([]byte, 10000), 0755)
	require.NoError(t, err)

	server := httptest.NewServer(http.FileServer(http.Dir(dir)))
	defer server.Close()

	res, err := http.Get(server.URL + "/file")
	require.NoError(t, err)
	defer res.Body.Close()

	stream := NewHTTPReadSeeker(res)
	require.NotNil(t, stream)

	t.Run("Can read 100 bytes from start of file", func(t *testing.T) {
		n, err := stream.Read(make([]byte, 100))
		require.NoError(t, err)
		require.Equal(t, 100, n)

		t.Run("When seeking 4KiB forward", func(t *testing.T) {
			pos, err := stream.Seek(4096, io.SeekCurrent)
			require.NoError(t, err)
			require.Equal(t, int64(4096+100), pos)

			t.Run("Can read 100 bytes", func(t *testing.T) {
				n, err := stream.Read(make([]byte, 100))
				require.NoError(t, err)
				require.Equal(t, 100, n)
			})
		})
	})
}

func TestHttpReaderSeeker(t *testing.T) {
	tests := []struct {
		name  string
		newRS func() *HTTPReadSeeker
	}{
		{name: "with no flags", newRS: newRSFactory(0)},
		{name: "with only Accept-Ranges", newRS: newRSFactory(sendAcceptRanges)},
		{name: "downgrade 0-range to no range", newRS: newRSFactory(downgradeZeroToNoRange)},
		{name: "downgrade 0-range with Accept-Ranges", newRS: newRSFactory(downgradeZeroToNoRange | sendAcceptRanges)},
	}

	for _, test := range tests {
		t.Run(test.name, func(t *testing.T) {
			testHTTPReaderSeeker(t, test.newRS)
		})
	}
}

func testHTTPReaderSeeker(t *testing.T, newRS RSFactory) {
	t.Run("Read should start at the beginning", func(t *testing.T) {
		r := newRS()
		require.NotNil(t, r)
		defer r.Close()

		buf := make([]byte, 4)
		n, err := io.ReadFull(r, buf)
		require.NoError(t, err)
		require.Equal(t, 4, n)
		require.Equal(t, "0000", string(buf))
	})

	t.Run("Seek w SEEK_SET should seek to right offset", func(t *testing.T) {
		r := newRS()
		require.NotNil(t, r)
		defer r.Close()

		s, err := r.Seek(4*64, io.SeekStart)
		require.NoError(t, err)
		require.Equal(t, int64(4*64), s)

		buf := make([]byte, 4)
		n, err := io.ReadFull(r, buf)
		require.NoError(t, err)
		require.Equal(t, 4, n)
		require.Equal(t, "0064", string(buf))
	})

	t.Run("Read + Seek w SEEK_CUR should seek to right offset", func(t *testing.T) {
		r := newRS()
		require.NotNil(t, r)
		defer r.Close()

		buf := make([]byte, 4)
		io.ReadFull(r, buf)

		s, err := r.Seek(4*64, io.SeekCurrent)
		require.NoError(t, err)
		require.Equal(t, int64(4*64+4), s)

		n, err := io.ReadFull(r, buf)
		require.NoError(t, err)
		require.Equal(t, 4, n)
		require.Equal(t, "0065", string(buf))
	})

	t.Run("Seek w SEEK_END should seek to right offset", func(t *testing.T) {
		r := newRS()
		require.NotNil(t, r)
		defer r.Close()

		buf := make([]byte, 4)
		io.ReadFull(r, buf)

		s, err := r.Seek(4, io.SeekEnd)
		require.NoError(t, err)
		require.Equal(t, int64(SZ*4-4), s)

		n, err := io.ReadFull(r, buf)
		require.NoError(t, err)
		require.Equal(t, 4, n)
		require.Equal(t, fmt.Sprintf("%04d", SZ-1), string(buf))
	})

	t.Run("Short seek should consume existing request", func(t *testing.T) {
		r := newRS()
		require.NotNil(t, r)
		defer r.Close()

		buf := make([]byte, 4)
		require.Equal(t, 0, r.Requests)
		io.ReadFull(r, buf)
		require.Equal(t, 1, r.Requests)

		s, err := r.Seek(shortSeekBytes, io.SeekCurrent)
		require.NoError(t, err)
		require.Equal(t, int64(shortSeekBytes+4), s)

		n, err := io.ReadFull(r, buf)
		require.NoError(t, err)
		require.Equal(t, 4, n)
		require.Equal(t, "0257", string(buf))
		require.Equal(t, 1, r.Requests)
	})

	t.Run("Long seek should do a new request", func(t *testing.T) {
		r := newRS()
		require.NotNil(t, r)
		defer r.Close()

		buf := make([]byte, 4)
		require.Equal(t, 0, r.Requests)
		io.ReadFull(r, buf)
		require.Equal(t, 1, r.Requests)

		s, err := r.Seek(shortSeekBytes+1, io.SeekCurrent)
		require.NoError(t, err)
		require.Equal(t, int64(shortSeekBytes+4+1), s)

		n, err := io.ReadFull(r, buf)
		require.NoError(t, err)
		require.Equal(t, 4, n)
		require.Equal(t, "2570", string(buf))
		require.Equal(t, 2, r.Requests)
	})
}
