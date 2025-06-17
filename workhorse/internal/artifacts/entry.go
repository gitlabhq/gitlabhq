// Package artifacts provides functionality for managing artifacts.
package artifacts

import (
	"bufio"
	"context"
	"fmt"
	"io"
	"mime"
	"net/http"
	"os"
	"os/exec"
	"path/filepath"
	"strconv"
	"strings"
	"syscall"

	"gitlab.com/gitlab-org/labkit/log"
	"gitlab.com/gitlab-org/labkit/mask"

	"gitlab.com/gitlab-org/gitlab/workhorse/internal/helper"

	"gitlab.com/gitlab-org/gitlab/workhorse/internal/metrics"

	"gitlab.com/gitlab-org/gitlab/workhorse/internal/helper/command"
	"gitlab.com/gitlab-org/gitlab/workhorse/internal/helper/fail"
	"gitlab.com/gitlab-org/gitlab/workhorse/internal/senddata"
	"gitlab.com/gitlab-org/gitlab/workhorse/internal/zipartifacts"
)

type entry struct{ senddata.Prefix }
type entryParams struct{ Archive, Entry string }

// SendEntry is a predefined entry used for sending artifacts.
var SendEntry = &entry{"artifacts-entry:"}

// Artifacts downloader doesn't support ranges when downloading a single file
func (e *entry) Inject(w http.ResponseWriter, r *http.Request, sendData string) {
	var params entryParams
	if err := e.Unpack(&params, sendData); err != nil {
		fail.Request(w, r, fmt.Errorf("SendEntry: unpack sendData: %v", err))
		return
	}

	if helper.IsURL(params.Archive) {
		// Get the tracker from context and set flags
		if tracker, ok := metrics.FromContext(r.Context()); ok {
			tracker.SetFlag(metrics.KeyFetchedExternalURL, strconv.FormatBool(true))
		}
	}

	log.WithContextFields(r.Context(), log.Fields{
		"entry":   params.Entry,
		"archive": mask.URL(params.Archive),
		"path":    r.URL.Path,
	}).Print("SendEntry: sending")

	if params.Archive == "" || params.Entry == "" {
		fail.Request(w, r, fmt.Errorf("SendEntry: Archive or Entry is empty"))
		return
	}

	err := unpackFileFromZip(r.Context(), params.Archive, params.Entry, w.Header(), w)

	if os.IsNotExist(err) {
		http.NotFound(w, r)
	} else if err != nil {
		fail.Request(w, r, fmt.Errorf("SendEntry: %v", err))
	}
}

func detectFileContentType(fileName string) string {
	contentType := mime.TypeByExtension(filepath.Ext(fileName))
	if contentType == "" {
		contentType = "application/octet-stream"
	}
	return contentType
}

func unpackFileFromZip(ctx context.Context, archivePath, encodedFilename string, headers http.Header, output io.Writer) error {
	fileName, err := zipartifacts.DecodeFileEntry(encodedFilename)
	if err != nil {
		return err
	}

	logWriter := log.ContextLogger(ctx).Writer()
	defer func() {
		if closeErr := logWriter.Close(); closeErr != nil {
			log.ContextLogger(ctx).WithError(closeErr).Error("failed to close gitlab-zip-cat log writer")
		}
	}()

	catFile := exec.Command("gitlab-zip-cat")
	catFile.Env = append(os.Environ(),
		"ARCHIVE_PATH="+archivePath,
		"ENCODED_FILE_NAME="+encodedFilename,
	)
	catFile.Stderr = logWriter
	catFile.SysProcAttr = &syscall.SysProcAttr{Setpgid: true}
	stdout, err := catFile.StdoutPipe()
	if err != nil {
		return fmt.Errorf("create gitlab-zip-cat stdout pipe: %v", err)
	}

	if err = catFile.Start(); err != nil {
		return fmt.Errorf("start %v: %v", catFile.Args, err)
	}
	defer func() {
		if err = command.KillProcessGroup(catFile); err != nil {
			fmt.Printf("failed to kill process group: %v\n", err)
		}
	}()

	basename := filepath.Base(fileName)
	reader := bufio.NewReader(stdout)
	contentLength, err := reader.ReadString('\n')
	if err != nil {
		if catFileErr := waitCatFile(catFile); catFileErr != nil {
			return catFileErr
		}
		return fmt.Errorf("read content-length: %v", err)
	}
	contentLength = strings.TrimSuffix(contentLength, "\n")

	// Write http headers about the file
	headers.Set("Content-Length", contentLength)
	headers.Set("Content-Type", detectFileContentType(fileName))
	headers.Set("Content-Disposition", "attachment; filename=\""+escapeQuotes(basename)+"\"")
	// Copy file body to client
	if _, err := io.Copy(output, reader); err != nil {
		return fmt.Errorf("copy stdout of %v: %v", catFile.Args, err)
	}

	return waitCatFile(catFile)
}

func waitCatFile(cmd *exec.Cmd) error {
	err := cmd.Wait()
	if err == nil {
		return nil
	}

	st, ok := command.ExitStatus(err)
	if ok && (st == zipartifacts.CodeArchiveNotFound || st == zipartifacts.CodeEntryNotFound) {
		return os.ErrNotExist
	}
	return fmt.Errorf("wait for %v to finish: %v", cmd.Args, err)
}
