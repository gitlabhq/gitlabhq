package helper

import (
	"bytes"
	"errors"
	"io"
	"mime"
	"net"
	"net/http"
	"net/url"
	"os"
	"strings"

	"github.com/sebest/xff"

	"gitlab.com/gitlab-org/gitlab/workhorse/internal/log"
)

func CaptureAndFail(w http.ResponseWriter, r *http.Request, err error, msg string, code int) {
	http.Error(w, msg, code)
	printError(r, err, nil)
}

func Fail500(w http.ResponseWriter, r *http.Request, err error) {
	CaptureAndFail(w, r, err, "Internal server error", http.StatusInternalServerError)
}

func Fail500WithFields(w http.ResponseWriter, r *http.Request, err error, fields log.Fields) {
	http.Error(w, "Internal server error", http.StatusInternalServerError)
	printError(r, err, fields)
}

func RequestEntityTooLarge(w http.ResponseWriter, r *http.Request, err error) {
	CaptureAndFail(w, r, err, "Request Entity Too Large", http.StatusRequestEntityTooLarge)
}

func printError(r *http.Request, err error, fields log.Fields) {
	log.WithRequest(r).WithFields(fields).WithError(err).Error()
}

func SetNoCacheHeaders(header http.Header) {
	header.Set("Cache-Control", "no-cache, no-store, max-age=0, must-revalidate")
	header.Set("Pragma", "no-cache")
	header.Set("Expires", "Fri, 01 Jan 1990 00:00:00 GMT")
}

func OpenFile(path string) (file *os.File, fi os.FileInfo, err error) {
	file, err = os.Open(path)
	if err != nil {
		return
	}

	defer func() {
		if err != nil {
			file.Close()
		}
	}()

	fi, err = file.Stat()
	if err != nil {
		return
	}

	// The os.Open can also open directories
	if fi.IsDir() {
		err = &os.PathError{
			Op:   "open",
			Path: path,
			Err:  errors.New("path is directory"),
		}
		return
	}

	return
}

func URLMustParse(s string) *url.URL {
	u, err := url.Parse(s)
	if err != nil {
		log.WithError(err).WithFields(log.Fields{"url": s}).Fatal("urlMustParse")
	}
	return u
}

func HTTPError(w http.ResponseWriter, r *http.Request, error string, code int) {
	if r.ProtoAtLeast(1, 1) {
		// Force client to disconnect if we render request error
		w.Header().Set("Connection", "close")
	}

	http.Error(w, error, code)
}

func HeaderClone(h http.Header) http.Header {
	h2 := make(http.Header, len(h))
	for k, vv := range h {
		vv2 := make([]string, len(vv))
		copy(vv2, vv)
		h2[k] = vv2
	}
	return h2
}

func FixRemoteAddr(r *http.Request) {
	// Unix domain sockets have a remote addr of @. This will make the
	// xff package lookup the X-Forwarded-For address if available.
	if r.RemoteAddr == "@" {
		r.RemoteAddr = "127.0.0.1:0"
	}
	r.RemoteAddr = xff.GetRemoteAddr(r)
}

func SetForwardedFor(newHeaders *http.Header, originalRequest *http.Request) {
	if clientIP, _, err := net.SplitHostPort(originalRequest.RemoteAddr); err == nil {
		var header string

		// If we aren't the first proxy retain prior
		// X-Forwarded-For information as a comma+space
		// separated list and fold multiple headers into one.
		if prior, ok := originalRequest.Header["X-Forwarded-For"]; ok {
			header = strings.Join(prior, ", ") + ", " + clientIP
		} else {
			header = clientIP
		}
		newHeaders.Set("X-Forwarded-For", header)
	}
}

func IsContentType(expected, actual string) bool {
	parsed, _, err := mime.ParseMediaType(actual)
	return err == nil && parsed == expected
}

func IsApplicationJson(r *http.Request) bool {
	contentType := r.Header.Get("Content-Type")
	return IsContentType("application/json", contentType)
}

func ReadRequestBody(w http.ResponseWriter, r *http.Request, maxBodySize int64) ([]byte, error) {
	limitedBody := http.MaxBytesReader(w, r.Body, maxBodySize)
	defer limitedBody.Close()

	return io.ReadAll(limitedBody)
}

func CloneRequestWithNewBody(r *http.Request, body []byte) *http.Request {
	newReq := *r
	newReq.Body = io.NopCloser(bytes.NewReader(body))
	newReq.Header = HeaderClone(r.Header)
	newReq.ContentLength = int64(len(body))
	return &newReq
}
