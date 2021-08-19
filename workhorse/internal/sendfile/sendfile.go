/*
The xSendFile middleware transparently sends static files in HTTP responses
via the X-Sendfile mechanism. All that is needed in the Rails code is the
'send_file' method.
*/

package sendfile

import (
	"fmt"
	"io"
	"io/ioutil"
	"net/http"
	"regexp"

	"github.com/prometheus/client_golang/prometheus"
	"github.com/prometheus/client_golang/prometheus/promauto"

	"gitlab.com/gitlab-org/labkit/log"
	"gitlab.com/gitlab-org/labkit/mask"

	"gitlab.com/gitlab-org/gitlab/workhorse/internal/headers"
	"gitlab.com/gitlab-org/gitlab/workhorse/internal/helper"
)

var (
	sendFileRequests = promauto.NewCounterVec(
		prometheus.CounterOpts{
			Name: "gitlab_workhorse_sendfile_requests",
			Help: "How many X-Sendfile requests have been processed by gitlab-workhorse, partitioned by sendfile type.",
		},
		[]string{"type"},
	)

	sendFileBytes = promauto.NewCounterVec(
		prometheus.CounterOpts{
			Name: "gitlab_workhorse_sendfile_bytes",
			Help: "How many X-Sendfile bytes have been sent by gitlab-workhorse, partitioned by sendfile type.",
		},
		[]string{"type"},
	)

	artifactsSendFile = regexp.MustCompile("builds/[0-9]+/artifacts")
)

type sendFileResponseWriter struct {
	rw       http.ResponseWriter
	status   int
	hijacked bool
	req      *http.Request
}

func SendFile(h http.Handler) http.Handler {
	return http.HandlerFunc(func(rw http.ResponseWriter, req *http.Request) {
		s := &sendFileResponseWriter{
			rw:  rw,
			req: req,
		}
		// Advertise to upstream (Rails) that we support X-Sendfile
		req.Header.Set(headers.XSendFileTypeHeader, headers.XSendFileHeader)
		defer s.flush()
		h.ServeHTTP(s, req)
	})
}

func (s *sendFileResponseWriter) Header() http.Header {
	return s.rw.Header()
}

func (s *sendFileResponseWriter) Write(data []byte) (int, error) {
	if s.status == 0 {
		s.WriteHeader(http.StatusOK)
	}
	if s.hijacked {
		return len(data), nil
	}
	return s.rw.Write(data)
}

func (s *sendFileResponseWriter) WriteHeader(status int) {
	if s.status != 0 {
		return
	}

	s.status = status
	if s.status != http.StatusOK {
		s.rw.WriteHeader(s.status)
		return
	}

	file := s.Header().Get(headers.XSendFileHeader)
	if file != "" && !s.hijacked {
		// Mark this connection as hijacked
		s.hijacked = true

		// Serve the file
		helper.DisableResponseBuffering(s.rw)
		sendFileFromDisk(s.rw, s.req, file)
		return
	}

	s.rw.WriteHeader(s.status)
}

func sendFileFromDisk(w http.ResponseWriter, r *http.Request, file string) {
	log.WithContextFields(r.Context(), log.Fields{
		"file":   file,
		"method": r.Method,
		"uri":    mask.URL(r.RequestURI),
	}).Print("Send file")

	contentTypeHeaderPresent := false

	if headers.IsDetectContentTypeHeaderPresent(w) {
		// Removing the GitlabWorkhorseDetectContentTypeHeader header to
		// avoid handling the response by the senddata handler
		w.Header().Del(headers.GitlabWorkhorseDetectContentTypeHeader)
		contentTypeHeaderPresent = true
	}

	content, fi, err := helper.OpenFile(file)
	if err != nil {
		http.NotFound(w, r)
		return
	}
	defer content.Close()

	countSendFileMetrics(fi.Size(), r)

	if contentTypeHeaderPresent {
		data, err := ioutil.ReadAll(io.LimitReader(content, headers.MaxDetectSize))
		if err != nil {
			helper.Fail500(w, r, fmt.Errorf("content type detection: %v", err))
			return
		}

		content.Seek(0, io.SeekStart)

		contentType, contentDisposition := headers.SafeContentHeaders(data, w.Header().Get(headers.ContentDispositionHeader))
		w.Header().Set(headers.ContentTypeHeader, contentType)
		w.Header().Set(headers.ContentDispositionHeader, contentDisposition)
	}

	http.ServeContent(w, r, "", fi.ModTime(), content)
}

func countSendFileMetrics(size int64, r *http.Request) {
	var requestType string
	switch {
	case artifactsSendFile.MatchString(r.RequestURI):
		requestType = "artifacts"
	default:
		requestType = "other"
	}

	sendFileRequests.WithLabelValues(requestType).Inc()
	sendFileBytes.WithLabelValues(requestType).Add(float64(size))
}

func (s *sendFileResponseWriter) flush() {
	s.WriteHeader(http.StatusOK)
}
