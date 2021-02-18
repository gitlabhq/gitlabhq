package errortracker

import (
	"fmt"
	"net/http"
	"os"
	"runtime/debug"

	"gitlab.com/gitlab-org/labkit/errortracking"

	"gitlab.com/gitlab-org/labkit/log"
)

// NewHandler allows us to handle panics in upstreams gracefully, by logging them
// using structured logging and reporting them into Sentry as `error`s with a
// proper correlation ID attached.
func NewHandler(next http.Handler) http.Handler {
	return http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		defer func() {
			if p := recover(); p != nil {
				fields := log.ContextFields(r.Context())
				log.WithFields(fields).Error(p)
				debug.PrintStack()
				// A panic isn't always an `error`, so we may have to convert it into one.
				e, ok := p.(error)
				if !ok {
					e = fmt.Errorf("%v", p)
				}
				TrackFailedRequest(r, e, fields)
			}
		}()

		next.ServeHTTP(w, r)
	})
}

func TrackFailedRequest(r *http.Request, err error, fields log.Fields) {
	captureOpts := []errortracking.CaptureOption{
		errortracking.WithContext(r.Context()),
		errortracking.WithRequest(r),
	}
	for k, v := range fields {
		captureOpts = append(captureOpts, errortracking.WithField(k, fmt.Sprintf("%v", v)))
	}

	errortracking.Capture(err, captureOpts...)
}

func Initialize(version string) error {
	// Use a custom environment variable (not SENTRY_DSN) to prevent
	// clashes with gitlab-rails.
	sentryDSN := os.Getenv("GITLAB_WORKHORSE_SENTRY_DSN")
	sentryEnvironment := os.Getenv("GITLAB_WORKHORSE_SENTRY_ENVIRONMENT")

	return errortracking.Initialize(
		errortracking.WithSentryDSN(sentryDSN),
		errortracking.WithSentryEnvironment(sentryEnvironment),
		errortracking.WithVersion(version),
	)
}
