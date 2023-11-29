package goredis

import (
	"context"
	"os"
	"sync"
	"testing"
	"time"

	"github.com/stretchr/testify/require"

	"gitlab.com/gitlab-org/gitlab/workhorse/internal/config"
	"gitlab.com/gitlab-org/gitlab/workhorse/internal/redis"
)

var ctx = context.Background()

const (
	runnerKey = "runner:build_queue:10"
)

func initRdb() {
	buf, _ := os.ReadFile("../../config.toml")
	cfg, _ := config.LoadConfig(string(buf))
	Configure(cfg.Redis)
}

func (kw *KeyWatcher) countSubscribers(key string) int {
	kw.mu.Lock()
	defer kw.mu.Unlock()
	return len(kw.subscribers[key])
}

// Forces a run of the `Process` loop against a mock PubSubConn.
func (kw *KeyWatcher) processMessages(t *testing.T, numWatchers int, value string, ready chan<- struct{}, wg *sync.WaitGroup) {
	kw.mu.Lock()
	kw.redisConn = rdb
	psc := kw.redisConn.Subscribe(ctx, []string{}...)
	kw.mu.Unlock()

	errC := make(chan error)
	go func() { errC <- kw.receivePubSubStream(ctx, psc) }()

	require.Eventually(t, func() bool {
		kw.mu.Lock()
		defer kw.mu.Unlock()
		return kw.conn != nil
	}, time.Second, time.Millisecond)
	close(ready)

	require.Eventually(t, func() bool {
		return kw.countSubscribers(runnerKey) == numWatchers
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
	expectedStatus redis.WatchKeyStatus
	timeout        time.Duration
}

func TestKeyChangesInstantReturn(t *testing.T) {
	initRdb()

	testCases := []keyChangeTestCase{
		// WatchKeyStatusAlreadyChanged
		{
			desc:           "sees change with key existing and changed",
			returnValue:    "somethingelse",
			watchValue:     "something",
			expectedStatus: redis.WatchKeyStatusAlreadyChanged,
			timeout:        time.Second,
		},
		{
			desc:           "sees change with key non-existing",
			isKeyMissing:   true,
			watchValue:     "something",
			processedValue: "somethingelse",
			expectedStatus: redis.WatchKeyStatusAlreadyChanged,
			timeout:        time.Second,
		},
		// WatchKeyStatusTimeout
		{
			desc:           "sees timeout with key existing and unchanged",
			returnValue:    "something",
			watchValue:     "something",
			expectedStatus: redis.WatchKeyStatusTimeout,
			timeout:        time.Millisecond,
		},
		{
			desc:           "sees timeout with key non-existing and unchanged",
			isKeyMissing:   true,
			watchValue:     "",
			expectedStatus: redis.WatchKeyStatusTimeout,
			timeout:        time.Millisecond,
		},
	}

	for _, tc := range testCases {
		t.Run(tc.desc, func(t *testing.T) {

			// setup
			if !tc.isKeyMissing {
				rdb.Set(ctx, runnerKey, tc.returnValue, 0)
			}

			defer func() {
				rdb.FlushDB(ctx)
			}()

			kw := NewKeyWatcher()
			defer kw.Shutdown()
			kw.redisConn = rdb
			kw.conn = kw.redisConn.Subscribe(ctx, []string{}...)

			val, err := kw.WatchKey(ctx, runnerKey, tc.watchValue, tc.timeout)

			require.NoError(t, err, "Expected no error")
			require.Equal(t, tc.expectedStatus, val, "Expected value")
		})
	}
}

func TestKeyChangesWhenWatching(t *testing.T) {
	initRdb()

	testCases := []keyChangeTestCase{
		// WatchKeyStatusSeenChange
		{
			desc:           "sees change with key existing",
			returnValue:    "something",
			watchValue:     "something",
			processedValue: "somethingelse",
			expectedStatus: redis.WatchKeyStatusSeenChange,
		},
		{
			desc:           "sees change with key non-existing, when watching empty value",
			isKeyMissing:   true,
			watchValue:     "",
			processedValue: "something",
			expectedStatus: redis.WatchKeyStatusSeenChange,
		},
		// WatchKeyStatusNoChange
		{
			desc:           "sees no change with key existing",
			returnValue:    "something",
			watchValue:     "something",
			processedValue: "something",
			expectedStatus: redis.WatchKeyStatusNoChange,
		},
	}

	for _, tc := range testCases {
		t.Run(tc.desc, func(t *testing.T) {
			if !tc.isKeyMissing {
				rdb.Set(ctx, runnerKey, tc.returnValue, 0)
			}

			kw := NewKeyWatcher()
			defer kw.Shutdown()
			defer func() {
				rdb.FlushDB(ctx)
			}()

			wg := &sync.WaitGroup{}
			wg.Add(1)
			ready := make(chan struct{})

			go func() {
				defer wg.Done()
				<-ready
				val, err := kw.WatchKey(ctx, runnerKey, tc.watchValue, time.Second)

				require.NoError(t, err, "Expected no error")
				require.Equal(t, tc.expectedStatus, val, "Expected value")
			}()

			kw.processMessages(t, 1, tc.processedValue, ready, wg)
		})
	}
}

func TestKeyChangesParallel(t *testing.T) {
	initRdb()

	testCases := []keyChangeTestCase{
		{
			desc:           "massively parallel, sees change with key existing",
			returnValue:    "something",
			watchValue:     "something",
			processedValue: "somethingelse",
			expectedStatus: redis.WatchKeyStatusSeenChange,
		},
		{
			desc:           "massively parallel, sees change with key existing, watching missing keys",
			isKeyMissing:   true,
			watchValue:     "",
			processedValue: "somethingelse",
			expectedStatus: redis.WatchKeyStatusSeenChange,
		},
	}

	for _, tc := range testCases {
		t.Run(tc.desc, func(t *testing.T) {
			runTimes := 100

			if !tc.isKeyMissing {
				rdb.Set(ctx, runnerKey, tc.returnValue, 0)
			}

			defer func() {
				rdb.FlushDB(ctx)
			}()

			wg := &sync.WaitGroup{}
			wg.Add(runTimes)
			ready := make(chan struct{})

			kw := NewKeyWatcher()
			defer kw.Shutdown()

			for i := 0; i < runTimes; i++ {
				go func() {
					defer wg.Done()
					<-ready
					val, err := kw.WatchKey(ctx, runnerKey, tc.watchValue, time.Second)

					require.NoError(t, err, "Expected no error")
					require.Equal(t, tc.expectedStatus, val, "Expected value")
				}()
			}

			kw.processMessages(t, runTimes, tc.processedValue, ready, wg)
		})
	}
}

func TestShutdown(t *testing.T) {
	initRdb()

	kw := NewKeyWatcher()
	kw.redisConn = rdb
	kw.conn = kw.redisConn.Subscribe(ctx, []string{}...)
	defer kw.Shutdown()

	rdb.Set(ctx, runnerKey, "something", 0)

	wg := &sync.WaitGroup{}
	wg.Add(2)

	go func() {
		defer wg.Done()
		val, err := kw.WatchKey(ctx, runnerKey, "something", 10*time.Second)

		require.NoError(t, err, "Expected no error")
		require.Equal(t, redis.WatchKeyStatusNoChange, val, "Expected value not to change")
	}()

	go func() {
		defer wg.Done()
		require.Eventually(t, func() bool { return kw.countSubscribers(runnerKey) == 1 }, 10*time.Second, time.Millisecond)

		kw.Shutdown()
	}()

	wg.Wait()

	require.Eventually(t, func() bool { return kw.countSubscribers(runnerKey) == 0 }, 10*time.Second, time.Millisecond)

	// Adding a key after the shutdown should result in an immediate response
	var val redis.WatchKeyStatus
	var err error
	done := make(chan struct{})
	go func() {
		val, err = kw.WatchKey(ctx, runnerKey, "something", 10*time.Second)
		close(done)
	}()

	select {
	case <-done:
		require.NoError(t, err, "Expected no error")
		require.Equal(t, redis.WatchKeyStatusNoChange, val, "Expected value not to change")
	case <-time.After(100 * time.Millisecond):
		t.Fatal("timeout waiting for WatchKey")
	}
}
