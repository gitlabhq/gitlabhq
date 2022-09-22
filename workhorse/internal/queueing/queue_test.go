package queueing

import (
	"testing"
	"time"

	"github.com/prometheus/client_golang/prometheus"
)

func TestNormalQueueing(t *testing.T) {
	q := newQueue("queue name", 2, 1, time.Microsecond, prometheus.NewRegistry())
	err1 := q.Acquire()
	if err1 != nil {
		t.Fatal("we should acquire a new slot")
	}

	err2 := q.Acquire()
	if err2 != nil {
		t.Fatal("we should acquire a new slot")
	}

	err3 := q.Acquire()
	if err3 != ErrQueueingTimedout {
		t.Fatal("we should timeout")
	}

	q.Release()

	err4 := q.Acquire()
	if err4 != nil {
		t.Fatal("we should acquire a new slot")
	}
}

func TestQueueLimit(t *testing.T) {
	q := newQueue("queue name", 1, 0, time.Microsecond, prometheus.NewRegistry())
	err1 := q.Acquire()
	if err1 != nil {
		t.Fatal("we should acquire a new slot")
	}

	err2 := q.Acquire()
	if err2 != ErrTooManyRequests {
		t.Fatal("we should fail because of not enough slots in queue")
	}
}

func TestQueueProcessing(t *testing.T) {
	q := newQueue("queue name", 1, 1, time.Second, prometheus.NewRegistry())
	err1 := q.Acquire()
	if err1 != nil {
		t.Fatal("we should acquire a new slot")
	}

	go func() {
		time.Sleep(50 * time.Microsecond)
		q.Release()
	}()

	err2 := q.Acquire()
	if err2 != nil {
		t.Fatal("we should acquire slot after the previous one finished")
	}
}
