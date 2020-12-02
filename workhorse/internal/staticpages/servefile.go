package staticpages

import (
	"net/http"
	"os"
	"path/filepath"
	"strings"
	"time"

	"gitlab.com/gitlab-org/labkit/log"
	"gitlab.com/gitlab-org/labkit/mask"

	"gitlab.com/gitlab-org/gitlab-workhorse/internal/helper"
	"gitlab.com/gitlab-org/gitlab-workhorse/internal/urlprefix"
)

type CacheMode int

const (
	CacheDisabled CacheMode = iota
	CacheExpireMax
)

// BUG/QUIRK: If a client requests 'foo%2Fbar' and 'foo/bar' exists,
// handleServeFile will serve foo/bar instead of passing the request
// upstream.
func (s *Static) ServeExisting(prefix urlprefix.Prefix, cache CacheMode, notFoundHandler http.Handler) http.Handler {
	return http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		file := filepath.Join(s.DocumentRoot, prefix.Strip(r.URL.Path))

		// The filepath.Join does Clean traversing directories up
		if !strings.HasPrefix(file, s.DocumentRoot) {
			helper.Fail500(w, r, &os.PathError{
				Op:   "open",
				Path: file,
				Err:  os.ErrInvalid,
			})
			return
		}

		var content *os.File
		var fi os.FileInfo
		var err error

		// Serve pre-gzipped assets
		if acceptEncoding := r.Header.Get("Accept-Encoding"); strings.Contains(acceptEncoding, "gzip") {
			content, fi, err = helper.OpenFile(file + ".gz")
			if err == nil {
				w.Header().Set("Content-Encoding", "gzip")
			}
		}

		// If not found, open the original file
		if content == nil || err != nil {
			content, fi, err = helper.OpenFile(file)
		}
		if err != nil {
			if notFoundHandler != nil {
				notFoundHandler.ServeHTTP(w, r)
			} else {
				http.NotFound(w, r)
			}
			return
		}
		defer content.Close()

		switch cache {
		case CacheExpireMax:
			// Cache statically served files for 1 year
			cacheUntil := time.Now().AddDate(1, 0, 0).Format(http.TimeFormat)
			w.Header().Set("Cache-Control", "public")
			w.Header().Set("Expires", cacheUntil)
		}

		log.WithContextFields(r.Context(), log.Fields{
			"file":     file,
			"encoding": w.Header().Get("Content-Encoding"),
			"method":   r.Method,
			"uri":      mask.URL(r.RequestURI),
		}).Info("Send static file")

		http.ServeContent(w, r, filepath.Base(file), fi.ModTime(), content)
	})
}
