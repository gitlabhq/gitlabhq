package senddata

import (
	"net/http"

	"gitlab.com/gitlab-org/gitlab/workhorse/internal/headers"
	"gitlab.com/gitlab-org/gitlab/workhorse/internal/helper"
	"gitlab.com/gitlab-org/gitlab/workhorse/internal/senddata/contentprocessor"

	"github.com/prometheus/client_golang/prometheus"
	"github.com/prometheus/client_golang/prometheus/promauto"
)

var (
	sendDataResponses = promauto.NewCounterVec(
		prometheus.CounterOpts{
			Name: "gitlab_workhorse_senddata_responses",
			Help: "How many HTTP responses have been hijacked by a workhorse senddata injecter",
		},
		[]string{"injecter"},
	)
	sendDataResponseBytes = promauto.NewCounterVec(
		prometheus.CounterOpts{
			Name: "gitlab_workhorse_senddata_response_bytes",
			Help: "How many bytes have been written by workhorse senddata response injecters",
		},
		[]string{"injecter"},
	)
)

type sendDataResponseWriter struct {
	rw        http.ResponseWriter
	status    int
	hijacked  bool
	req       *http.Request
	injecters []Injecter
}

func SendData(h http.Handler, injecters ...Injecter) http.Handler {
	return contentprocessor.SetContentHeaders(http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		s := sendDataResponseWriter{
			rw:        w,
			req:       r,
			injecters: injecters,
		}
		defer s.flush()
		h.ServeHTTP(&s, r)
	}))
}

func (s *sendDataResponseWriter) Header() http.Header {
	return s.rw.Header()
}

func (s *sendDataResponseWriter) Write(data []byte) (int, error) {
	if s.status == 0 {
		s.WriteHeader(http.StatusOK)
	}
	if s.hijacked {
		return len(data), nil
	}
	return s.rw.Write(data)
}

func (s *sendDataResponseWriter) WriteHeader(status int) {
	if s.status != 0 {
		return
	}
	s.status = status

	if s.status == http.StatusOK && s.tryInject() {
		return
	}

	s.rw.WriteHeader(s.status)
}

func (s *sendDataResponseWriter) tryInject() bool {
	if s.hijacked {
		return false
	}

	header := s.Header().Get(headers.GitlabWorkhorseSendDataHeader)
	if header == "" {
		return false
	}

	for _, injecter := range s.injecters {
		if injecter.Match(header) {
			s.hijacked = true
			helper.DisableResponseBuffering(s.rw)
			crw := helper.NewCountingResponseWriter(s.rw)
			injecter.Inject(crw, s.req, header)
			sendDataResponses.WithLabelValues(injecter.Name()).Inc()
			sendDataResponseBytes.WithLabelValues(injecter.Name()).Add(float64(crw.Count()))
			return true
		}
	}

	return false
}

func (s *sendDataResponseWriter) flush() {
	s.WriteHeader(http.StatusOK)
}
