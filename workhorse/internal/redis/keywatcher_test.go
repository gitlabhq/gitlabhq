package redis

import (
	"context"
	"os"
	"sync"
	"testing"
	"time"

	"github.com/redis/go-redis/v9"
	"github.com/stretchr/testify/assert"
	"github.com/stretchr/testify/require"

	"gitlab.com/gitlab-org/gitlab/workhorse/internal/config"
)

var ctx = context.Background()

const (
	runnerKey = "runner:build_queue:10"
)

func initRdb(t *testing.T) *redis.Client {
	buf, err := os.ReadFile("../../config.toml")
	require.NoError(t, err)
	cfg, err := config.LoadConfig(string(buf))
	require.NoError(t, err)
	rdb, err := Configure(cfg)
	require.NoError(t, err)
	t.Cleanup(func() {
		assert.NoError(t, rdb.Close())
	})
	return rdb
}

func countSubscribers(kw *KeyWatcher, key string) int {
	kw.mu.Lock()
	defer kw.mu.Unlock()
	return len(kw.subscribers[key])
}

// Forces a run of the `Process` loop against a mock PubSubConn.
func processMessages(t *testing.T, kw *KeyWatcher, numWatchers int, value string, ready chan<- struct{}, wg *sync.WaitGroup) {
	psc := kw.redisConn.Subscribe(ctx, []string{}...)

	errC := make(chan error)
	go func() { errC <- kw.receivePubSubStream(ctx, psc) }()

	require.Eventually(t, func() bool {
		kw.mu.Lock()
		defer kw.mu.Unlock()
		return kw.conn != nil
	}, time.Second, time.Millisecond)
	close(ready)

	require.Eventually(t, func() bool {
		return countSubscribers(kw, runnerKey) == numWatchers
	}, time.Second, time.Millisecond)

	// send message after listeners are ready
	kw.redisConn.Publish(ctx, channelPrefix+runnerKey, value)

	// close subscription after all workers are done
	wg.Wait()
	kw.mu.Lock()
	kw.conn.Close()
	kw.mu.Unlock()

	require.NoError(t, <-errC)
}

type keyChangeTestCase struct {
	desc           string
	returnValue    string
	isKeyMissing   bool
	watchValue     string
	processedValue string
	expectedStatus WatchKeyStatus
	timeout        time.Duration
}

func TestKeyChangesInstantReturn(t *testing.T) {
	rdb := initRdb(t)

	testCases := []keyChangeTestCase{
		// WatchKeyStatusAlreadyChanged
		{
			desc:           "sees change with key existing and changed",
			returnValue:    "somethingelse",
			watchValue:     "something",
			expectedStatus: WatchKeyStatusAlreadyChanged,
			timeout:        time.Second,
		},
		{
			desc:           "sees change with key non-existing",
			isKeyMissing:   true,
			watchValue:     "something",
			processedValue: "somethingelse",
			expectedStatus: WatchKeyStatusAlreadyChanged,
			timeout:        time.Second,
		},
		// WatchKeyStatusTimeout
		{
			desc:           "sees timeout with key existing and unchanged",
			returnValue:    "something",
			watchValue:     "something",
			expectedStatus: WatchKeyStatusTimeout,
			timeout:        time.Millisecond,
		},
		{
			desc:           "sees timeout with key non-existing and unchanged",
			isKeyMissing:   true,
			watchValue:     "",
			expectedStatus: WatchKeyStatusTimeout,
			timeout:        time.Millisecond,
		},
	}

	for _, tc := range testCases {
		t.Run(tc.desc, func(t *testing.T) {
			// setup
			if !tc.isKeyMissing {
				rdb.Set(ctx, runnerKey, tc.returnValue, 0)
			}

			defer rdb.FlushDB(ctx)

			kw := NewKeyWatcher(rdb)
			defer kw.Shutdown()
			kw.conn = kw.redisConn.Subscribe(ctx, []string{}...)

			val, err := kw.WatchKey(ctx, runnerKey, tc.watchValue, tc.timeout)

			require.NoError(t, err, "Expected no error")
			require.Equal(t, tc.expectedStatus, val, "Expected value")
		})
	}
}

func TestKeyChangesWhenWatching(t *testing.T) {
	rdb := initRdb(t)

	testCases := []keyChangeTestCase{
		// WatchKeyStatusSeenChange
		{
			desc:           "sees change with key existing",
			returnValue:    "something",
			watchValue:     "something",
			processedValue: "somethingelse",
			expectedStatus: WatchKeyStatusSeenChange,
		},
		{
			desc:           "sees change with key non-existing, when watching empty value",
			isKeyMissing:   true,
			watchValue:     "",
			processedValue: "something",
			expectedStatus: WatchKeyStatusSeenChange,
		},
		// WatchKeyStatusNoChange
		{
			desc:           "sees no change with key existing",
			returnValue:    "something",
			watchValue:     "something",
			processedValue: "something",
			expectedStatus: WatchKeyStatusNoChange,
		},
	}

	for _, tc := range testCases {
		t.Run(tc.desc, func(t *testing.T) {
			if !tc.isKeyMissing {
				rdb.Set(ctx, runnerKey, tc.returnValue, 0)
			}

			kw := NewKeyWatcher(rdb)
			defer kw.Shutdown()
			defer rdb.FlushDB(ctx)

			wg := &sync.WaitGroup{}
			wg.Add(1)
			ready := make(chan struct{})

			go func() {
				defer wg.Done()
				<-ready
				val, err := kw.WatchKey(ctx, runnerKey, tc.watchValue, time.Second)

				assert.NoError(t, err, "Expected no error")
				assert.Equal(t, tc.expectedStatus, val, "Expected value")
			}()

			processMessages(t, kw, 1, tc.processedValue, ready, wg)
		})
	}
}

