package helper

import (
	"errors"
	"mime"
	"net/http"
	"net/url"
	"os"

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

func IsContentType(expected, actual string) bool {
	parsed, _, err := mime.ParseMediaType(actual)
	return err == nil && parsed == expected
}
