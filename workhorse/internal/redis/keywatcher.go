// Package redis provides a mechanism for watching Redis key changes.
package redis

import (
	"context"
	"errors"
	"fmt"
	"strings"
	"sync"
	"time"

	"github.com/jpillora/backoff"
	"github.com/prometheus/client_golang/prometheus"
	"github.com/prometheus/client_golang/prometheus/promauto"
	"github.com/redis/go-redis/v9"

	"gitlab.com/gitlab-org/gitlab/workhorse/internal/log"
)

// KeyWatcher is responsible for watching keys in Redis and notifying subscribers.
type KeyWatcher struct {
	// Put this field first to ensure backoff.Backoff is aligned for 64-bit access
	reconnectBackoff backoff.Backoff
	mu               sync.Mutex
	newSubscriber    chan struct{}
	subscribers      map[string][]chan string
	shutdown         chan struct{}
	redisConn        *redis.Client // can be nil
	conn             *redis.PubSub
	firstRun         bool
}

// NewKeyWatcher initializes a KeyWatcher for managing Redis key subscriptions.
func NewKeyWatcher(redisConn *redis.Client) *KeyWatcher {
	return &KeyWatcher{
		newSubscriber: make(chan struct{}, 1),
		shutdown:      make(chan struct{}),
		reconnectBackoff: backoff.Backoff{
			Min:    100 * time.Millisecond,
			Max:    60 * time.Second,
			Factor: 2,
			Jitter: true,
		},
		redisConn: redisConn,
		firstRun:  true,
	}
}

var (
	// KeyWatchers tracks the number of keys being actively watched by GitLab Workhorse.
	KeyWatchers = promauto.NewGauge(
		prometheus.GaugeOpts{
			Name: "gitlab_workhorse_keywatcher_keywatchers",
			Help: "The number of keys that is being watched by gitlab-workhorse",
		},
	)
	// RedisSubscriptions tracks the current number of active Redis pubsub subscriptions.
	RedisSubscriptions = promauto.NewGauge(
		prometheus.GaugeOpts{
			Name: "gitlab_workhorse_keywatcher_redis_subscriptions",
			Help: "Current number of keywatcher Redis pubsub subscriptions",
		},
	)
	// TotalMessages counts the total number of messages received by GitLab Workhorse on Redis pubsub channels.
	TotalMessages = promauto.NewCounter(
		prometheus.CounterOpts{
			Name: "gitlab_workhorse_keywatcher_total_messages",
			Help: "How many messages gitlab-workhorse has received in total on pubsub.",
		},
	)
	// TotalActions counts various keywatcher actions like adding or removing key watchers.
	TotalActions = promauto.NewCounterVec(
		prometheus.CounterOpts{
			Name: "gitlab_workhorse_keywatcher_actions_total",
			Help: "Counts of various keywatcher actions",
		},
		[]string{"action"},
	)
	// ReceivedBytes tracks the total number of bytes received by GitLab Workhorse in Redis pubsub messages.
	ReceivedBytes = promauto.NewCounter(
		prometheus.CounterOpts{
			Name: "gitlab_workhorse_keywatcher_received_bytes_total",
			Help: "How many bytes of messages gitlab-workhorse has received in total on pubsub.",
		},
	)
)

const channelPrefix = "workhorse:notifications:"

func countAction(action string) { TotalActions.WithLabelValues(action).Add(1) }

func (kw *KeyWatcher) receivePubSubStream(ctx context.Context, pubsub *redis.PubSub) error {
	kw.mu.Lock()
	// We must share kw.conn with the goroutines that call SUBSCRIBE and
	// UNSUBSCRIBE because Redis pubsub subscriptions are tied to the
	// connection.
	kw.conn = pubsub
	kw.mu.Unlock()

	defer func() {
		kw.mu.Lock()
		defer kw.mu.Unlock()
		kw.conn.Close() // nolint:errcheck,gosec // ignore errors
		kw.conn = nil

		// Reset kw.subscribers because it is tied to Redis server side state of
		// kw.conn and we just closed that connection.
		for _, chans := range kw.subscribers {
			for _, ch := range chans {
				close(ch)
				KeyWatchers.Dec()
			}
		}
		kw.subscribers = nil
	}()

	for {
		msg, err := kw.conn.Receive(ctx)
		if err != nil {
			log.WithError(fmt.Errorf("keywatcher: pubsub receive: %v", err)).Error()
			return nil
		}

		switch msg := msg.(type) {
		case *redis.Subscription:
			RedisSubscriptions.Set(float64(msg.Count))
		case *redis.Pong:
			// Ignore.
		case *redis.Message:
			TotalMessages.Inc()
			ReceivedBytes.Add(float64(len(msg.Payload)))
			if strings.HasPrefix(msg.Channel, channelPrefix) {
				kw.notifySubscribers(msg.Channel[len(channelPrefix):], msg.Payload)
			}
		default:
			log.WithError(fmt.Errorf("keywatcher: unknown: %T", msg)).Error()
			return nil
		}
	}
}

