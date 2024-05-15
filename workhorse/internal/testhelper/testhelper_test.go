package testhelper

import (
	"bytes"
	"net/http/httptest"
	"os"
	"path"
	"testing"

	"github.com/golang-jwt/jwt/v5"
	"github.com/stretchr/testify/require"
)

func TestRequireResponseBody(t *testing.T) {
	response := httptest.NewRecorder()
	response.WriteString("Hello, World!")

	RequireResponseBody(t, response, "Hello, World!")
}

func TestParseJWT(t *testing.T) {
	token := jwt.New(jwt.SigningMethodHS256)
	token.Header["alg"] = "HS256"

	secretBytes, err := ParseJWT(token)
	require.NoError(t, err, "unexpected error while parsing JWT")
	require.NotNil(t, secretBytes, "secret bytes should not be nil")
}

func TestBuildExecutables(t *testing.T) {
	originalPath := os.Getenv("PATH")
	require.NoError(t, os.Setenv("PATH", originalPath))

	rootDir := RootDir()
	err := BuildExecutables()
	require.NoError(t, err, "unexpected error while building executables")

	updatedPath := os.Getenv("PATH")
	expectedPath := rootDir + ":" + originalPath
	require.Equal(t, expectedPath, updatedPath, "PATH environment variable should be updated")
}

func TestTempDir(t *testing.T) {
	tmpDir := TempDir(t)

	_, err := os.Stat(tmpDir)
	require.NoError(t, err, "temporary directory should exist")

	err = os.RemoveAll(tmpDir)
	require.NoError(t, err, "failed to remove temporary directory")
}

func TestReadAll(t *testing.T) {
	content := []byte("This is a test content.")
	reader := bytes.NewReader(content)

	result := ReadAll(t, reader)
	require.Equal(t, content, result, "result does not match original content")
}

func TestSetupStaticFileHelper(t *testing.T) {
	fpath := "testfile.txt"
	content := "Hello, World!"
	directory := "testdir"

	absDocumentRoot := SetupStaticFileHelper(t, fpath, content, directory)
	_, err := os.Stat(absDocumentRoot)
	require.NoError(t, err, "document root directory should exist")

	staticFile := path.Join(absDocumentRoot, fpath)
	fileContent, err := os.ReadFile(staticFile)
	require.NoError(t, err, "failed to read file content")
	require.Equal(t, content, string(fileContent), "file content does not match")
	require.NoError(t, os.RemoveAll(absDocumentRoot), "failed to remove document root directory")
}
