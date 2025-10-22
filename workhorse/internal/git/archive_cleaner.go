package git

import (
	"io/fs"
	"os"
	"path/filepath"
	"strings"
	"sync"
	"time"

	"gitlab.com/gitlab-org/gitlab/workhorse/internal/log"
)

const (
	// lastModifiedTimeMins is the oldest duration a file archive can be
	lastModifiedTimeMins = 120
	// scanPeriod is the period when the archive cleaner will run
	scanPeriod = time.Hour

	// For `/path/project-N/sha/@v2/archive.zip`, `find /path -maxdepth 4` will find this file
	maxArchiveDepth = 4
)

// archiveCleaner removes cached repository archives
// that are generated on-the-fly by Gitaly. These files are stored in the
// following form (as defined in lib/gitlab/git/repository.rb) and served
// by GitLab Workhorse:
//
// /path/to/repository/downloads/project-N/sha/@v2/archive.format
//
// Legacy paths omit the @v2 prefix.
//
// For example:
//
// /var/opt/gitlab/gitlab-rails/shared/cache/archive/project-1/master/@v2/archive.zip
type archiveCleaner struct {
	path     string
	enabled  bool
	shutdown chan struct{}
	mutex    sync.Mutex
}

func newArchiveCleaner() *archiveCleaner {
	return &archiveCleaner{shutdown: make(chan struct{})}
}

// RegisterPath registers the root storage path for the archive cache.
func (s *archiveCleaner) RegisterPath(path string) {
	s.mutex.Lock()
	defer s.mutex.Unlock()

	if path != "" {
		absPath, err := filepath.Abs(path)
		if err != nil {
			log.WithFields(log.Fields{"storage_path": path}).WithError(err).Error("archive cleaner unable to resolve path")
			return
		}
		path = absPath
	}

	switch s.path {
	case "":
		log.WithFields(log.Fields{"storage_path": path}).Info("archive cleaner path registered")
	case path:
		return
	default:
		log.WithFields(log.Fields{"old_path": s.path, "new_path": path}).Error("archive cleaner path already set")
		// Abort because this should have been set correctly the first time, and this avoids
		// having to worry about race conditions with the already-running Goroutine.
		if s.enabled {
			return
		}
	}

	s.path = path

	if !s.enabled && s.isValidPath() {
		log.Info("archive cleaner starting")
		s.enabled = true
		s.start()
	}
}

// Shutdown gracefully stops the archive cleaner.
func (s *archiveCleaner) Shutdown() {
	log.Info("archive cleaner: shutting down")

	s.mutex.Lock()
	defer s.mutex.Unlock()

	select {
	case <-s.shutdown:
		// already closed
	default:
		close(s.shutdown)
	}
}

func (s *archiveCleaner) isValidPath() bool {
	return s.path != "" && s.path != "/" && isDirectory(s.path)
}

func (s *archiveCleaner) start() {
	// Run Goroutine to clean up old archives
	go func() {
		ticker := time.NewTicker(scanPeriod)
		defer ticker.Stop()

		// Run once immediately
		s.execute()

		for {
			select {
			// Then run periodically
			case <-ticker.C:
				s.execute()
			case <-s.shutdown:
				// Received shutdown signal, exit the Goroutine
				return
			}
		}
	}()
}

func (s *archiveCleaner) execute() {
	s.cleanUpOldArchives()
	s.cleanUpEmptyDirectories()
}

// cleanUpOldArchives removes archive files older than the specified time.
func (s *archiveCleaner) cleanUpOldArchives() {
	cutoffTime := time.Now().Add(-time.Duration(lastModifiedTimeMins) * time.Minute)

	err := filepath.WalkDir(s.path, func(path string, d fs.DirEntry, err error) error {
		if err != nil {
			return nil
		}

		return s.cleanEntry(path, d, cutoffTime)
	})

	if err != nil {
		log.WithError(err).Error("error walking archive cleaner path")
	}
}

