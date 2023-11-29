package proxy

import (
	"testing"

	"github.com/stretchr/testify/assert"
)

func TestBufferPool(t *testing.T) {
	bp := newBufferPool()

	b := bp.Get()
	assert.Len(t, b, bufferPoolSize)

	bp.Put(b) // just test that it doesn't panic or something like that
}
