package redis

import (
	"errors"
	"fmt"
	"strings"
	"sync"
	"time"

	"github.com/gomodule/redigo/redis"
	"github.com/jpillora/backoff"
	"github.com/prometheus/client_golang/prometheus"
	"github.com/prometheus/client_golang/prometheus/promauto"

	"gitlab.com/gitlab-org/gitlab/workhorse/internal/log"
)

type KeyWatcher struct {
	mu               sync.Mutex
	subscribers      map[string][]chan string
	shutdown         chan struct{}
	reconnectBackoff backoff.Backoff
}

func NewKeyWatcher() *KeyWatcher {
	return &KeyWatcher{
		subscribers: make(map[string][]chan string),
		shutdown:    make(chan struct{}),
		reconnectBackoff: backoff.Backoff{
			Min:    100 * time.Millisecond,
			Max:    60 * time.Second,
			Factor: 2,
			Jitter: true,
		},
	}
}

var (
	keyWatchers = promauto.NewGauge(
		prometheus.GaugeOpts{
			Name: "gitlab_workhorse_keywatcher_keywatchers",
			Help: "The number of keys that is being watched by gitlab-workhorse",
		},
	)
	totalMessages = promauto.NewCounter(
		prometheus.CounterOpts{
			Name: "gitlab_workhorse_keywatcher_total_messages",
			Help: "How many messages gitlab-workhorse has received in total on pubsub.",
		},
	)
	totalActions = promauto.NewCounterVec(
		prometheus.CounterOpts{
			Name: "gitlab_workhorse_keywatcher_actions_total",
			Help: "Counts of various keywatcher actions",
		},
		[]string{"action"},
	)
	receivedBytes = promauto.NewCounter(
		prometheus.CounterOpts{
			Name: "gitlab_workhorse_keywatcher_received_bytes_total",
			Help: "How many bytes of messages gitlab-workhorse has received in total on pubsub.",
		},
	)
)

const (
	keySubChannel = "workhorse:notifications"
)

func countAction(action string) { totalActions.WithLabelValues(action).Add(1) }

func (kw *KeyWatcher) receivePubSubStream(conn redis.Conn) error {
	defer conn.Close()
	psc := redis.PubSubConn{Conn: conn}
	if err := psc.Subscribe(keySubChannel); err != nil {
		return err
	}
	defer psc.Unsubscribe(keySubChannel)

	for {
		switch v := psc.Receive().(type) {
		case redis.Message:
			totalMessages.Inc()
			dataStr := string(v.Data)
			receivedBytes.Add(float64(len(dataStr)))
			msg := strings.SplitN(dataStr, "=", 2)
			if len(msg) != 2 {
				log.WithError(fmt.Errorf("keywatcher: invalid notification: %q", dataStr)).Error()
				continue
			}
			kw.notifySubscribers(msg[0], msg[1])
		case error:
			log.WithError(fmt.Errorf("keywatcher: pubsub receive: %v", v)).Error()
			// Intermittent error, return nil so that it doesn't wait before reconnect
			return nil
		}
	}
}

func dialPubSub(dialer redisDialerFunc) (redis.Conn, error) {
	conn, err := dialer()
	if err != nil {
		return nil, err
	}

	// Make sure Redis is actually connected
	conn.Do("PING")
	if err := conn.Err(); err != nil {
		conn.Close()
		return nil, err
	}

	return conn, nil
}

func (kw *KeyWatcher) Process() {
	log.Info("keywatcher: starting process loop")
	for {
		conn, err := dialPubSub(workerDialFunc)
		if err != nil {
			log.WithError(fmt.Errorf("keywatcher: %v", err)).Error()
			time.Sleep(kw.reconnectBackoff.Duration())
			continue
		}
		kw.reconnectBackoff.Reset()

		if err = kw.receivePubSubStream(conn); err != nil {
			log.WithError(fmt.Errorf("keywatcher: receivePubSubStream: %v", err)).Error()
		}
	}
}

func (kw *KeyWatcher) Shutdown() {
	log.Info("keywatcher: shutting down")

	kw.mu.Lock()
	defer kw.mu.Unlock()

	select {
	case <-kw.shutdown:
		// already closed
	default:
		close(kw.shutdown)
	}
}

func (kw *KeyWatcher) notifySubscribers(key, value string) {
	kw.mu.Lock()
	defer kw.mu.Unlock()

	chanList, ok := kw.subscribers[key]
	if !ok {
		countAction("drop-message")
		return
	}

	countAction("deliver-message")
	for _, c := range chanList {
		c <- value
		keyWatchers.Dec()
	}
	delete(kw.subscribers, key)
}

func (kw *KeyWatcher) addSubscription(key string, notify chan string) {
	kw.mu.Lock()
	defer kw.mu.Unlock()

	kw.subscribers[key] = append(kw.subscribers[key], notify)
	keyWatchers.Inc()
	if len(kw.subscribers[key]) == 1 {
		countAction("create-subscription")
	}
}

func (kw *KeyWatcher) delSubscription(key string, notify chan string) {
	kw.mu.Lock()
	defer kw.mu.Unlock()

	chans, ok := kw.subscribers[key]
	if !ok {
		return
	}

	for i, c := range chans {
		if notify == c {
			kw.subscribers[key] = append(chans[:i], chans[i+1:]...)
			keyWatchers.Dec()
			break
		}
	}
	if len(kw.subscribers[key]) == 0 {
		delete(kw.subscribers, key)
		countAction("delete-subscription")
	}
}

// WatchKeyStatus is used to tell how WatchKey returned
type WatchKeyStatus int

const (
	// WatchKeyStatusTimeout is returned when the watch timeout provided by the caller was exceeded
	WatchKeyStatusTimeout WatchKeyStatus = iota
	// WatchKeyStatusAlreadyChanged is returned when the value passed by the caller was never observed
	WatchKeyStatusAlreadyChanged
	// WatchKeyStatusSeenChange is returned when we have seen the value passed by the caller get changed
	WatchKeyStatusSeenChange
	// WatchKeyStatusNoChange is returned when the function had to return before observing a change.
	//  Also returned on errors.
	WatchKeyStatusNoChange
)

func (kw *KeyWatcher) WatchKey(key, value string, timeout time.Duration) (WatchKeyStatus, error) {
	notify := make(chan string, 1)
	kw.addSubscription(key, notify)
	defer kw.delSubscription(key, notify)

	currentValue, err := GetString(key)
	if errors.Is(err, redis.ErrNil) {
		currentValue = ""
	} else if err != nil {
		return WatchKeyStatusNoChange, fmt.Errorf("keywatcher: redis GET: %v", err)
	}
	if currentValue != value {
		return WatchKeyStatusAlreadyChanged, nil
	}

	select {
	case <-kw.shutdown:
		log.WithFields(log.Fields{"key": key}).Info("stopping watch due to shutdown")
		return WatchKeyStatusNoChange, nil
	case currentValue := <-notify:
		if currentValue == "" {
			return WatchKeyStatusNoChange, fmt.Errorf("keywatcher: redis GET failed")
		}
		if currentValue == value {
			return WatchKeyStatusNoChange, nil
		}
		return WatchKeyStatusSeenChange, nil
	case <-time.After(timeout):
		return WatchKeyStatusTimeout, nil
	}
}
