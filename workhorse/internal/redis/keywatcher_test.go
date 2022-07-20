package redis

import (
	"errors"
	"sync"
	"testing"
	"time"

	"github.com/gomodule/redigo/redis"
	"github.com/rafaeljusto/redigomock/v3"
	"github.com/stretchr/testify/require"
)

const (
	runnerKey = "runner:build_queue:10"
)

func createSubscriptionMessage(key, data string) []interface{} {
	return []interface{}{
		[]byte("message"),
		[]byte(key),
		[]byte(data),
	}
}

func createSubscribeMessage(key string) []interface{} {
	return []interface{}{
		[]byte("subscribe"),
		[]byte(key),
		[]byte("1"),
	}
}
func createUnsubscribeMessage(key string) []interface{} {
	return []interface{}{
		[]byte("unsubscribe"),
		[]byte(key),
		[]byte("1"),
	}
}

func countWatchers(key string) int {
	keyWatcherMutex.Lock()
	defer keyWatcherMutex.Unlock()
	return len(keyWatcher[key])
}

func deleteWatchers(key string) {
	keyWatcherMutex.Lock()
	defer keyWatcherMutex.Unlock()
	delete(keyWatcher, key)
}

// Forces a run of the `Process` loop against a mock PubSubConn.
func processMessages(numWatchers int, value string) {
	psc := redigomock.NewConn()

	// Setup the initial subscription message
	psc.Command("SUBSCRIBE", keySubChannel).Expect(createSubscribeMessage(keySubChannel))
	psc.Command("UNSUBSCRIBE", keySubChannel).Expect(createUnsubscribeMessage(keySubChannel))
	psc.AddSubscriptionMessage(createSubscriptionMessage(keySubChannel, runnerKey+"="+value))

	// Wait for all the `WatchKey` calls to be registered
	for countWatchers(runnerKey) != numWatchers {
		time.Sleep(time.Millisecond)
	}

	processInner(psc)
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

func TestKeyChangesBubblesUpError(t *testing.T) {
	conn, td := setupMockPool()
	defer td()

	conn.Command("GET", runnerKey).ExpectError(errors.New("test error"))

	_, err := WatchKey(runnerKey, "something", time.Second)
	require.Error(t, err, "Expected error")

	deleteWatchers(runnerKey)
}

func TestKeyChangesInstantReturn(t *testing.T) {
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
			conn, td := setupMockPool()
			defer td()

			if tc.isKeyMissing {
				conn.Command("GET", runnerKey).ExpectError(redis.ErrNil)
			} else {
				conn.Command("GET", runnerKey).Expect(tc.returnValue)
			}

			val, err := WatchKey(runnerKey, tc.watchValue, tc.timeout)

			require.NoError(t, err, "Expected no error")
			require.Equal(t, tc.expectedStatus, val, "Expected value")

			deleteWatchers(runnerKey)
		})
	}
}

func TestKeyChangesWhenWatching(t *testing.T) {
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
			conn, td := setupMockPool()
			defer td()

			if tc.isKeyMissing {
				conn.Command("GET", runnerKey).ExpectError(redis.ErrNil)
			} else {
				conn.Command("GET", runnerKey).Expect(tc.returnValue)
			}

			wg := &sync.WaitGroup{}
			wg.Add(1)

			go func() {
				defer wg.Done()
				val, err := WatchKey(runnerKey, tc.watchValue, time.Second)

				require.NoError(t, err, "Expected no error")
				require.Equal(t, tc.expectedStatus, val, "Expected value")
			}()

			processMessages(1, tc.processedValue)
			wg.Wait()
		})
	}
}

func TestKeyChangesParallel(t *testing.T) {
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

			conn, td := setupMockPool()
			defer td()

			getCmd := conn.Command("GET", runnerKey)

			for i := 0; i < runTimes; i++ {
				if tc.isKeyMissing {
					getCmd = getCmd.ExpectError(redis.ErrNil)
				} else {
					getCmd = getCmd.Expect(tc.returnValue)
				}
			}

			wg := &sync.WaitGroup{}
			wg.Add(runTimes)

			for i := 0; i < runTimes; i++ {
				go func() {
					defer wg.Done()
					val, err := WatchKey(runnerKey, tc.watchValue, time.Second)

					require.NoError(t, err, "Expected no error")
					require.Equal(t, tc.expectedStatus, val, "Expected value")
				}()
			}

			processMessages(runTimes, tc.processedValue)
			wg.Wait()
		})
	}
}

func TestShutdown(t *testing.T) {
	conn, td := setupMockPool()
	defer td()
	defer func() { shutdown = make(chan struct{}) }()

	conn.Command("GET", runnerKey).Expect("something")

	wg := &sync.WaitGroup{}
	wg.Add(2)

	go func() {
		val, err := WatchKey(runnerKey, "something", 10*time.Second)

		require.NoError(t, err, "Expected no error")
		require.Equal(t, WatchKeyStatusNoChange, val, "Expected value not to change")
		wg.Done()
	}()

	go func() {
		require.Eventually(t, func() bool { return countWatchers(runnerKey) == 1 }, 10*time.Second, time.Millisecond)

		Shutdown()
		wg.Done()
	}()

	wg.Wait()

	require.Eventually(t, func() bool { return countWatchers(runnerKey) == 0 }, 10*time.Second, time.Millisecond)

	// Adding a key after the shutdown should result in an immediate response
	var val WatchKeyStatus
	var err error
	done := make(chan struct{})
	go func() {
		val, err = WatchKey(runnerKey, "something", 10*time.Second)
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