func TestKeyChangesParallel(t *testing.T) {
	rdb := initRdb(t)

	testCases := []keyChangeTestCase{
		{
			desc:           "massively parallel, sees change with key existing",
			returnValue:    "something",
			watchValue:     "something",
			processedValue: "somethingelse",
			expectedStatus: WatchKeyStatusSeenChange,
		},
		{
			desc:           "massively parallel, sees change with key existing, watching missing keys",
			isKeyMissing:   true,
			watchValue:     "",
			processedValue: "somethingelse",
			expectedStatus: WatchKeyStatusSeenChange,
		},
	}

	for _, tc := range testCases {
		t.Run(tc.desc, func(t *testing.T) {
			runTimes := 100

			if !tc.isKeyMissing {
				rdb.Set(ctx, runnerKey, tc.returnValue, 0)
			}

			defer rdb.FlushDB(ctx)

			wg := &sync.WaitGroup{}
			wg.Add(runTimes)
			ready := make(chan struct{})

			kw := NewKeyWatcher(rdb)
			defer kw.Shutdown()

			for i := 0; i < runTimes; i++ {
				go func() {
					defer wg.Done()
					<-ready
					val, err := kw.WatchKey(ctx, runnerKey, tc.watchValue, time.Second)

					assert.NoError(t, err, "Expected no error")
					assert.Equal(t, tc.expectedStatus, val, "Expected value")
				}()
			}

			processMessages(t, kw, runTimes, tc.processedValue, ready, wg)
		})
	}
}

func TestShutdown(t *testing.T) {
	rdb := initRdb(t)

	kw := NewKeyWatcher(rdb)
	kw.conn = kw.redisConn.Subscribe(ctx, []string{}...)
	defer kw.Shutdown()

	rdb.Set(ctx, runnerKey, "something", 0)

	wg := &sync.WaitGroup{}
	wg.Add(2)

	go func() {
		defer wg.Done()
		val, err := kw.WatchKey(ctx, runnerKey, "something", 10*time.Second)

		assert.NoError(t, err, "Expected no error")
		assert.Equal(t, WatchKeyStatusNoChange, val, "Expected value not to change")
	}()

	go func() {
		defer wg.Done()
		assert.Eventually(t, func() bool { return countSubscribers(kw, runnerKey) == 1 }, 10*time.Second, time.Millisecond)

		kw.Shutdown()
	}()

	wg.Wait()

	require.Eventually(t, func() bool { return countSubscribers(kw, runnerKey) == 0 }, 10*time.Second, time.Millisecond)

	// Adding a key after the shutdown should result in an immediate response
	var val WatchKeyStatus
	var err error
	done := make(chan struct{})
	go func() {
		val, err = kw.WatchKey(ctx, runnerKey, "something", 10*time.Second)
		close(done)
	}()

	select {
	case <-done:
		require.NoError(t, err, "Expected no error")
		require.Equal(t, WatchKeyStatusNoChange, val, "Expected value not to change")
	case <-time.After(100 * time.Millisecond):
		t.Fatal("timeout waiting for WatchKey")
	}
}

func TestLazySubscribeInit(t *testing.T) {
	rdb := initRdb(t)
	kw := NewKeyWatcher(rdb)
	require.True(t, kw.firstRun)

	kw.firstRun = false
	defer kw.Shutdown()

	go kw.Process()

	require.Equal(t, 0, kw.getNumSubscribers())
	require.False(t, kw.connected())
	ctx, cancel := context.WithCancel(context.Background())
	defer cancel()

	notify := make(chan string)
	// Add a subscription to initiate a Redis connection
	kw.addSubscription(ctx, "test_key", notify)

	require.Eventually(t, func() bool {
		return kw.connected()
	}, time.Second, time.Millisecond)

	// Add another one just to ensure there is at least one subscriber
	err := kw.addSubscription(ctx, "test_key2", notify)
	require.NoError(t, err)

	require.Eventually(t, func() bool {
		return kw.getNumSubscribers() > 0
	}, time.Second, time.Millisecond, "Subscription was not added")

	require.Eventually(t, func() bool {
		return kw.connected()
	}, time.Second, time.Millisecond)

	kw.delSubscription(ctx, "test_key", notify)
	kw.delSubscription(ctx, "test_key2", notify)
}
