// Package helper provides utility functions for various tasks
package helper

import (
	"errors"
	"mime"
	"net/url"
	"os"
	"path/filepath"

	"gitlab.com/gitlab-org/gitlab/workhorse/internal/log"
)

// OpenFile opens a file at the specified path and returns its properties
func OpenFile(path string) (file *os.File, fi os.FileInfo, err error) {
	file, err = os.Open(filepath.Clean(path))
	if err != nil {
		return
	}

	defer func() {
		if err != nil {
			_ = file.Close()
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

// URLMustParse parses the given string as a URL
func URLMustParse(s string) *url.URL {
	u, err := url.Parse(s)
	if err != nil {
		log.WithError(err).WithFields(log.Fields{"url": s}).Fatal("urlMustParse")
	}
	return u
}

// IsContentType checks if the actual content type matches the expected content type
func IsContentType(expected, actual string) bool {
	parsed, _, err := mime.ParseMediaType(actual)
	return err == nil && parsed == expected
}
