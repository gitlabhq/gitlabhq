package main

import (
	"bytes"
	"image"
	"os"
	"testing"

	"github.com/stretchr/testify/require"
)

func Test_encode(t *testing.T) {
	w := &bytes.Buffer{}

	testFile := "../../testdata/image.png"
	r, err := os.Open(testFile)
	require.NoError(t, err)

	err = encode("50", r, w)
	require.NoError(t, err)

	config, format, err := image.DecodeConfig(w)
	require.NoError(t, err)
	require.Equal(t, 46, config.Height)
	require.Equal(t, 50, config.Width)
	require.Equal(t, "png", format)
}
