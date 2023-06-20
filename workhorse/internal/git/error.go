package git

import (
	"errors"
	"fmt"
	"io"

	"gitlab.com/gitlab-org/gitaly/v16/proto/go/gitalypb"
	"google.golang.org/grpc/status"

	"gitlab.com/gitlab-org/gitlab/workhorse/internal/log"
)

// For unwrapping google.golang.org/grpc/internal/status.Error
type grpcErr interface {
	GRPCStatus() *status.Status
	Error() string
}

// For cosmetic purposes in Sentry
type copyError struct{ error }

// handleLimitErr handles errors that come back from Gitaly that may be a
// LimitError. A LimitError is returned by Gitaly when it is at its limit in
// handling requests. Since this is a known error, we should print a sensible
// error message to the end user.
func handleLimitErr(err error, w io.Writer, f func(w io.Writer) error) {
	var statusErr grpcErr
	if !errors.As(err, &statusErr) {
		return
	}

	if st, ok := status.FromError(statusErr); ok {
		details := st.Details()
		for _, detail := range details {
			switch detail.(type) {
			case *gitalypb.LimitError:
				if err := f(w); err != nil {
					log.WithError(fmt.Errorf("handling limit error: %w", err))
				}
			}
		}
	}
}

// writeReceivePackError writes a "server is busy" error message to the
// git-receive-pack-result.
//
// 0023\x01001aunpack server is busy
// 00000044\x2GitLab is currently unable to handle this request due to load.
// 0000
//
// We write a line reporting that unpack failed, and then provide some progress
// information through the side-band 2 channel.
// See https://gitlab.com/gitlab-org/gitaly/-/tree/jc-return-structured-error-limits
// for more details.
func writeReceivePackError(w io.Writer) error {
	if _, err := fmt.Fprintf(w, "%04x", 35); err != nil {
		return err
	}

	if _, err := w.Write([]byte{0x01}); err != nil {
		return err
	}

	if _, err := fmt.Fprintf(w, "%04xunpack server is busy\n", 26); err != nil {
		return err
	}

	if _, err := w.Write([]byte("0000")); err != nil {
		return err
	}

	if _, err := fmt.Fprintf(w, "%04x", 68); err != nil {
		return err
	}

	if _, err := w.Write([]byte{0x2}); err != nil {
		return err
	}

	if _, err := fmt.Fprint(w, "GitLab is currently unable to handle this request due to load.\n"); err != nil {
		return err
	}

	if _, err := w.Write([]byte("0000")); err != nil {
		return err
	}

	return nil
}

// writeUploadPackError writes a "server is busy" error message that git
// understands and prints to stdout. UploadPack expects to receive pack data in
// PKT-LINE format. An error-line can be passed that begins with ERR.
// See https://git-scm.com/docs/pack-protocol/2.29.0#_pkt_line_format.
func writeUploadPackError(w io.Writer) error {
	_, err := fmt.Fprintf(w, "%04xERR GitLab is currently unable to handle this request due to load.\n", 71)
	return err
}