func (s *archiveCleaner) cleanEntry(path string, d fs.DirEntry, cutoffTime time.Time) error {
	if d.IsDir() {
		// Skip directories beyond our max depth
		relPath, err := filepath.Rel(s.path, path)
		if err != nil {
			return nil
		}

		// Count depth (empty string splits to 1 for root path)
		depth := len(strings.Split(relPath, string(os.PathSeparator)))
		if depth > maxArchiveDepth {
			return fs.SkipDir
		}

		return nil
	}

	// Process only archive files
	if isArchiveFile(path) {
		info, err := d.Info()
		if err != nil {
			return nil
		}

		// Delete if older than cutoff
		if info.ModTime().Before(cutoffTime) {
			log.WithFields(log.Fields{"path": path, "modified_time": info.ModTime()}).Info("Removing old archive")
			err := os.Remove(path)

			if err != nil {
				log.WithFields(log.Fields{"path": path, "error": err}).Error("failed to remove old archive")
			}
		}
	}

	return nil
}

// cleanUpEmptyDirectories removes empty directories starting from the deepest level.
func (s *archiveCleaner) cleanUpEmptyDirectories() {
	// We'll need to make multiple passes to handle nested empty directories
	for depth := maxArchiveDepth - 1; depth >= 1; depth-- {
		s.cleanUpEmptyDirectoriesWithDepth(depth)
	}
}

// cleanUpEmptyDirectoriesWithDepth removes empty directories at a specific depth.
func (s *archiveCleaner) cleanUpEmptyDirectoriesWithDepth(targetDepth int) {
	var dirsToCheck []string

	// First collect directories at the right depth
	err := filepath.WalkDir(s.path, func(path string, d fs.DirEntry, err error) error {
		if err != nil || !d.IsDir() {
			return nil
		}

		relPath, err := filepath.Rel(s.path, path)
		if err != nil {
			return nil
		}

		// Skip root directory
		if relPath == "." {
			return nil
		}

		// Count depth
		depth := len(strings.Split(relPath, string(os.PathSeparator)))
		if depth == targetDepth {
			dirsToCheck = append(dirsToCheck, path)
			return fs.SkipDir // Skip deeper directories
		} else if depth > targetDepth {
			return fs.SkipDir
		}

		return nil
	})

	if err != nil {
		log.WithError(err).Error("error walking archiveCleaner path for empty directories")
	}

	// Now check each directory and delete if empty
	for _, dir := range dirsToCheck {
		isEmpty, err := isDirEmpty(dir)
		if err == nil && isEmpty {
			log.WithFields(log.Fields{"path": dir}).Info("Removing empty directory")
			removeErr := os.Remove(dir)

			if removeErr != nil {
				log.WithFields(log.Fields{"path": dir}).WithError(err).Error("error removing directory")
			}
		}
	}
}

// isArchiveFile checks if a file has an archive extension.
func isArchiveFile(path string) bool {
	ext := strings.ToLower(filepath.Ext(path))
	switch ext {
	// Allowed formats: https://docs.gitlab.com/api/repositories/#get-file-archive
	// These get mapped to `Gitaly::GetArchiveRequest::Format` types (see lib/gitlab/workhorse.rb).
	case ".tar", ".bz2", ".zip":
		return true
	case ".gz":
		// Only accept .gz if it's .tar.gz
		return strings.HasSuffix(strings.ToLower(path), ".tar.gz")
	default:
		return false
	}
}

// isDirEmpty checks if a directory is empty.
func isDirEmpty(dir string) (bool, error) {
	f, err := os.Open(filepath.Clean(dir))
	if err != nil {
		return false, err
	}
	defer func() { _ = f.Close() }()

	_, err = f.Readdirnames(1)
	if err == nil {
		// Directory is not empty
		return false, nil
	}

	// Directory is empty if we got EOF
	return true, nil
}

func isDirectory(path string) bool {
	info, err := os.Stat(path)
	if err != nil {
		return false
	}
	return info.IsDir()
}
