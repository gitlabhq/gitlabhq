package staticpages

import (
	"encoding/json"
	"fmt"
	"io/ioutil"
	"net/http"
	"path/filepath"

	"github.com/prometheus/client_golang/prometheus"
	"github.com/prometheus/client_golang/prometheus/promauto"

	"gitlab.com/gitlab-org/gitlab/workhorse/internal/helper"
)

var (
	staticErrorResponses = promauto.NewCounterVec(
		prometheus.CounterOpts{
			Name: "gitlab_workhorse_static_error_responses",
			Help: "How many HTTP responses have been changed to a static error page, by HTTP status code.",
		},
		[]string{"code"},
	)
)

type ErrorFormat int

const (
	ErrorFormatHTML ErrorFormat = iota
	ErrorFormatJSON
	ErrorFormatText
)

type errorPageResponseWriter struct {
	rw       http.ResponseWriter
	status   int
	hijacked bool
	path     string
	format   ErrorFormat
}

func (s *errorPageResponseWriter) Header() http.Header {
	return s.rw.Header()
}

func (s *errorPageResponseWriter) Write(data []byte) (int, error) {
	if s.status == 0 {
		s.WriteHeader(http.StatusOK)
	}
	if s.hijacked {
		return len(data), nil
	}
	return s.rw.Write(data)
}

func (s *errorPageResponseWriter) WriteHeader(status int) {
	if s.status != 0 {
		return
	}

	s.status = status

	if s.status < 400 || s.status > 599 || s.rw.Header().Get("X-GitLab-Custom-Error") != "" {
		s.rw.WriteHeader(status)
		return
	}

	var contentType string
	var data []byte
	switch s.format {
	case ErrorFormatText:
		contentType, data = s.writeText()
	case ErrorFormatJSON:
		contentType, data = s.writeJSON()
	default:
		contentType, data = s.writeHTML()
	}

	if contentType == "" {
		s.rw.WriteHeader(status)
		return
	}

	s.hijacked = true
	staticErrorResponses.WithLabelValues(fmt.Sprintf("%d", s.status)).Inc()

	helper.SetNoCacheHeaders(s.rw.Header())
	s.rw.Header().Set("Content-Type", contentType)
	s.rw.Header().Set("Content-Length", fmt.Sprintf("%d", len(data)))
	s.rw.Header().Del("Transfer-Encoding")
	s.rw.WriteHeader(s.status)
	s.rw.Write(data)
}

func (s *errorPageResponseWriter) writeHTML() (string, []byte) {
	if s.rw.Header().Get("Content-Type") != "application/json" {
		errorPageFile := filepath.Join(s.path, fmt.Sprintf("%d.html", s.status))

		// check if custom error page exists, serve this page instead
		if data, err := ioutil.ReadFile(errorPageFile); err == nil {
			return "text/html; charset=utf-8", data
		}
	}

	return "", nil
}

func (s *errorPageResponseWriter) writeJSON() (string, []byte) {
	message, err := json.Marshal(map[string]interface{}{"error": http.StatusText(s.status), "status": s.status})
	if err != nil {
		return "", nil
	}

	return "application/json; charset=utf-8", append(message, "\n"...)
}

func (s *errorPageResponseWriter) writeText() (string, []byte) {
	return "text/plain; charset=utf-8", []byte(http.StatusText(s.status) + "\n")
}

func (s *errorPageResponseWriter) flush() {
	s.WriteHeader(http.StatusOK)
}

func (st *Static) ErrorPagesUnless(disabled bool, format ErrorFormat, handler http.Handler) http.Handler {
	if disabled {
		return handler
	}
	return http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		rw := errorPageResponseWriter{
			rw:     w,
			path:   st.DocumentRoot,
			format: format,
		}
		defer rw.flush()
		handler.ServeHTTP(&rw, r)
	})
}
