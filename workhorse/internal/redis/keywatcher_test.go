package redis

import (
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

func (kw *KeyWatcher) countSubscribers(key string) int {
	kw.mu.Lock()
	defer kw.mu.Unlock()
	return len(kw.subscribers[key])
}

// Forces a run of the `Process` loop against a mock PubSubConn.
func (kw *KeyWatcher) processMessages(t *testing.T, numWatchers int, value string, ready chan<- struct{}) {
	psc := redigomock.NewConn()
	psc.ReceiveWait = true

	channel := channelPrefix + runnerKey
	psc.Command("SUBSCRIBE", channel).Expect(createSubscribeMessage(channel))
	psc.Command("UNSUBSCRIBE", channel).Expect(createUnsubscribeMessage(channel))
	psc.AddSubscriptionMessage(createSubscriptionMessage(channel, value))

	errC := make(chan error)
	go func() { errC <- kw.receivePubSubStream(psc) }()

	require.Eventually(t, func() bool {
		kw.mu.Lock()
		defer kw.mu.Unlock()
		return kw.conn != nil
	}, time.Second, time.Millisecond)
	close(ready)

	require.Eventually(t, func() bool {
		return kw.countSubscribers(runnerKey) == numWatchers
	}, time.Second, time.Millisecond)
	close(psc.ReceiveNow)

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

			kw := NewKeyWatcher()
			defer kw.Shutdown()
			kw.conn = &redis.PubSubConn{Conn: redigomock.NewConn()}

			val, err := kw.WatchKey(runnerKey, tc.watchValue, tc.timeout)

			require.NoError(t, err, "Expected no error")
			require.Equal(t, tc.expectedStatus, val, "Expected value")
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

			kw := NewKeyWatcher()
			defer kw.Shutdown()

			wg := &sync.WaitGroup{}
			wg.Add(1)
			ready := make(chan struct{})

			go func() {
				defer wg.Done()
				<-ready
				val, err := kw.WatchKey(runnerKey, tc.watchValue, time.Second)

				require.NoError(t, err, "Expected no error")
				require.Equal(t, tc.expectedStatus, val, "Expected value")
			}()

			kw.processMessages(t, 1, tc.processedValue, ready)
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
			ready := make(chan struct{})

			kw := NewKeyWatcher()
			defer kw.Shutdown()

			for i := 0; i < runTimes; i++ {
				go func() {
					defer wg.Done()
					<-ready
					val, err := kw.WatchKey(runnerKey, tc.watchValue, time.Second)

					require.NoError(t, err, "Expected no error")
					require.Equal(t, tc.expectedStatus, val, "Expected value")
				}()
			}

			kw.processMessages(t, runTimes, tc.processedValue, ready)
			wg.Wait()
		})
	}
}

func TestShutdown(t *testing.T) {
	conn, td := setupMockPool()
	defer td()

	kw := NewKeyWatcher()
	kw.conn = &redis.PubSubConn{Conn: redigomock.NewConn()}
	defer kw.Shutdown()

	conn.Command("GET", runnerKey).Expect("something")

	wg := &sync.WaitGroup{}
	wg.Add(2)

	go func() {
		defer wg.Done()
		val, err := kw.WatchKey(runnerKey, "something", 10*time.Second)

		require.NoError(t, err, "Expected no error")
		require.Equal(t, WatchKeyStatusNoChange, val, "Expected value not to change")
	}()

	go func() {
		defer wg.Done()
		require.Eventually(t, func() bool { return kw.countSubscribers(runnerKey) == 1 }, 10*time.Second, time.Millisecond)

		kw.Shutdown()
	}()

	wg.Wait()

	require.Eventually(t, func() bool { return kw.countSubscribers(runnerKey) == 0 }, 10*time.Second, time.Millisecond)

	// Adding a key after the shutdown should result in an immediate response
	var val WatchKeyStatus
	var err error
	done := make(chan struct{})
	go func() {
		val, err = kw.WatchKey(runnerKey, "something", 10*time.Second)
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
