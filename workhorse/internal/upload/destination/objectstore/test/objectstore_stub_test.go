package test

import (
	"context"
	"fmt"
	"io"
	"net/http"
	"strings"
	"testing"

	"github.com/stretchr/testify/require"
)

func doRequest(method, url string, body io.Reader) error {
	req, err := http.NewRequest(method, url, body)
	if err != nil {
		return err
	}

	resp, err := http.DefaultClient.Do(req)
	if err != nil {
		return err
	}

	return resp.Body.Close()
}

func TestObjectStoreStub(t *testing.T) {
	stub, ts := StartObjectStore()
	defer ts.Close()

	require.Equal(t, 0, stub.PutsCnt())
	require.Equal(t, 0, stub.DeletesCnt())

	objectURL := ts.URL + ObjectPath

	require.NoError(t, doRequest(http.MethodPut, objectURL, strings.NewReader(ObjectContent)))

	require.Equal(t, 1, stub.PutsCnt())
	require.Equal(t, 0, stub.DeletesCnt())
	require.Equal(t, ObjectMD5, stub.GetObjectMD5(ObjectPath))

	require.NoError(t, doRequest(http.MethodDelete, objectURL, nil))

	require.Equal(t, 1, stub.PutsCnt())
	require.Equal(t, 1, stub.DeletesCnt())
}

func TestObjectStoreStubDelete404(t *testing.T) {
	stub, ts := StartObjectStore()
	defer ts.Close()

	objectURL := ts.URL + ObjectPath

	ctx, cancel := context.WithCancel(context.Background())
	defer cancel()

	req, err := http.NewRequestWithContext(ctx, http.MethodDelete, objectURL, nil)
	require.NoError(t, err)

	resp, err := http.DefaultClient.Do(req)
	require.NoError(t, err)
	defer resp.Body.Close()
	require.Equal(t, 404, resp.StatusCode)

	require.Equal(t, 0, stub.DeletesCnt())
}

func TestObjectStoreInitiateMultipartUpload(t *testing.T) {
	stub, ts := StartObjectStore()
	defer ts.Close()

	path := "/my-multipart"
	err := stub.InitiateMultipartUpload(path)
	require.NoError(t, err)

	err = stub.InitiateMultipartUpload(path)
	require.Error(t, err, "second attempt to open the same MultipartUpload")
}

func TestObjectStoreCompleteMultipartUpload(t *testing.T) {
	stub, ts := StartObjectStore()
	defer ts.Close()

	objectURL := ts.URL + ObjectPath
	parts := []struct {
		number     int
		content    string
		contentMD5 string
	}{
		{
			number:     1,
			content:    "first part",
			contentMD5: "550cf6b6e60f65a0e3104a26e70fea42",
		}, {
			number:     2,
			content:    "second part",
			contentMD5: "920b914bca0a70780b40881b8f376135",
		},
	}

	stub.InitiateMultipartUpload(ObjectPath)

	require.True(t, stub.IsMultipartUpload(ObjectPath))
	require.Equal(t, 0, stub.PutsCnt())
	require.Equal(t, 0, stub.DeletesCnt())

	// Workhorse knows nothing about S3 MultipartUpload, it receives some URLs
	//  from GitLab-rails and PUTs chunk of data to each of them.
	// Then it completes the upload with a final POST
	partPutURLs := []string{
		fmt.Sprintf("%s?partNumber=%d", objectURL, 1),
		fmt.Sprintf("%s?partNumber=%d", objectURL, 2),
	}
	completePostURL := objectURL

	for i, partPutURL := range partPutURLs {
		part := parts[i]

		require.NoError(t, doRequest(http.MethodPut, partPutURL, strings.NewReader(part.content)))

		require.Equal(t, i+1, stub.PutsCnt())
		require.Equal(t, 0, stub.DeletesCnt())
		require.Equal(t, part.contentMD5, stub.multipart[ObjectPath][part.number], "Part %d was not uploaded into ObjectStorage", part.number)
		require.Empty(t, stub.GetObjectMD5(ObjectPath), "Part %d was mistakenly uploaded as a single object", part.number)
		require.True(t, stub.IsMultipartUpload(ObjectPath), "MultipartUpload completed or aborted")
	}

	completeBody := fmt.Sprintf(`<CompleteMultipartUpload>
		<Part>
			<PartNumber>1</PartNumber>
			<ETag>%s</ETag>
		</Part>
		<Part>
			<PartNumber>2</PartNumber>
			<ETag>%s</ETag>
		</Part>
	</CompleteMultipartUpload>`, parts[0].contentMD5, parts[1].contentMD5)
	require.NoError(t, doRequest(http.MethodPost, completePostURL, strings.NewReader(completeBody)))

	require.Len(t, parts, stub.PutsCnt())
	require.Equal(t, 0, stub.DeletesCnt())
	require.False(t, stub.IsMultipartUpload(ObjectPath), "MultipartUpload is still in progress")
}

func TestObjectStoreAbortMultipartUpload(t *testing.T) {
	stub, ts := StartObjectStore()
	defer ts.Close()

	stub.InitiateMultipartUpload(ObjectPath)

	require.True(t, stub.IsMultipartUpload(ObjectPath))
	require.Equal(t, 0, stub.PutsCnt())
	require.Equal(t, 0, stub.DeletesCnt())

	objectURL := ts.URL + ObjectPath
	require.NoError(t, doRequest(http.MethodPut, fmt.Sprintf("%s?partNumber=%d", objectURL, 1), strings.NewReader(ObjectContent)))

	require.Equal(t, 1, stub.PutsCnt())
	require.Equal(t, 0, stub.DeletesCnt())
	require.Equal(t, ObjectMD5, stub.multipart[ObjectPath][1], "Part was not uploaded into ObjectStorage")
	require.Empty(t, stub.GetObjectMD5(ObjectPath), "Part was mistakenly uploaded as a single object")
	require.True(t, stub.IsMultipartUpload(ObjectPath), "MultipartUpload completed or aborted")

	require.NoError(t, doRequest(http.MethodDelete, objectURL, nil))

	require.Equal(t, 1, stub.PutsCnt())
	require.Equal(t, 1, stub.DeletesCnt())
	require.Empty(t, stub.GetObjectMD5(ObjectPath), "MultiUpload has been completed")
	require.False(t, stub.IsMultipartUpload(ObjectPath), "MultiUpload is still in progress")
}
