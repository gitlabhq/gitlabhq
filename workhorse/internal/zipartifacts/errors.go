package zipartifacts

import (
	"errors"
)

// These are exit codes used by subprocesses in cmd/gitlab-zip-xxx. We also use
// them to map errors and error messages that we use as label in Prometheus.
const (
	CodeNotZip = 10 + iota
	CodeEntryNotFound
	CodeArchiveNotFound
	CodeLimitsReached
	CodeUnknownError
)

var (
	// ErrorCode maps integer error codes to corresponding error messages.
	ErrorCode = map[int]error{
		CodeNotZip:          errors.New("zip archive format invalid"),
		CodeEntryNotFound:   errors.New("zip entry not found"),
		CodeArchiveNotFound: errors.New("zip archive not found"),
		CodeLimitsReached:   errors.New("zip processing limits reached"),
		CodeUnknownError:    errors.New("zip processing unknown error"),
	}

	// ErrorLabel maps integer error codes to corresponding error labels.
	ErrorLabel = map[int]string{
		CodeNotZip:          "archive_invalid",
		CodeEntryNotFound:   "entry_not_found",
		CodeArchiveNotFound: "archive_not_found",
		CodeLimitsReached:   "limits_reached",
		CodeUnknownError:    "unknown_error",
	}

	// ErrBadMetadata represents an error indicating that the zip artifacts metadata is invalid.
	ErrBadMetadata = errors.New("zip artifacts metadata invalid")
)

// ExitCodeByError find an os.Exit code for a corresponding error.
// CodeUnkownError in case it can not be found.
func ExitCodeByError(err error) int {
	for c, e := range ErrorCode {
		if err == e {
			return c
		}
	}

	return CodeUnknownError
}

// ErrorLabelByCode returns a Prometheus counter label associated with an exit code.
func ErrorLabelByCode(code int) string {
	label, ok := ErrorLabel[code]
	if ok {
		return label
	}

	return ErrorLabel[CodeUnknownError]
}
