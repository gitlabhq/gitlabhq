package goredis

import (
	"context"
	"errors"
	"fmt"
	"strings"
	"sync"
	"time"

	"github.com/jpillora/backoff"
	"github.com/redis/go-redis/v9"

	"gitlab.com/gitlab-org/gitlab/workhorse/internal/log"
	internalredis "gitlab.com/gitlab-org/gitlab/workhorse/internal/redis"
)

type KeyWatcher struct {
	mu               sync.Mutex
	subscribers      map[string][]chan string
	shutdown         chan struct{}
	reconnectBackoff backoff.Backoff
	redisConn        *redis.Client
	conn             *redis.PubSub
}

func NewKeyWatcher() *KeyWatcher {
	return &KeyWatcher{
		shutdown: make(chan struct{}),
		reconnectBackoff: backoff.Backoff{
			Min:    100 * time.Millisecond,
			Max:    60 * time.Second,
			Factor: 2,
			Jitter: true,
		},
	}
}

const channelPrefix = "workhorse:notifications:"

func countAction(action string) { internalredis.TotalActions.WithLabelValues(action).Add(1) }

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
		kw.conn.Close()
		kw.conn = nil

		// Reset kw.subscribers because it is tied to Redis server side state of
		// kw.conn and we just closed that connection.
		for _, chans := range kw.subscribers {
			for _, ch := range chans {
				close(ch)
				internalredis.KeyWatchers.Dec()
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
			internalredis.RedisSubscriptions.Set(float64(msg.Count))
		case *redis.Pong:
			// Ignore.
		case *redis.Message:
			internalredis.TotalMessages.Inc()
			internalredis.ReceivedBytes.Add(float64(len(msg.Payload)))
			if strings.HasPrefix(msg.Channel, channelPrefix) {
				kw.notifySubscribers(msg.Channel[len(channelPrefix):], string(msg.Payload))
			}
		default:
			log.WithError(fmt.Errorf("keywatcher: unknown: %T", msg)).Error()
			return nil
		}
	}
}

func (kw *KeyWatcher) Process(client *redis.Client) {
	log.Info("keywatcher: starting process loop")

	ctx := context.Background() // lint:allow context.Background
	kw.mu.Lock()
	kw.redisConn = client
	kw.mu.Unlock()

	for {
		pubsub := client.Subscribe(ctx, []string{}...)
		if err := pubsub.Ping(ctx); err != nil {
			log.WithError(fmt.Errorf("keywatcher: %v", err)).Error()
			time.Sleep(kw.reconnectBackoff.Duration())
			continue
		}

		kw.reconnectBackoff.Reset()

		if err := kw.receivePubSubStream(ctx, pubsub); err != nil {
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
		select {
		case c <- value:
		default:
		}
	}
}

func (kw *KeyWatcher) addSubscription(ctx context.Context, key string, notify chan string) error {
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
	internalredis.KeyWatchers.Inc()

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
			internalredis.KeyWatchers.Dec()
			break
		}
	}
	if len(kw.subscribers[key]) == 0 {
		delete(kw.subscribers, key)
		countAction("delete-subscription")
		if kw.conn != nil {
			kw.conn.Unsubscribe(ctx, channelPrefix+key)
		}
	}
}

func (kw *KeyWatcher) WatchKey(ctx context.Context, key, value string, timeout time.Duration) (internalredis.WatchKeyStatus, error) {
	notify := make(chan string, 1)
	if err := kw.addSubscription(ctx, key, notify); err != nil {
		return internalredis.WatchKeyStatusNoChange, err
	}
	defer kw.delSubscription(ctx, key, notify)

	currentValue, err := kw.redisConn.Get(ctx, key).Result()
	if errors.Is(err, redis.Nil) {
		currentValue = ""
	} else if err != nil {
		return internalredis.WatchKeyStatusNoChange, fmt.Errorf("keywatcher: redis GET: %v", err)
	}
	if currentValue != value {
		return internalredis.WatchKeyStatusAlreadyChanged, nil
	}

	select {
	case <-kw.shutdown:
		log.WithFields(log.Fields{"key": key}).Info("stopping watch due to shutdown")
		return internalredis.WatchKeyStatusNoChange, nil
	case currentValue := <-notify:
		if currentValue == "" {
			return internalredis.WatchKeyStatusNoChange, fmt.Errorf("keywatcher: redis GET failed")
		}
		if currentValue == value {
			return internalredis.WatchKeyStatusNoChange, nil
		}
		return internalredis.WatchKeyStatusSeenChange, nil
	case <-time.After(timeout):
		return internalredis.WatchKeyStatusTimeout, nil
	}
}
