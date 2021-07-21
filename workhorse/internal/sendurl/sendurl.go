package sendurl

import (
	"fmt"
	"io"
	"net"
	"net/http"
	"time"

	"github.com/prometheus/client_golang/prometheus"
	"github.com/prometheus/client_golang/prometheus/promauto"

	"gitlab.com/gitlab-org/labkit/correlation"
	"gitlab.com/gitlab-org/labkit/mask"
	"gitlab.com/gitlab-org/labkit/tracing"

	"gitlab.com/gitlab-org/gitlab/workhorse/internal/helper"
	"gitlab.com/gitlab-org/gitlab/workhorse/internal/log"
	"gitlab.com/gitlab-org/gitlab/workhorse/internal/senddata"
)

type entry struct{ senddata.Prefix }

type entryParams struct {
	URL            string
	AllowRedirects bool
}

var SendURL = &entry{"send-url:"}

var rangeHeaderKeys = []string{
	"If-Match",
	"If-Unmodified-Since",
	"If-None-Match",
	"If-Modified-Since",
	"If-Range",
	"Range",
}

// Keep cache headers from the original response, not the proxied response. The
// original response comes from the Rails application, which should be the
// source of truth for caching.
var preserveHeaderKeys = map[string]bool{
	"Cache-Control": true,
	"Expires":       true,
	"Date":          true, // Support for HTTP 1.0 proxies
	"Pragma":        true, // Support for HTTP 1.0 proxies
}

// httpTransport defines a http.Transport with values
// that are more restrictive than for http.DefaultTransport,
// they define shorter TLS Handshake, and more aggressive connection closing
// to prevent the connection hanging and reduce FD usage
var httpTransport = tracing.NewRoundTripper(correlation.NewInstrumentedRoundTripper(&http.Transport{
	Proxy: http.ProxyFromEnvironment,
	DialContext: (&net.Dialer{
		Timeout:   30 * time.Second,
		KeepAlive: 10 * time.Second,
	}).DialContext,
	MaxIdleConns:          2,
	IdleConnTimeout:       30 * time.Second,
	TLSHandshakeTimeout:   10 * time.Second,
	ExpectContinueTimeout: 10 * time.Second,
	ResponseHeaderTimeout: 30 * time.Second,
}))

var httpClient = &http.Client{
	Transport: httpTransport,
}

var (
	sendURLRequests = promauto.NewCounterVec(
		prometheus.CounterOpts{
			Name: "gitlab_workhorse_send_url_requests",
			Help: "How many send URL requests have been processed",
		},
		[]string{"status"},
	)
	sendURLOpenRequests = promauto.NewGauge(
		prometheus.GaugeOpts{
			Name: "gitlab_workhorse_send_url_open_requests",
			Help: "Describes how many send URL requests are open now",
		},
	)
	sendURLBytes = promauto.NewCounter(
		prometheus.CounterOpts{
			Name: "gitlab_workhorse_send_url_bytes",
			Help: "How many bytes were passed with send URL",
		},
	)

	sendURLRequestsInvalidData   = sendURLRequests.WithLabelValues("invalid-data")
	sendURLRequestsRequestFailed = sendURLRequests.WithLabelValues("request-failed")
	sendURLRequestsSucceeded     = sendURLRequests.WithLabelValues("succeeded")
)

func (e *entry) Inject(w http.ResponseWriter, r *http.Request, sendData string) {
	var params entryParams

	sendURLOpenRequests.Inc()
	defer sendURLOpenRequests.Dec()

	if err := e.Unpack(&params, sendData); err != nil {
		helper.Fail500(w, r, fmt.Errorf("SendURL: unpack sendData: %v", err))
		return
	}

	log.WithContextFields(r.Context(), log.Fields{
		"url":  mask.URL(params.URL),
		"path": r.URL.Path,
	}).Info("SendURL: sending")

	if params.URL == "" {
		sendURLRequestsInvalidData.Inc()
		helper.Fail500(w, r, fmt.Errorf("SendURL: URL is empty"))
		return
	}

	// create new request and copy range headers
	newReq, err := http.NewRequest("GET", params.URL, nil)
	if err != nil {
		sendURLRequestsInvalidData.Inc()
		helper.Fail500(w, r, fmt.Errorf("SendURL: NewRequest: %v", err))
		return
	}
	newReq = newReq.WithContext(r.Context())

	for _, header := range rangeHeaderKeys {
		newReq.Header[header] = r.Header[header]
	}

	// execute new request
	var resp *http.Response
	if params.AllowRedirects {
		resp, err = httpClient.Do(newReq)
	} else {
		resp, err = httpTransport.RoundTrip(newReq)
	}
	if err != nil {
		sendURLRequestsRequestFailed.Inc()
		helper.Fail500(w, r, fmt.Errorf("SendURL: Do request: %v", err))
		return
	}

	// Prevent Go from adding a Content-Length header automatically
	w.Header().Del("Content-Length")

	// copy response headers and body, except the headers from preserveHeaderKeys
	for key, value := range resp.Header {
		if !preserveHeaderKeys[key] {
			w.Header()[key] = value
		}
	}
	w.WriteHeader(resp.StatusCode)

	defer resp.Body.Close()
	n, err := io.Copy(w, resp.Body)
	sendURLBytes.Add(float64(n))

	if err != nil {
		sendURLRequestsRequestFailed.Inc()
		log.WithRequest(r).WithError(fmt.Errorf("SendURL: Copy response: %v", err)).Error()
		return
	}

	sendURLRequestsSucceeded.Inc()
}
