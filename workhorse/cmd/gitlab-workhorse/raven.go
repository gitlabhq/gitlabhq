package main

import (
	"errors"
	"fmt"
	"net/http"
	"os"
	"runtime/debug"

	"github.com/getsentry/raven-go"

	"gitlab.com/gitlab-org/gitlab/workhorse/internal/helper/exception"
	"gitlab.com/gitlab-org/gitlab/workhorse/internal/log"
)

func wrapRaven(h http.Handler) http.Handler {
	// Use a custom environment variable (not SENTRY_DSN) to prevent
	// clashes with gitlab-rails.
	sentryDSN := os.Getenv("GITLAB_WORKHORSE_SENTRY_DSN")
	sentryEnvironment := os.Getenv("GITLAB_WORKHORSE_SENTRY_ENVIRONMENT")
	_ = raven.SetDSN(sentryDSN) // sentryDSN may be empty

	if sentryEnvironment != "" {
		raven.SetEnvironment(sentryEnvironment)
	}

	if sentryDSN == "" {
		return h
	}

	raven.DefaultClient.SetRelease(Version)

	return sentryHandler(h)
}

// sentryHandler is based on raven.RecoveryHandler(): https://github.com/getsentry/raven-go/blob/master/http.go#L82-L101
func sentryHandler(next http.Handler) http.Handler {
	return http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		defer func() {
			rval := recover()
			switch rval {
			case nil:
				return
			case http.ErrAbortHandler:
				// Propagate the panic so that the HTTP server aborts the connection and the client knows that something went wrong.
				// We cannot do better than that because we may have written the response headers already.
				log.WithRequest(r).Info("Handler aborted connection")
				panic(http.ErrAbortHandler)
			default:
				debug.PrintStack()
				exception.CleanHeaders(r) // clean header before sending to Sentry
				rvalStr := fmt.Sprint(rval)
				var packet *raven.Packet
				if err, ok := rval.(error); ok {
					packet = raven.NewPacket(rvalStr, raven.NewException(errors.New(rvalStr), raven.GetOrNewStacktrace(err, 1, 2, nil)), raven.NewHttp(r))
				} else {
					packet = raven.NewPacket(rvalStr, raven.NewException(errors.New(rvalStr), raven.NewStacktrace(1, 2, nil)), raven.NewHttp(r))
				}
				raven.Capture(packet, nil)
				w.WriteHeader(http.StatusInternalServerError)
			}
		}()
		next.ServeHTTP(w, r)
	})
}
