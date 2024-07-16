package queueing

import (
	"fmt"
	"net/http"
	"net/http/httptest"
	"testing"
	"time"

	"github.com/prometheus/client_golang/prometheus"
)

var httpHandler = http.HandlerFunc(func(w http.ResponseWriter, _ *http.Request) {
	fmt.Fprintln(w, "OK")
})

func pausedHTTPHandler(pauseCh chan struct{}) http.Handler {
	return http.HandlerFunc(func(w http.ResponseWriter, _ *http.Request) {
		<-pauseCh
		fmt.Fprintln(w, "OK")
	})
}

func TestNormalRequestProcessing(t *testing.T) {
	w := httptest.NewRecorder()
	h := QueueRequests("Normal request processing", httpHandler, 1, 1, time.Second, prometheus.NewRegistry())
	h.ServeHTTP(w, nil)
	if w.Code != 200 {
		t.Fatal("QueueRequests should process request")
	}
}

// testSlowRequestProcessing creates a new queue,
// then it runs a number of requests that are going through queue,
// we return the response of first finished request,
// where status of request can be 200, 429 or 503
func testSlowRequestProcessing(name string, count int, limit, queueLimit uint, queueTimeout time.Duration) *httptest.ResponseRecorder {
	pauseCh := make(chan struct{})
	defer close(pauseCh)

	handler := QueueRequests("Slow request processing: "+name, pausedHTTPHandler(pauseCh), limit, queueLimit, queueTimeout, prometheus.NewRegistry())

	respCh := make(chan *httptest.ResponseRecorder, count)

	// queue requests to use up the queue
	for i := 0; i < count; i++ {
		go func() {
			w := httptest.NewRecorder()
			handler.ServeHTTP(w, nil)
			respCh <- w
		}()
	}

	// dequeue first request
	return <-respCh
}

// TestQueueingTimeout performs 2 requests
// the queue limit and length is 1,
// the second request gets timed-out
func TestQueueingTimeout(t *testing.T) {
	w := testSlowRequestProcessing("timeout", 2, 1, 1, time.Microsecond)

	if w.Code != 503 {
		t.Fatal("QueueRequests should timeout queued request")
	}
}

// TestQueueingTooManyRequests performs 3 requests
// the queue limit and length is 1,
// so the third request has to be rejected with 429
func TestQueueingTooManyRequests(t *testing.T) {
	w := testSlowRequestProcessing("too many requests", 3, 1, 1, time.Minute)

	if w.Code != 429 {
		t.Fatal("QueueRequests should return immediately and return too many requests")
	}
}
