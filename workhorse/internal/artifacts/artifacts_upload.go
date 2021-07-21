package artifacts

import (
	"context"
	"fmt"
	"io"
	"mime/multipart"
	"net/http"
	"os"
	"os/exec"
	"strings"
	"syscall"

	"github.com/prometheus/client_golang/prometheus"
	"github.com/prometheus/client_golang/prometheus/promauto"
	"gitlab.com/gitlab-org/labkit/log"

	"gitlab.com/gitlab-org/gitlab/workhorse/internal/api"
	"gitlab.com/gitlab-org/gitlab/workhorse/internal/filestore"
	"gitlab.com/gitlab-org/gitlab/workhorse/internal/helper"
	"gitlab.com/gitlab-org/gitlab/workhorse/internal/upload"
	"gitlab.com/gitlab-org/gitlab/workhorse/internal/zipartifacts"
)

// Sent by the runner: https://gitlab.com/gitlab-org/gitlab-runner/blob/c24da19ecce8808d9d2950896f70c94f5ea1cc2e/network/gitlab.go#L580
const (
	ArtifactFormatKey     = "artifact_format"
	ArtifactFormatZip     = "zip"
	ArtifactFormatDefault = ""
)

var zipSubcommandsErrorsCounter = promauto.NewCounterVec(
	prometheus.CounterOpts{
		Name: "gitlab_workhorse_zip_subcommand_errors_total",
		Help: "Errors comming from subcommands used for processing ZIP archives",
	}, []string{"error"})

type artifactsUploadProcessor struct {
	opts   *filestore.SaveFileOpts
	format string

	upload.SavedFileTracker
}

func (a *artifactsUploadProcessor) generateMetadataFromZip(ctx context.Context, file *filestore.FileHandler) (*filestore.FileHandler, error) {
	metaReader, metaWriter := io.Pipe()
	defer metaWriter.Close()

	metaOpts := &filestore.SaveFileOpts{
		LocalTempPath:  a.opts.LocalTempPath,
		TempFilePrefix: "metadata.gz",
	}
	if metaOpts.LocalTempPath == "" {
		metaOpts.LocalTempPath = os.TempDir()
	}

	fileName := file.LocalPath
	if fileName == "" {
		fileName = file.RemoteURL
	}

	zipMd := exec.CommandContext(ctx, "gitlab-zip-metadata", fileName)
	zipMd.Stderr = log.ContextLogger(ctx).Writer()
	zipMd.SysProcAttr = &syscall.SysProcAttr{Setpgid: true}
	zipMd.Stdout = metaWriter

	if err := zipMd.Start(); err != nil {
		return nil, err
	}
	defer helper.CleanUpProcessGroup(zipMd)

	type saveResult struct {
		error
		*filestore.FileHandler
	}
	done := make(chan saveResult)
	go func() {
		var result saveResult
		result.FileHandler, result.error = filestore.SaveFileFromReader(ctx, metaReader, -1, metaOpts)

		done <- result
	}()

	if err := zipMd.Wait(); err != nil {
		st, ok := helper.ExitStatus(err)

		if !ok {
			return nil, err
		}

		zipSubcommandsErrorsCounter.WithLabelValues(zipartifacts.ErrorLabelByCode(st)).Inc()

		if st == zipartifacts.CodeNotZip {
			return nil, nil
		}

		if st == zipartifacts.CodeLimitsReached {
			return nil, zipartifacts.ErrBadMetadata
		}
	}

	metaWriter.Close()
	result := <-done
	return result.FileHandler, result.error
}

func (a *artifactsUploadProcessor) ProcessFile(ctx context.Context, formName string, file *filestore.FileHandler, writer *multipart.Writer) error {
	//  ProcessFile for artifacts requires file form-data field name to eq `file`

	if formName != "file" {
		return fmt.Errorf("invalid form field: %q", formName)
	}
	if a.Count() > 0 {
		return fmt.Errorf("artifacts request contains more than one file")
	}
	a.Track(formName, file.LocalPath)

	select {
	case <-ctx.Done():
		return fmt.Errorf("ProcessFile: context done")
	default:
	}

	if !strings.EqualFold(a.format, ArtifactFormatZip) && a.format != ArtifactFormatDefault {
		return nil
	}

	// TODO: can we rely on disk for shipping metadata? Not if we split workhorse and rails in 2 different PODs
	metadata, err := a.generateMetadataFromZip(ctx, file)
	if err != nil {
		return err
	}

	if metadata != nil {
		fields, err := metadata.GitLabFinalizeFields("metadata")
		if err != nil {
			return fmt.Errorf("finalize metadata field error: %v", err)
		}

		for k, v := range fields {
			writer.WriteField(k, v)
		}

		a.Track("metadata", metadata.LocalPath)
	}

	return nil
}

func (a *artifactsUploadProcessor) Name() string {
	return "artifacts"
}

func UploadArtifacts(myAPI *api.API, h http.Handler, p upload.Preparer) http.Handler {
	return myAPI.PreAuthorizeHandler(func(w http.ResponseWriter, r *http.Request, a *api.Response) {
		opts, _, err := p.Prepare(a)
		if err != nil {
			helper.Fail500(w, r, fmt.Errorf("UploadArtifacts: error preparing file storage options"))
			return
		}

		format := r.URL.Query().Get(ArtifactFormatKey)

		mg := &artifactsUploadProcessor{opts: opts, format: format, SavedFileTracker: upload.SavedFileTracker{Request: r}}
		upload.HandleFileUploads(w, r, h, a, mg, opts)
	}, "/authorize")
}
