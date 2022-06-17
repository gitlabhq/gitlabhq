package parser

import (
	"context"
	"io"
	"os"
	"runtime"
	"testing"

	"github.com/stretchr/testify/require"
)

func BenchmarkGenerate(b *testing.B) {
	filePath := "testdata/workhorse.lsif.zip"
	tmpDir := filePath + ".tmp"
	defer os.RemoveAll(tmpDir)

	var memoryUsage float64
	for i := 0; i < b.N; i++ {
		memoryUsage += measureMemory(func() {
			file, err := os.Open(filePath)
			require.NoError(b, err)

			parser, err := NewParser(context.Background(), file)
			require.NoError(b, err)

			_, err = io.Copy(io.Discard, parser)
			require.NoError(b, err)
			require.NoError(b, parser.Close())
		})
	}

	b.ReportMetric(memoryUsage/float64(b.N), "MiB/op")
}

func measureMemory(f func()) float64 {
	var m, m1 runtime.MemStats
	runtime.ReadMemStats(&m)

	f()

	runtime.ReadMemStats(&m1)
	runtime.GC()

	return float64(m1.Alloc-m.Alloc) / 1024 / 1024
}
