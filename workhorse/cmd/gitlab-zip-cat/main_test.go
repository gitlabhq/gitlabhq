package main

import (
	"archive/zip"
	"bytes"
	"encoding/base64"
	"io"
	"os"
	"sync"
	"testing"
)

func TestRun(t *testing.T) {
	tests := createTestCases()

	for name, tt := range tests {
		t.Run(name, func(t *testing.T) {
			runTest(t, tt)
		})
	}
}

func createTestCases() map[string]struct {
	archiveContent          string
	fileName                string
	expectedOutput          string
	expectedError           string
	missingArchiveEnv       bool
	missingEncodingEnv      bool
	overrideEncodedFileName string
} {
	return map[string]struct {
		archiveContent          string
		fileName                string
		expectedOutput          string
		expectedError           string
		missingArchiveEnv       bool
		missingEncodingEnv      bool
		overrideEncodedFileName string
	}{
		"successful case": {
			archiveContent: "sample content",
			fileName:       "testfile.txt",
			expectedOutput: "14\nsample content",
			expectedError:  "",
		},
		"missing archive path": {
			archiveContent:    "sample content",
			fileName:          "testfile.txt",
			expectedOutput:    "",
			expectedError:     "usage: gitlab-zip-cat\nEnv: ARCHIVE_PATH=https://path.to/archive.zip or /path/to/archive.zip\nEnv: ENCODED_FILE_NAME=base64-encoded-file-name",
			missingArchiveEnv: true,
		},
		"missing encoding name": {
			archiveContent:     "sample content",
			fileName:           "testfile.txt",
			expectedOutput:     "",
			expectedError:      "usage: gitlab-zip-cat\nEnv: ARCHIVE_PATH=https://path.to/archive.zip or /path/to/archive.zip\nEnv: ENCODED_FILE_NAME=base64-encoded-file-name",
			missingEncodingEnv: true,
		},
	}
}

func runTest(t *testing.T, tt struct {
	archiveContent          string
	fileName                string
	expectedOutput          string
	expectedError           string
	missingArchiveEnv       bool
	missingEncodingEnv      bool
	overrideEncodedFileName string
}) {
	archivePath := createTempZipWithFile(tt.fileName, tt.archiveContent)
	encodedFileName := base64.StdEncoding.EncodeToString([]byte(tt.fileName))

	setupEnvironment(tt.missingArchiveEnv, tt.missingEncodingEnv, archivePath, tt.overrideEncodedFileName, encodedFileName)

	stdoutBuf, _, err := captureOutput(run)

	verifyResults(t, tt.expectedError, err, tt.expectedOutput, stdoutBuf)

	unsetEnvironment()
}

func setupEnvironment(missingArchiveEnv, missingEncodingEnv bool, archivePath, overrideEncodedFileName, encodedFileName string) {
	if !missingArchiveEnv {
		os.Setenv("ARCHIVE_PATH", archivePath)
	}
	if !missingEncodingEnv {
		if overrideEncodedFileName != "" {
			encodedFileName = base64.StdEncoding.EncodeToString([]byte(overrideEncodedFileName))
		}
		os.Setenv("ENCODED_FILE_NAME", encodedFileName)
	}
	os.Args = []string{"gitlab-zip-cat"}
}

func captureOutput(fn func() (error, error)) (stdoutBuf, stderrBuf bytes.Buffer, err error) {
	stdoutPipe, stdoutWriter, _ := os.Pipe()
	stderrPipe, stderrWriter, _ := os.Pipe()
	defer stdoutPipe.Close()
	defer stderrPipe.Close()

	oldStdout := os.Stdout
	oldStderr := os.Stderr
	os.Stdout = stdoutWriter
	os.Stderr = stderrWriter
	defer func() {
		os.Stdout = oldStdout
		os.Stderr = oldStderr
	}()

	wg := sync.WaitGroup{}
	wg.Add(2)

	go func() {
		defer wg.Done()
		io.Copy(&stdoutBuf, stdoutPipe)
	}()

	go func() {
		defer wg.Done()
		io.Copy(&stderrBuf, stderrPipe)
	}()

	err, _ = fn()

	stdoutWriter.Close()
	stderrWriter.Close()

	wg.Wait()

	return stdoutBuf, stderrBuf, err
}

func verifyResults(t *testing.T, expectedError string, err error, expectedOutput string, stdoutBuf bytes.Buffer) {
	if expectedError == "" && err != nil {
		t.Fatalf("Expected no error, got %v", err)
	}

	if got := stdoutBuf.String(); got != expectedOutput {
		t.Errorf("Expected %q, got %q", expectedOutput, got)
	}
}

func unsetEnvironment() {
	os.Unsetenv("ARCHIVE_PATH")
	os.Unsetenv("ENCODED_FILE_NAME")
}

func createTempZipWithFile(fileName, content string) string {
	zipFile, err := os.CreateTemp("", "test-archive-*.zip")
	if err != nil {
		panic(err)
	}
	defer zipFile.Close()

	archive := zip.NewWriter(zipFile)
	defer archive.Close()

	w, err := archive.Create(fileName)
	if err != nil {
		panic(err)
	}

	_, err = io.Copy(w, bytes.NewReader([]byte(content)))
	if err != nil {
		panic(err)
	}

	return zipFile.Name()
}
