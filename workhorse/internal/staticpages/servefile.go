package staticpages

import (
	"context"
	"errors"
	"fmt"
	"net/http"
	"os"
	"path/filepath"
	"slices"
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

// AssetAuthorizationResult represents the result of asset authorization check.
type AssetAuthorizationResult struct {
	Allowed              bool
	AuthorizationHeaders map[string][]string
}

// HTTP methods allowed for asset authorization checks.
var assetAuthorizationAllowedRequestMethods = []string{"OPTIONS", "GET", "HEAD"}

// Headers that can be copied from the upstream authorization API response.
var assetAuthorizationUpstreamResponseForwardedHeaders = []string{
	"Access-Control-Allow-Origin",
	"Access-Control-Allow-Methods",
	"Access-Control-Allow-Headers",
	"Access-Control-Allow-Credentials",
	"Cross-Origin-Opener-Policy",
	"Content-Security-Policy",
	"Cross-Origin-Resource-Policy",
	"Vary",
}

// Allowed asset authorization result with empty headers
var allowedAssetAuthorizationResult = AssetAuthorizationResult{
	Allowed:              true,
	AuthorizationHeaders: make(map[string][]string),
}

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

		authResult := s.resolveAssetAuthorization(r)

		if !authResult.Allowed {
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
				log.WithError(err).Error("Could not close static file")
			}
		}()

		s.setAuthorizationHeaders(w, authResult)
		s.setCacheHeaders(w, cache)
		s.logFileServed(r.Context(), file, w.Header().Get("Content-Encoding"), r.Method, r.RequestURI)

		http.ServeContent(w, r, filepath.Base(file), fi.ModTime(), content)
	})
}

// setAuthorizationHeaders sets authorization headers from the auth result
func (s *Static) setAuthorizationHeaders(w http.ResponseWriter, authResult AssetAuthorizationResult) {
	for k, v := range authResult.AuthorizationHeaders {
		w.Header()[k] = v
	}
}

var errPathTraversal = errors.New("path traversal")

// resolveAssetAuthorization checks authorization for specific static assets and retrieves
// CORS-related headers from the upstream API.
//
// This function handles authorization for two specific asset paths:
//   - /assets/webpack/gitlab-web-ide-vscode-workbench-<version>/*
//   - /assets/gitlab-mono/*
//
// For these paths, it performs a CORS preflight check by sending an OPTIONS request to the
// upstream API via PreAuthorize. If the request is unauthorized (HTTP 401), access is denied.
// Otherwise, allowed CORS headers (access-control-*, cross-origin-*, content-security-policy, vary)
// are extracted from the API response and returned.
//
// For all other asset paths or non-GET/HEAD/OPTIONS requests, authorization is implicitly allowed
// with no additional headers.
//
// Parameters:
//   - r: The incoming HTTP request
//
// Returns:
//   - AssetAuthorizationResult containing:
//   - Allowed: true if the asset can be served, false if unauthorized
//   - AuthorizationHeaders: map of CORS and security headers from the API response
func (s *Static) resolveAssetAuthorization(r *http.Request) AssetAuthorizationResult {
	isTargetAssetsPath := strings.HasPrefix(r.URL.Path, "/assets/webpack/gitlab-web-ide-vscode-workbench") ||
		strings.HasPrefix(r.URL.Path, "/assets/gitlab-mono")

	if !isTargetAssetsPath || !slices.Contains(assetAuthorizationAllowedRequestMethods, r.Method) {
		return allowedAssetAuthorizationResult
	}

	preflightRequest := &http.Request{Method: "OPTIONS", URL: r.URL, Header: r.Header.Clone()}
	preflightRequest.Host = r.Host
	httpResponse, _, err := s.API.PreAuthorize(r.RequestURI, preflightRequest)

	if err != nil {
		log.WithContextFields(r.Context(), log.Fields{
			"uri": mask.URL(r.RequestURI),
		}).Error("Could not resolve CORS headers for static asset")
		return allowedAssetAuthorizationResult
	}

	defer func() {
		if err := httpResponse.Body.Close(); err != nil {
			log.WithContextFields(r.Context(), log.Fields{
				"uri": mask.URL(r.RequestURI),
			}).WithError(err).Error("Error closing asset authorization API response")
		}
	}()

	if httpResponse.StatusCode == http.StatusUnauthorized {
		return AssetAuthorizationResult{
			Allowed:              false,
			AuthorizationHeaders: make(map[string][]string),
		}
	}

	headers := make(map[string][]string)

	for _, headerKey := range assetAuthorizationUpstreamResponseForwardedHeaders {
		if headerValue, ok := httpResponse.Header[headerKey]; ok {
			headers[headerKey] = headerValue
		}
	}

	return AssetAuthorizationResult{
		Allowed:              true,
		AuthorizationHeaders: headers,
	}
}

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
