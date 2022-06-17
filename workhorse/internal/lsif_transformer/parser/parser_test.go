package parser

import (
	"archive/zip"
	"bytes"
	"context"
	"encoding/json"
	"io"
	"os"
	"path/filepath"
	"testing"

	"github.com/stretchr/testify/require"
)

func TestGenerate(t *testing.T) {
	filePath := "testdata/dump.lsif.zip"
	tmpDir := filePath + ".tmp"
	defer os.RemoveAll(tmpDir)

	createFiles(t, filePath, tmpDir)

	verifyCorrectnessOf(t, tmpDir, "lsif/main.go.json")
	verifyCorrectnessOf(t, tmpDir, "lsif/morestrings/reverse.go.json")
}

func verifyCorrectnessOf(t *testing.T, tmpDir, fileName string) {
	file, err := os.ReadFile(filepath.Join(tmpDir, fileName))
	require.NoError(t, err)

	var buf bytes.Buffer
	require.NoError(t, json.Indent(&buf, file, "", "    "))

	expected, err := os.ReadFile(filepath.Join("testdata/expected/", fileName))
	require.NoError(t, err)

	require.Equal(t, string(expected), buf.String())
}

func createFiles(t *testing.T, filePath, tmpDir string) {
	t.Helper()
	file, err := os.Open(filePath)
	require.NoError(t, err)

	parser, err := NewParser(context.Background(), file)
	require.NoError(t, err)

	zipFileName := tmpDir + ".zip"
	w, err := os.Create(zipFileName)
	require.NoError(t, err)
	defer os.RemoveAll(zipFileName)

	_, err = io.Copy(w, parser)
	require.NoError(t, err)
	require.NoError(t, parser.Close())

	extractZipFiles(t, tmpDir, zipFileName)
}

func extractZipFiles(t *testing.T, tmpDir, zipFileName string) {
	zipReader, err := zip.OpenReader(zipFileName)
	require.NoError(t, err)

	for _, file := range zipReader.Reader.File {
		zippedFile, err := file.Open()
		require.NoError(t, err)
		defer zippedFile.Close()

		fileDir, fileName := filepath.Split(file.Name)
		require.NoError(t, os.MkdirAll(filepath.Join(tmpDir, fileDir), os.ModePerm))

		outputFile, err := os.Create(filepath.Join(tmpDir, fileDir, fileName))
		require.NoError(t, err)
		defer outputFile.Close()

		_, err = io.Copy(outputFile, zippedFile)
		require.NoError(t, err)
	}
}
