package main

import (
	"io"
	"os"
	"testing"

	"github.com/stretchr/testify/require"
)

func Test_NewImage(t *testing.T) {
	requestedWidth := 50

	testFile := "../../testdata/image.png"
	r, err := os.Open(testFile)
	require.NoError(t, err)

	badTestFile := "../../testdata/audio.mp3"
	br, err := os.Open(badTestFile)
	require.NoError(t, err)

	type args struct {
		requestedWidth int
		r              io.Reader
	}
	tests := []struct {
		name       string
		args       args
		wantW      string
		wantErrStr string
	}{
		{
			name:       "Bad requestedWidth",
			args:       args{requestedWidth: -1},
			wantErrStr: "requestedWidth needs to be > 0",
		},
		{
			name:       "Bad r",
			args:       args{requestedWidth: requestedWidth, r: br},
			wantErrStr: "decode: image: unknown format",
		},
		{
			name: "Good",
			args: args{requestedWidth: requestedWidth, r: r},
		},
	}

	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			img, err := NewImage(tt.args.requestedWidth, tt.args.r)
			if tt.wantErrStr != "" {
				require.ErrorContains(t, err, tt.wantErrStr)
			} else {
				require.Equal(t, requestedWidth, img.RequestedWidth)
				require.NotNil(t, img.Source)
			}
		})
	}
}
