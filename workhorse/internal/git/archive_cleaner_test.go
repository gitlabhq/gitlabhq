package git

import (
	"os"
	"path/filepath"
	"testing"
	"time"

	"github.com/stretchr/testify/assert"
	"github.com/stretchr/testify/require"
)

func TestRegisterPath(t *testing.T) {
	// Create a temporary test directory
	testDir, err := os.MkdirTemp("", "archive-cleaner-test")
	require.NoError(t, err, "Failed to create test directory")
	defer os.RemoveAll(testDir)

	// Create a new archive cleaner
	cleaner := newArchiveCleaner()
	defer cleaner.Shutdown()
	cleaner.RegisterPath(testDir)

	assert.Equal(t, testDir, cleaner.path, "Path should match registered path")
	assert.True(t, cleaner.enabled, "Cleaner should be enabled")
}

func TestRegisterUncleanPath(t *testing.T) {
	// Create a temporary test directory
	testDir, err := os.MkdirTemp("", "archive-cleaner-test")
	require.NoError(t, err, "Failed to create test directory")
	defer os.RemoveAll(testDir)

	// Create a new archive cleaner
	cleaner := newArchiveCleaner()
	defer cleaner.Shutdown()

	baseName := filepath.Base(testDir)
	path := testDir + "/../" + baseName

	cleaner.RegisterPath(path)

	assert.Equal(t, testDir, cleaner.path, "Path should match clean path")
	assert.True(t, cleaner.enabled, "Cleaner should be enabled")
}

func TestRegisterPathInvalid(t *testing.T) {
	// Empty path
	c := newArchiveCleaner()
	c.RegisterPath("")
	assert.False(t, c.enabled, "Cleaner should not be enabled with empty path")
	c.Shutdown()

	// Root path
	c = newArchiveCleaner()
	c.RegisterPath("/")
	assert.False(t, c.enabled, "Cleaner should not be enabled with root path")
	c.Shutdown()
}

func TestRegisterPathDuplicateCalls(t *testing.T) {
	// Create a temporary test directory
	testDir, err := os.MkdirTemp("", "archive-cleaner-test")
	require.NoError(t, err, "Failed to create test directory")
	defer os.RemoveAll(testDir)

	c := newArchiveCleaner()

	c.RegisterPath(testDir)
	c.RegisterPath(testDir) // Should log but not error

	// Test registering a different path
	otherDir, err := os.MkdirTemp("", "other-dir")
	require.NoError(t, err, "Failed to create other test directory")
	defer os.RemoveAll(otherDir)

	// This should log an error but not panic
	c.RegisterPath(otherDir)
	assert.Equal(t, testDir, c.path)
}

func TestCleanUpOldArchives(t *testing.T) {
	// Create a temporary test directory
	testDir, err := os.MkdirTemp("", "archive-cleaner-test")
	require.NoError(t, err, "Failed to create test directory")
	defer os.RemoveAll(testDir)

	// Create test archive file structure:
	// testDir/
	//   project-1/
	//     master/
	//       @v2/
	//         old-archive.zip (old - should be deleted)
	//         new-archive.zip (new - should be kept)

	// Create directory structure
	projectDir := filepath.Join(testDir, "project-1")
	masterDir := filepath.Join(projectDir, "master")
	v2Dir := filepath.Join(masterDir, "@v2")

	createDirs(t, projectDir, masterDir, v2Dir)

	// Create old file (should be deleted)
	oldFilePath := filepath.Join(v2Dir, "old-archive.zip")
	createFile(t, oldFilePath)

	// Set old file's modification time to be older than the cutoff
	oldTime := time.Now().Add(-time.Duration(lastModifiedTimeMins+10) * time.Minute)
	err = os.Chtimes(oldFilePath, oldTime, oldTime)
	require.NoError(t, err, "Failed to set old file time")

	// Create new file (should be kept)
	newFilePath := filepath.Join(v2Dir, "new-archive.zip")
	createFile(t, newFilePath)

	// Create a non-archive file (should be kept)
	nonArchivePath := filepath.Join(v2Dir, "readme.txt")
	createFile(t, nonArchivePath)

	// Run the cleaner
	c := newArchiveCleaner()
	defer c.Shutdown()

	c.RegisterPath(testDir)
	c.execute()

	// Check if old file was deleted
	assert.False(t, fileExists(oldFilePath), "Old archive file should be deleted")

	// Check if new file was kept
	assert.True(t, fileExists(newFilePath), "New archive file should be kept")

	// Check if non-archive file was kept
	assert.True(t, fileExists(nonArchivePath), "Non-archive file should be kept")
}

