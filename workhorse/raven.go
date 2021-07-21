package main

import (
	"net/http"
	"os"

	raven "github.com/getsentry/raven-go"

	"gitlab.com/gitlab-org/gitlab/workhorse/internal/helper"
)

func wrapRaven(h http.Handler) http.Handler {
	// Use a custom environment variable (not SENTRY_DSN) to prevent
	// clashes with gitlab-rails.
	sentryDSN := os.Getenv("GITLAB_WORKHORSE_SENTRY_DSN")
	sentryEnvironment := os.Getenv("GITLAB_WORKHORSE_SENTRY_ENVIRONMENT")
	raven.SetDSN(sentryDSN) // sentryDSN may be empty

	if sentryEnvironment != "" {
		raven.SetEnvironment(sentryEnvironment)
	}

	if sentryDSN == "" {
		return h
	}

	raven.DefaultClient.SetRelease(Version)

	return http.HandlerFunc(raven.RecoveryHandler(
		func(w http.ResponseWriter, r *http.Request) {
			defer func() {
				if p := recover(); p != nil {
					helper.CleanHeadersForRaven(r)
					panic(p)
				}
			}()

			h.ServeHTTP(w, r)
		}))
}
