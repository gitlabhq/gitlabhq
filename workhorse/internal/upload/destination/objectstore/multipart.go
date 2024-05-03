package objectstore

import (
	"bytes"
	"context"
	"encoding/xml"
	"errors"
	"fmt"
	"io"
	"net/http"
	"os"

	"gitlab.com/gitlab-org/labkit/mask"

	"gitlab.com/gitlab-org/gitlab/workhorse/internal/upload/destination/objectstore/s3api"
)

// ErrNotEnoughParts will be used when writing more than size * len(partURLs)
var ErrNotEnoughParts = errors.New("not enough Parts")

// Multipart represents a MultipartUpload on a S3 compatible Object Store service.
// It can be used as io.WriteCloser for uploading an object
type Multipart struct {
	PartURLs []string
	// CompleteURL is a presigned URL for CompleteMultipartUpload
	CompleteURL string
	// AbortURL is a presigned URL for AbortMultipartUpload
	AbortURL string
	// DeleteURL is a presigned URL for RemoveObject
	DeleteURL  string
	PutHeaders map[string]string
	partSize   int64
	etag       string

	*uploader
}

// NewMultipart provides Multipart pointer that can be used for uploading. Data written will be split buffered on disk up to size bytes
// then uploaded with S3 Upload Part. Once Multipart is Closed a final call to CompleteMultipartUpload will be sent.
// In case of any error a call to AbortMultipartUpload will be made to cleanup all the resources
func NewMultipart(partURLs []string, completeURL, abortURL, deleteURL string, putHeaders map[string]string, partSize int64) (*Multipart, error) {
	m := &Multipart{
		PartURLs:    partURLs,
		CompleteURL: completeURL,
		AbortURL:    abortURL,
		DeleteURL:   deleteURL,
		PutHeaders:  putHeaders,
		partSize:    partSize,
	}

	m.uploader = newUploader(m)
	return m, nil
}

// Upload uploads the multipart content using the provided reader.
func (m *Multipart) Upload(ctx context.Context, r io.Reader) error {
	cmu := &s3api.CompleteMultipartUpload{}
	for i, partURL := range m.PartURLs {
		src := io.LimitReader(r, m.partSize)
		part, err := m.readAndUploadOnePart(ctx, partURL, m.PutHeaders, src, i+1)
		if err != nil {
			return err
		}
		if part == nil {
			break
		}
		cmu.Part = append(cmu.Part, part)
	}

	n, err := io.Copy(io.Discard, r)
	if err != nil {
		return fmt.Errorf("drain pipe: %v", err)
	}
	if n > 0 {
		return ErrNotEnoughParts
	}

	if err := m.complete(ctx, cmu); err != nil {
		return err
	}

	return nil
}

// ETag returns the ETag of the multipart upload.
func (m *Multipart) ETag() string {
	return m.etag
}

// Abort aborts the multipart upload by sending a DELETE request to the AbortURL.
func (m *Multipart) Abort() {
	deleteURL(m.AbortURL)
}

// Delete deletes the multipart upload by sending a DELETE request to the DeleteURL.
func (m *Multipart) Delete() {
	deleteURL(m.DeleteURL)
}

func (m *Multipart) readAndUploadOnePart(ctx context.Context, partURL string, putHeaders map[string]string, src io.Reader, partNumber int) (*s3api.CompleteMultipartUploadPart, error) {
	file, err := os.CreateTemp("", "part-buffer")
	if err != nil {
		return nil, fmt.Errorf("create temporary buffer file: %v", err)
	}
	defer func() { _ = file.Close() }()

	if err = os.Remove(file.Name()); err != nil {
		return nil, fmt.Errorf("remove temporary buffer file: %v", err)
	}

	n, err := io.Copy(file, src)
	if err != nil {
		return nil, fmt.Errorf("copy to temporary buffer file: %v", err)
	}
	if n == 0 {
		return nil, nil
	}

	if _, err = file.Seek(0, io.SeekStart); err != nil {
		return nil, fmt.Errorf("rewind part %d temporary dump : %v", partNumber, err)
	}

	etag, err := m.uploadPart(ctx, partURL, putHeaders, file, n)
	if err != nil {
		return nil, fmt.Errorf("upload part %d: %v", partNumber, err)
	}
	return &s3api.CompleteMultipartUploadPart{PartNumber: partNumber, ETag: etag}, nil
}

func (m *Multipart) uploadPart(ctx context.Context, url string, headers map[string]string, body io.Reader, size int64) (string, error) {
	deadline, ok := ctx.Deadline()
	if !ok {
		return "", fmt.Errorf("missing deadline")
	}

	part, err := newObject(url, "", headers, size, false)
	if err != nil {
		return "", err
	}

	if n, err := part.Consume(ctx, io.LimitReader(body, size), deadline); err != nil || n < size {
		if err == nil {
			err = io.ErrUnexpectedEOF
		}
		return "", err
	}

	return part.ETag(), nil
}

func (m *Multipart) complete(ctx context.Context, cmu *s3api.CompleteMultipartUpload) error {
	body, err := xml.Marshal(cmu)
	if err != nil {
		return fmt.Errorf("marshal CompleteMultipartUpload request: %v", err)
	}

	req, err := http.NewRequest("POST", m.CompleteURL, bytes.NewReader(body))
	if err != nil {
		return fmt.Errorf("create CompleteMultipartUpload request: %v", err)
	}
	req.ContentLength = int64(len(body))
	req.Header.Set("Content-Type", "application/xml")
	req = req.WithContext(ctx)

	resp, err := httpClient.Do(req)
	if err != nil {
		return fmt.Errorf("CompleteMultipartUpload request %q: %v", mask.URL(m.CompleteURL), err)
	}
	defer func() { _ = resp.Body.Close() }()

	if resp.StatusCode != http.StatusOK {
		return fmt.Errorf("CompleteMultipartUpload request %v returned: %s", mask.URL(m.CompleteURL), resp.Status)
	}

	result := &compoundCompleteMultipartUploadResult{}
	decoder := xml.NewDecoder(resp.Body)
	if err := decoder.Decode(&result); err != nil {
		return fmt.Errorf("decode CompleteMultipartUpload answer: %v", err)
	}

	if result.isError() {
		return result
	}

	if result.CompleteMultipartUploadResult == nil {
		return fmt.Errorf("empty CompleteMultipartUploadResult")
	}

	m.etag = extractETag(result.ETag)

	return nil
}
