package filestore

import (
	"context"
	"os"
	"strings"
	"testing"
	"time"

	"github.com/stretchr/testify/require"
)

func TestConsume(t *testing.T) {
	f, err := os.CreateTemp("", "filestore-local-file")
	if f != nil {
		defer os.Remove(f.Name())
	}
	require.NoError(t, err)
	defer f.Close()

	localFile := &LocalFile{File: f}

	ctx, cancel := context.WithCancel(context.Background())
	defer cancel()

	content := "file content"
	reader := strings.NewReader(content)
	var deadline time.Time

	n, err := localFile.Consume(ctx, reader, deadline)
	require.NoError(t, err)
	require.Equal(t, int64(len(content)), n)

	consumedContent, err := os.ReadFile(f.Name())
	require.NoError(t, err)
	require.Equal(t, content, string(consumedContent))
}