func TestCleanUpEmptyDirectories(t *testing.T) {
	// Create a temporary test directory
	testDir, err := os.MkdirTemp("", "archive-cleaner-test")
	require.NoError(t, err, "Failed to create test directory")
	defer os.RemoveAll(testDir)

	// Create test directory structure:
	// testDir/
	//   empty1/         (should be deleted)
	//   empty2/
	//     empty3/       (should be deleted first, then empty2)
	//   nonempty1/
	//     file.txt      (should be kept along with its directory)

	// Create directories
	empty1Dir := filepath.Join(testDir, "empty1")
	empty2Dir := filepath.Join(testDir, "empty2")
	empty3Dir := filepath.Join(empty2Dir, "empty3")
	nonempty1Dir := filepath.Join(testDir, "nonempty1")

	createDirs(t, empty1Dir, empty2Dir, empty3Dir, nonempty1Dir)

	// Create a file in nonempty1
	nonEmptyFilePath := filepath.Join(nonempty1Dir, "file.txt")
	createFile(t, nonEmptyFilePath)

	// Run the cleaner
	c := newArchiveCleaner()
	c.Shutdown()

	c.RegisterPath(testDir)
	c.execute()

	// Check if empty directories were deleted
	assert.False(t, dirExists(empty3Dir), "Empty directory should be deleted: %s", empty3Dir)
	assert.False(t, dirExists(empty2Dir), "Empty directory should be deleted: %s", empty2Dir)
	assert.False(t, dirExists(empty1Dir), "Empty directory should be deleted: %s", empty1Dir)

	// Check if non-empty directory was kept
	assert.True(t, dirExists(nonempty1Dir), "Non-empty directory should be kept")

	// Check if file in non-empty directory was kept
	assert.True(t, fileExists(nonEmptyFilePath), "File in non-empty directory should be kept")
}

func TestIsArchiveFile(t *testing.T) {
	tests := []struct {
		path     string
		expected bool
	}{
		{"file.zip", true},
		{"file.tar", true},
		{"file.tar.gz", true},
		{"file.tgz", false},
		{"file.gz", false},
		{"file.tar.bz2", true},
		{"file.tbz", false},
		{"file.tbz2", false},
		{"file.tb2", false},
		{"file.bz2", true},
		{"file.txt", false},
		{"file.zip.txt", false},
		{"archive.ZIP", true}, // Should be case insensitive
		{"archive.TAR.GZ", true},
	}

	for _, test := range tests {
		t.Run(test.path, func(t *testing.T) {
			result := isArchiveFile(test.path)
			assert.Equal(t, test.expected, result, "For %s, expected %v but got %v", test.path, test.expected, result)
		})
	}
}

func createDirs(t *testing.T, dirs ...string) {
	for _, dir := range dirs {
		err := os.MkdirAll(dir, 0755)
		require.NoError(t, err, "Failed to create directory %s", dir)
	}
}

func createFile(t *testing.T, path string) {
	err := os.WriteFile(path, []byte("test content"), 0644)
	require.NoError(t, err, "Failed to create file %s", path)
}

func fileExists(path string) bool {
	info, err := os.Stat(path)
	if os.IsNotExist(err) {
		return false
	}
	return !info.IsDir()
}

func dirExists(path string) bool {
	info, err := os.Stat(path)
	if os.IsNotExist(err) {
		return false
	}
	return info.IsDir()
}
