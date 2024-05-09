package staticpages

import (
	"context"
	"errors"
	"fmt"
	"net/http"
	"os"
	"path/filepath"
	"strings"
	"time"

	"gitlab.com/gitlab-org/labkit/mask"

	"gitlab.com/gitlab-org/gitlab/workhorse/internal/helper"
	"gitlab.com/gitlab-org/gitlab/workhorse/internal/log"
	"gitlab.com/gitlab-org/gitlab/workhorse/internal/urlprefix"
)

// CacheMode represents the caching mode used in the application.
type CacheMode int

const (
	// CacheDisabled represents a cache mode where caching is disabled.
	CacheDisabled CacheMode = iota
	// CacheExpireMax represents the maximum duration for cache expiration.
	CacheExpireMax
)

// ServeExisting serves static assets
// QUIRK: If a client requests 'foo%2Fbar' and 'foo/bar' exists,
// handleServeFile will serve foo/bar instead of passing the request
// upstream.
func (s *Static) ServeExisting(prefix urlprefix.Prefix, cache CacheMode, notFoundHandler http.Handler) http.Handler {
	return http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		if notFoundHandler == nil {
			notFoundHandler = http.NotFoundHandler()
		}

		// We intentionally use r.URL.Path instead of r.URL.EscaptedPath() below.
		// This is to make it possible to serve static files with e.g. a space %20 in their name.
		file, err := s.getFile(prefix, r.URL.Path)
		if err != nil {
			if errors.Is(err, errPathTraversal) {
				log.WithRequest(r).WithError(err).Error()
			}
			notFoundHandler.ServeHTTP(w, r)
			return
		}

		var content *os.File
		var fi os.FileInfo

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
			notFoundHandler.ServeHTTP(w, r)
			return
		}
		w.Header().Set("X-Content-Type-Options", "nosniff")

		defer func() {
			if err := content.Close(); err != nil {
				fmt.Printf("Error closing file: %v\n", err)
			}
		}()

		s.setCacheHeaders(w, cache)
		s.logFileServed(r.Context(), file, w.Header().Get("Content-Encoding"), r.Method, r.RequestURI)

		http.ServeContent(w, r, filepath.Base(file), fi.ModTime(), content)
	})
}

var errPathTraversal = errors.New("path traversal")

func (s *Static) getFile(prefix urlprefix.Prefix, path string) (string, error) {
	relativePath, err := s.validatePath(prefix.Strip(path))
	if err != nil {
		return "", err
	}

	file := filepath.Join(s.DocumentRoot, relativePath)
	if !strings.HasPrefix(file, s.DocumentRoot) {
		return "", errPathTraversal
	}

	return file, nil
}

func (s *Static) setCacheHeaders(w http.ResponseWriter, cache CacheMode) {
	if cache == CacheExpireMax {
		// Cache statically served files for 1 year
		cacheUntil := time.Now().AddDate(1, 0, 0).Format(http.TimeFormat)
		w.Header().Set("Cache-Control", "public")
		w.Header().Set("Expires", cacheUntil)
	}
}

func (s *Static) logFileServed(ctx context.Context, file, encoding, method, uri string) {
	log.WithContextFields(ctx, log.Fields{
		"file":     file,
		"encoding": encoding,
		"method":   method,
		"uri":      mask.URL(uri),
	}).Info("Send static file")
}

func (s *Static) validatePath(filename string) (string, error) {
	filename = filepath.Clean(filename)

	for _, exc := range s.Exclude {
		if strings.HasPrefix(filename, exc) {
			return "", fmt.Errorf("file is excluded: %s", exc)
		}
	}

	return filename, nil
}
