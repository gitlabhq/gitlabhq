package helper

import (
	"os"
	"testing"

	"github.com/stretchr/testify/require"
)

func TestOpenFile(t *testing.T) {
	tests := []struct {
		name        string
		path        string
		createFunc  func(string) (string, error)
		wantFileNil bool
		wantFiNil   bool
		wantErr     bool
	}{
		{
			name: "valid - file exists",
			path: "testfile.txt",
			createFunc: func(path string) (string, error) {
				tempPath, err := os.CreateTemp(t.TempDir(), path)
				if err != nil {
					return "", err
				}
				return tempPath.Name(), nil
			},
			wantFileNil: false,
			wantFiNil:   false,
			wantErr:     false,
		},
		{
			name: "invalid - file doesn't exist",
			path: "testfile.txt",
			createFunc: func(path string) (string, error) {
				return path, nil
			},
			wantFileNil: true,
			wantFiNil:   true,
			wantErr:     true,
		},
		{
			name: "invalid - path is directory",
			path: "_",
			createFunc: func(_ string) (string, error) {
				return t.TempDir(), nil
			},
			wantFileNil: false,
			wantFiNil:   false,
			wantErr:     true,
		},
	}

	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			path, _ := tt.createFunc(tt.path)
			file, fi, err := OpenFile(path)

			if tt.wantErr {
				require.Error(t, err, "Expected an error but got nil")
			} else {
				require.NoError(t, err, "Unexpected error")
			}

			if tt.wantFileNil {
				require.Nil(t, file, "Expected file to be nil")
			} else {
				require.NotNil(t, file, "Expected file to be non-nil")
			}

			if tt.wantFiNil {
				require.Nil(t, fi, "Expected FileInfo to be nil")
			} else {
				require.NotNil(t, fi, "Expected FileInfo to be non-nil")
			}
		})
	}
}

func TestURLMustParse(t *testing.T) {
	tests := []struct {
		name      string
		urlString string
		wantPath  string
		wantHost  string
	}{
		{
			name:      "valid URL",
			urlString: "http://example.com",
			wantPath:  "",
			wantHost:  "example.com",
		},
		{
			name:      "empty URL",
			urlString: "",
			wantPath:  "",
			wantHost:  "",
		},
		{
			name:      "invalid URL",
			urlString: "This is a string",
			wantPath:  "This is a string",
			wantHost:  "",
		},
	}

	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			u := URLMustParse(tt.urlString)
			require.NotNil(t, u, "URLMustParse returned nil for a valid URL")
			require.Equal(t, tt.wantPath, u.Path, "URLMustParse returned an unexpected path")
			require.Equal(t, tt.wantHost, u.Host, "URLMustParse returned an unexpected host")
		})
	}
}

func TestIsContentType(t *testing.T) {
	type args struct {
		expected string
		actual   string
	}

	tests := []struct {
		name string
		args args
		want bool
	}{
		{
			name: "pass",
			args: args{expected: "text/plain", actual: "text/plain; charset=utf-8"},
			want: true,
		},
		{
			name: "fail",
			args: args{expected: "text/json", actual: "text/html; charset=utf-8"},
			want: false,
		},
	}

	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			require.Equal(t, tt.want, IsContentType(tt.args.expected, tt.args.actual))
		})
	}
}