// Process listens for pub/sub events and reconnects if needed.
func (kw *KeyWatcher) Process() {
	log.Info("keywatcher: starting process loop")

	ctx := context.Background() // lint:allow context.Background

	for {
		// Connect to Redis to flag configuration issues
		if !kw.firstRun && kw.getNumSubscribers() == 0 {
			<-kw.newSubscriber
		}

		kw.firstRun = false
		kw.processSubscriptions(ctx)

		// Precaution to avoid spinning in a loop
		time.Sleep(100 * time.Millisecond)
	}
}

func (kw *KeyWatcher) processSubscriptions(ctx context.Context) {
	log.Info("keywatcher: listening for subscriptions")
	pubsub := kw.redisConn.Subscribe(ctx, []string{}...)
	if err := pubsub.Ping(ctx); err != nil {
		log.WithError(fmt.Errorf("keywatcher: %v", err)).Error()
		time.Sleep(kw.reconnectBackoff.Duration())
		return
	}

	kw.reconnectBackoff.Reset()

	if err := kw.receivePubSubStream(ctx, pubsub); err != nil {
		log.WithError(fmt.Errorf("keywatcher: receivePubSubStream: %v", err)).Error()
	}
}

// Shutdown gracefully stops the KeyWatcher.
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
		select {
		case c <- value:
		default:
		}
	}
}

func (kw *KeyWatcher) addSubscription(ctx context.Context, key string, notify chan string) error {
	// Use a non-blocking send because we only want to initiate the connection if not present.
	// This does not guarantee that the connection will be set up by the time we attempt
	// to subscribe to the channel, but missing one long poll should not be a big deal.
	select {
	case kw.newSubscriber <- struct{}{}:
	default: // Drop the value if channel is full
	}

	kw.mu.Lock()
	defer kw.mu.Unlock()

	if kw.conn == nil {
		// This can happen because CI long polling is disabled in this Workhorse
		// process. It can also be that we are waiting for the pubsub connection
		// to be established. Either way it is OK to fail fast.
		return errors.New("no redis connection")
	}

	if len(kw.subscribers[key]) == 0 {
		countAction("create-subscription")
		if err := kw.conn.Subscribe(ctx, channelPrefix+key); err != nil {
			return err
		}
	}

	if kw.subscribers == nil {
		kw.subscribers = make(map[string][]chan string)
	}
	kw.subscribers[key] = append(kw.subscribers[key], notify)
	KeyWatchers.Inc()

	return nil
}

func (kw *KeyWatcher) delSubscription(ctx context.Context, key string, notify chan string) {
	kw.mu.Lock()
	defer kw.mu.Unlock()

	chans, ok := kw.subscribers[key]
	if !ok {
		// This can happen if the pubsub connection dropped while we were
		// waiting.
		return
	}

	for i, c := range chans {
		if notify == c {
			kw.subscribers[key] = append(chans[:i], chans[i+1:]...)
			KeyWatchers.Dec()
			break
		}
	}
	if len(kw.subscribers[key]) == 0 {
		delete(kw.subscribers, key)
		countAction("delete-subscription")
		if kw.conn != nil {
			kw.conn.Unsubscribe(ctx, channelPrefix+key) // nolint:errcheck,gosec // ignore errors
		}
	}
}
func (kw *KeyWatcher) getNumSubscribers() int {
	kw.mu.Lock()
	defer kw.mu.Unlock()

	return len(kw.subscribers)
}

func (kw *KeyWatcher) connected() bool {
	kw.mu.Lock()
	defer kw.mu.Unlock()

	return kw.conn != nil
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

// WatchKey watches a Redis key for changes and returns the change status.
func (kw *KeyWatcher) WatchKey(ctx context.Context, key, value string, timeout time.Duration) (WatchKeyStatus, error) {
	notify := make(chan string, 1)
	if err := kw.addSubscription(ctx, key, notify); err != nil {
		return WatchKeyStatusNoChange, err
	}
	defer kw.delSubscription(ctx, key, notify)

	currentValue, err := kw.redisConn.Get(ctx, key).Result()
	if errors.Is(err, redis.Nil) {
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
