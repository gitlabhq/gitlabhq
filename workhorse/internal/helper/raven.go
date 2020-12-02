package helper

import (
	"net/http"
	"reflect"

	raven "github.com/getsentry/raven-go"

	//lint:ignore SA1019 this was recently deprecated. Update workhorse to use labkit errortracking package.
	correlation "gitlab.com/gitlab-org/labkit/correlation/raven"

	"gitlab.com/gitlab-org/labkit/log"
)

var ravenHeaderBlacklist = []string{
	"Authorization",
	"Private-Token",
}

func captureRavenError(r *http.Request, err error, fields log.Fields) {
	client := raven.DefaultClient
	extra := raven.Extra{}

	for k, v := range fields {
		extra[k] = v
	}

	interfaces := []raven.Interface{}
	if r != nil {
		CleanHeadersForRaven(r)
		interfaces = append(interfaces, raven.NewHttp(r))

		//lint:ignore SA1019 this was recently deprecated. Update workhorse to use labkit errortracking package.
		extra = correlation.SetExtra(r.Context(), extra)
	}

	exception := &raven.Exception{
		Stacktrace: raven.NewStacktrace(2, 3, nil),
		Value:      err.Error(),
		Type:       reflect.TypeOf(err).String(),
	}
	interfaces = append(interfaces, exception)

	packet := raven.NewPacketWithExtra(err.Error(), extra, interfaces...)
	client.Capture(packet, nil)
}

func CleanHeadersForRaven(r *http.Request) {
	if r == nil {
		return
	}

	for _, key := range ravenHeaderBlacklist {
		if r.Header.Get(key) != "" {
			r.Header.Set(key, "[redacted]")
		}
	}
}
