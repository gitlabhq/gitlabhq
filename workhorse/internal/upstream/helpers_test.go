package upstream

import (
	"testing"

	redis "github.com/redis/go-redis/v9"
	"github.com/sirupsen/logrus"
)

// testDependencies returns a Dependencies with safe defaults for unit tests.
// Optional overrides can be applied via the with* helpers:
//
//	newUpstream(cfg, testDependencies(t, withShutdownChan(ch)), routes)
func testDependencies(_ *testing.T, opts ...func(*Dependencies)) Dependencies {
	deps := Dependencies{
		AccessLogger: logrus.StandardLogger(),
	}
	for _, opt := range opts {
		opt(&deps)
	}
	return deps
}

func withShutdownChan(ch <-chan struct{}) func(*Dependencies) {
	return func(d *Dependencies) {
		d.ShutdownChan = ch
	}
}

func withRdb(rdb *redis.Client) func(*Dependencies) {
	return func(d *Dependencies) {
		d.Rdb = rdb
	}
}
