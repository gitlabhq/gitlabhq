package helper

import (
	"errors"
	"mime"
	"net/url"
	"os"

	"gitlab.com/gitlab-org/gitlab/workhorse/internal/log"
)

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
