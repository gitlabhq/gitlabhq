/*
Package upload provides middleware for handling file uploads in GitLab Workhorse.

It includes functionality for processing multipart requests, authorizing uploads,
and preparing file uploads before they are saved.
*/
package upload

import (
	"net/http"

	"gitlab.com/gitlab-org/gitlab/workhorse/internal/api"
	"gitlab.com/gitlab-org/gitlab/workhorse/internal/config"
)

// Multipart is a request middleware. If the request has a MIME multipart
// request body, the middleware will iterate through the multipart parts.
// When it finds a file part (filename != ""), the middleware will save
// the file contents to a temporary location and replace the file part
// with a reference to the temporary location.
func Multipart(rails PreAuthorizer, h http.Handler, p Preparer, cfg *config.Config) http.Handler {
	return rails.PreAuthorizeHandler(func(w http.ResponseWriter, r *http.Request, a *api.Response) {
		s := &SavedFileTracker{Request: r}

		interceptMultipartFiles(w, r, h, s, &eagerAuthorizer{a}, p, cfg)
	}, "/authorize")
}

// FixedPreAuthMultipart behaves like Multipart except it makes lazy
// preauthorization requests when it encounters a multipart upload. The
// preauthorization requests go to a fixed internal GitLab Rails API
// endpoint. This endpoint currently does not support direct upload, so
// using FixedPreAuthMultipart implies disk buffering.
func FixedPreAuthMultipart(myAPI *api.API, h http.Handler, p Preparer, cfg *config.Config) http.Handler {
	return http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		s := &SavedFileTracker{Request: r}
		fa := &apiAuthorizer{myAPI}
		interceptMultipartFiles(w, r, h, s, fa, p, cfg)
	})
}
