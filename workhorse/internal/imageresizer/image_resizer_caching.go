// This file contains code derived from https://github.com/golang/go/blob/master/src/net/http/fs.go
//
// Copyright 2020 GitLab Inc. All rights reserved.
// Copyright 2009 The Go Authors. All rights reserved.

package imageresizer

import (
	"net/http"
	"time"
)

func checkNotModified(r *http.Request, modtime time.Time) bool {
	ims := r.Header.Get("If-Modified-Since")
	if ims == "" || isZeroTime(modtime) {
		// Treat bogus times as if there was no such header at all
		return false
	}
	t, err := http.ParseTime(ims)
	if err != nil {
		return false
	}
	// The Last-Modified header truncates sub-second precision so
	// the modtime needs to be truncated too.
	return !modtime.Truncate(time.Second).After(t)
}

// isZeroTime reports whether t is obviously unspecified (either zero or Unix epoch time).
func isZeroTime(t time.Time) bool {
	return t.IsZero() || t.Equal(time.Unix(0, 0))
}

func setLastModified(w http.ResponseWriter, modtime time.Time) {
	if !isZeroTime(modtime) {
		w.Header().Set("Last-Modified", modtime.UTC().Format(http.TimeFormat))
	}
}

func writeNotModified(w http.ResponseWriter) {
	h := w.Header()
	h.Del("Content-Type")
	h.Del("Content-Length")
	w.WriteHeader(http.StatusNotModified)
}
