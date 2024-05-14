package secret

import (
	"crypto/rand"
	"encoding/base64"
	"os"
	"testing"

	"github.com/stretchr/testify/require"
)

func TestSetPath(t *testing.T) {
	SetPath("/tmp/secret")
	require.Equal(t, "/tmp/secret", theSecret.path)
}

func TestGetBytes(t *testing.T) {
	SetPath("/tmp/secret")
	bytes := []byte("secret")
	theSecret.bytes = bytes

	result := getBytes()
	require.Equal(t, bytes, result)
}

func TestCopyBytes(t *testing.T) {
	bytes := []byte("secret")

	result := copyBytes(bytes)
	require.Equal(t, bytes, result)
	require.NotSame(t, bytes, result)
}

func TestSetBytes(t *testing.T) {
	tempFile, err := os.CreateTemp(t.TempDir(), "secret_test")
	require.NoError(t, err)
	defer os.Remove(tempFile.Name())

	secretBytes := make([]byte, 32)
	_, err = rand.Read(secretBytes)
	require.NoError(t, err)

	encodedSecret := base64.StdEncoding.EncodeToString(secretBytes)
	_, err = tempFile.WriteString(encodedSecret)
	require.NoError(t, err)
	SetPath(tempFile.Name())

	bytes, err := setBytes()
	require.NoError(t, err)
	require.Len(t, bytes, 33)
}
