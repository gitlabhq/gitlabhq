package filestore_test

import (
	"context"
	"errors"
	"fmt"
	"io/ioutil"
	"os"
	"path"
	"strconv"
	"strings"
	"testing"
	"time"

	"github.com/dgrijalva/jwt-go"
	"github.com/stretchr/testify/require"
	"gocloud.dev/blob"

	"gitlab.com/gitlab-org/gitlab/workhorse/internal/config"
	"gitlab.com/gitlab-org/gitlab/workhorse/internal/filestore"
	"gitlab.com/gitlab-org/gitlab/workhorse/internal/objectstore/test"
	"gitlab.com/gitlab-org/gitlab/workhorse/internal/testhelper"
)

func testDeadline() time.Time {
	return time.Now().Add(filestore.DefaultObjectStoreTimeout)
}

func requireFileGetsRemovedAsync(t *testing.T, filePath string) {
	var err error

	// Poll because the file removal is async
	for i := 0; i < 100; i++ {
		_, err = os.Stat(filePath)
		if err != nil {
			break
		}
		time.Sleep(100 * time.Millisecond)
	}

	require.True(t, os.IsNotExist(err), "File hasn't been deleted during cleanup")
}

func requireObjectStoreDeletedAsync(t *testing.T, expectedDeletes int, osStub *test.ObjectstoreStub) {
	// Poll because the object removal is async
	for i := 0; i < 100; i++ {
		if osStub.DeletesCnt() == expectedDeletes {
			break
		}
		time.Sleep(10 * time.Millisecond)
	}

	require.Equal(t, expectedDeletes, osStub.DeletesCnt(), "Object not deleted")
}

func TestSaveFileWrongSize(t *testing.T) {
	ctx, cancel := context.WithCancel(context.Background())
	defer cancel()

	tmpFolder, err := ioutil.TempDir("", "workhorse-test-tmp")
	require.NoError(t, err)
	defer os.RemoveAll(tmpFolder)

	opts := &filestore.SaveFileOpts{LocalTempPath: tmpFolder, TempFilePrefix: "test-file"}
	fh, err := filestore.SaveFileFromReader(ctx, strings.NewReader(test.ObjectContent), test.ObjectSize+1, opts)
	require.Error(t, err)
	_, isSizeError := err.(filestore.SizeError)
	require.True(t, isSizeError, "Should fail with SizeError")
	require.Nil(t, fh)
}

func TestSaveFileWithKnownSizeExceedLimit(t *testing.T) {
	ctx, cancel := context.WithCancel(context.Background())
	defer cancel()

	tmpFolder, err := ioutil.TempDir("", "workhorse-test-tmp")
	require.NoError(t, err)
	defer os.RemoveAll(tmpFolder)

	opts := &filestore.SaveFileOpts{LocalTempPath: tmpFolder, TempFilePrefix: "test-file", MaximumSize: test.ObjectSize - 1}
	fh, err := filestore.SaveFileFromReader(ctx, strings.NewReader(test.ObjectContent), test.ObjectSize, opts)
	require.Error(t, err)
	_, isSizeError := err.(filestore.SizeError)
	require.True(t, isSizeError, "Should fail with SizeError")
	require.Nil(t, fh)
}

func TestSaveFileWithUnknownSizeExceedLimit(t *testing.T) {
	ctx, cancel := context.WithCancel(context.Background())
	defer cancel()

	tmpFolder, err := ioutil.TempDir("", "workhorse-test-tmp")
	require.NoError(t, err)
	defer os.RemoveAll(tmpFolder)

	opts := &filestore.SaveFileOpts{LocalTempPath: tmpFolder, TempFilePrefix: "test-file", MaximumSize: test.ObjectSize - 1}
	fh, err := filestore.SaveFileFromReader(ctx, strings.NewReader(test.ObjectContent), -1, opts)
	require.Equal(t, err, filestore.ErrEntityTooLarge)
	require.Nil(t, fh)
}

func TestSaveFromDiskNotExistingFile(t *testing.T) {
	ctx, cancel := context.WithCancel(context.Background())
	defer cancel()
	fh, err := filestore.SaveFileFromDisk(ctx, "/I/do/not/exist", &filestore.SaveFileOpts{})
	require.Error(t, err, "SaveFileFromDisk should fail")
	require.True(t, os.IsNotExist(err), "Provided file should not exists")
	require.Nil(t, fh, "On error FileHandler should be nil")
}

func TestSaveFileWrongETag(t *testing.T) {
	tests := []struct {
		name      string
		multipart bool
	}{
		{name: "single part"},
		{name: "multi part", multipart: true},
	}

	for _, spec := range tests {
		t.Run(spec.name, func(t *testing.T) {
			osStub, ts := test.StartObjectStoreWithCustomMD5(map[string]string{test.ObjectPath: "brokenMD5"})
			defer ts.Close()

			objectURL := ts.URL + test.ObjectPath

			opts := &filestore.SaveFileOpts{
				RemoteID:        "test-file",
				RemoteURL:       objectURL,
				PresignedPut:    objectURL + "?Signature=ASignature",
				PresignedDelete: objectURL + "?Signature=AnotherSignature",
				Deadline:        testDeadline(),
			}
			if spec.multipart {
				opts.PresignedParts = []string{objectURL + "?partNumber=1"}
				opts.PresignedCompleteMultipart = objectURL + "?Signature=CompleteSig"
				opts.PresignedAbortMultipart = objectURL + "?Signature=AbortSig"
				opts.PartSize = test.ObjectSize

				osStub.InitiateMultipartUpload(test.ObjectPath)
			}
			ctx, cancel := context.WithCancel(context.Background())
			fh, err := filestore.SaveFileFromReader(ctx, strings.NewReader(test.ObjectContent), test.ObjectSize, opts)
			require.Nil(t, fh)
			require.Error(t, err)
			require.Equal(t, 1, osStub.PutsCnt(), "File not uploaded")

			cancel() // this will trigger an async cleanup
			requireObjectStoreDeletedAsync(t, 1, osStub)
			require.False(t, spec.multipart && osStub.IsMultipartUpload(test.ObjectPath), "there must be no multipart upload in progress now")
		})
	}
}

func TestSaveFileFromDiskToLocalPath(t *testing.T) {
	f, err := ioutil.TempFile("", "workhorse-test")
	require.NoError(t, err)
	defer os.Remove(f.Name())

	_, err = fmt.Fprint(f, test.ObjectContent)
	require.NoError(t, err)

	tmpFolder, err := ioutil.TempDir("", "workhorse-test-tmp")
	require.NoError(t, err)
	defer os.RemoveAll(tmpFolder)

	ctx, cancel := context.WithCancel(context.Background())
	defer cancel()

	opts := &filestore.SaveFileOpts{LocalTempPath: tmpFolder}
	fh, err := filestore.SaveFileFromDisk(ctx, f.Name(), opts)
	require.NoError(t, err)
	require.NotNil(t, fh)

	require.NotEmpty(t, fh.LocalPath, "File not persisted on disk")
	_, err = os.Stat(fh.LocalPath)
	require.NoError(t, err)
}

func TestSaveFile(t *testing.T) {
	testhelper.ConfigureSecret()

	type remote int
	const (
		notRemote remote = iota
		remoteSingle
		remoteMultipart
	)

	tmpFolder, err := ioutil.TempDir("", "workhorse-test-tmp")
	require.NoError(t, err)
	defer os.RemoveAll(tmpFolder)

	tests := []struct {
		name   string
		local  bool
		remote remote
	}{
		{name: "Local only", local: true},
		{name: "Remote Single only", remote: remoteSingle},
		{name: "Remote Multipart only", remote: remoteMultipart},
	}

	for _, spec := range tests {
		t.Run(spec.name, func(t *testing.T) {
			var opts filestore.SaveFileOpts
			var expectedDeletes, expectedPuts int

			osStub, ts := test.StartObjectStore()
			defer ts.Close()

			switch spec.remote {
			case remoteSingle:
				objectURL := ts.URL + test.ObjectPath

				opts.RemoteID = "test-file"
				opts.RemoteURL = objectURL
				opts.PresignedPut = objectURL + "?Signature=ASignature"
				opts.PresignedDelete = objectURL + "?Signature=AnotherSignature"
				opts.Deadline = testDeadline()

				expectedDeletes = 1
				expectedPuts = 1
			case remoteMultipart:
				objectURL := ts.URL + test.ObjectPath

				opts.RemoteID = "test-file"
				opts.RemoteURL = objectURL
				opts.PresignedDelete = objectURL + "?Signature=AnotherSignature"
				opts.PartSize = int64(len(test.ObjectContent)/2) + 1
				opts.PresignedParts = []string{objectURL + "?partNumber=1", objectURL + "?partNumber=2"}
				opts.PresignedCompleteMultipart = objectURL + "?Signature=CompleteSignature"
				opts.Deadline = testDeadline()

				osStub.InitiateMultipartUpload(test.ObjectPath)
				expectedDeletes = 1
				expectedPuts = 2
			}

			if spec.local {
				opts.LocalTempPath = tmpFolder
				opts.TempFilePrefix = "test-file"
			}

			ctx, cancel := context.WithCancel(context.Background())
			defer cancel()

			fh, err := filestore.SaveFileFromReader(ctx, strings.NewReader(test.ObjectContent), test.ObjectSize, &opts)
			require.NoError(t, err)
			require.NotNil(t, fh)

			require.Equal(t, opts.RemoteID, fh.RemoteID)
			require.Equal(t, opts.RemoteURL, fh.RemoteURL)

			if spec.local {
				require.NotEmpty(t, fh.LocalPath, "File not persisted on disk")
				_, err := os.Stat(fh.LocalPath)
				require.NoError(t, err)

				dir := path.Dir(fh.LocalPath)
				require.Equal(t, opts.LocalTempPath, dir)
				filename := path.Base(fh.LocalPath)
				beginsWithPrefix := strings.HasPrefix(filename, opts.TempFilePrefix)
				require.True(t, beginsWithPrefix, fmt.Sprintf("LocalPath filename %q do not begin with TempFilePrefix %q", filename, opts.TempFilePrefix))
			} else {
				require.Empty(t, fh.LocalPath, "LocalPath must be empty for non local uploads")
			}

			require.Equal(t, test.ObjectSize, fh.Size)
			require.Equal(t, test.ObjectMD5, fh.MD5())
			require.Equal(t, test.ObjectSHA256, fh.SHA256())

			require.Equal(t, expectedPuts, osStub.PutsCnt(), "ObjectStore PutObject count mismatch")
			require.Equal(t, 0, osStub.DeletesCnt(), "File deleted too early")

			cancel() // this will trigger an async cleanup
			requireObjectStoreDeletedAsync(t, expectedDeletes, osStub)
			requireFileGetsRemovedAsync(t, fh.LocalPath)

			// checking generated fields
			fields, err := fh.GitLabFinalizeFields("file")
			require.NoError(t, err)

			checkFileHandlerWithFields(t, fh, fields, "file")

			token, jwtErr := jwt.ParseWithClaims(fields["file.gitlab-workhorse-upload"], &testhelper.UploadClaims{}, testhelper.ParseJWT)
			require.NoError(t, jwtErr)

			uploadFields := token.Claims.(*testhelper.UploadClaims).Upload

			checkFileHandlerWithFields(t, fh, uploadFields, "")
		})
	}
}

func TestSaveFileWithS3WorkhorseClient(t *testing.T) {
	tests := []struct {
		name        string
		objectSize  int64
		maxSize     int64
		expectedErr error
	}{
		{
			name:       "known size with no limit",
			objectSize: test.ObjectSize,
		},
		{
			name:       "unknown size with no limit",
			objectSize: -1,
		},
		{
			name:        "unknown object size with limit",
			objectSize:  -1,
			maxSize:     test.ObjectSize - 1,
			expectedErr: filestore.ErrEntityTooLarge,
		},
	}

	for _, tc := range tests {
		t.Run(tc.name, func(t *testing.T) {

			s3Creds, s3Config, sess, ts := test.SetupS3(t, "")
			defer ts.Close()

			ctx, cancel := context.WithCancel(context.Background())
			defer cancel()

			remoteObject := "tmp/test-file/1"
			opts := filestore.SaveFileOpts{
				RemoteID:           "test-file",
				Deadline:           testDeadline(),
				UseWorkhorseClient: true,
				RemoteTempObjectID: remoteObject,
				ObjectStorageConfig: filestore.ObjectStorageConfig{
					Provider:      "AWS",
					S3Credentials: s3Creds,
					S3Config:      s3Config,
				},
				MaximumSize: tc.maxSize,
			}

			_, err := filestore.SaveFileFromReader(ctx, strings.NewReader(test.ObjectContent), tc.objectSize, &opts)

			if tc.expectedErr == nil {
				require.NoError(t, err)
				test.S3ObjectExists(t, sess, s3Config, remoteObject, test.ObjectContent)
			} else {
				require.Equal(t, tc.expectedErr, err)
				test.S3ObjectDoesNotExist(t, sess, s3Config, remoteObject)
			}
		})
	}
}

func TestSaveFileWithAzureWorkhorseClient(t *testing.T) {
	mux, bucketDir, cleanup := test.SetupGoCloudFileBucket(t, "azblob")
	defer cleanup()

	ctx, cancel := context.WithCancel(context.Background())
	defer cancel()

	remoteObject := "tmp/test-file/1"
	opts := filestore.SaveFileOpts{
		RemoteID:           "test-file",
		Deadline:           testDeadline(),
		UseWorkhorseClient: true,
		RemoteTempObjectID: remoteObject,
		ObjectStorageConfig: filestore.ObjectStorageConfig{
			Provider:      "AzureRM",
			URLMux:        mux,
			GoCloudConfig: config.GoCloudConfig{URL: "azblob://test-container"},
		},
	}

	_, err := filestore.SaveFileFromReader(ctx, strings.NewReader(test.ObjectContent), test.ObjectSize, &opts)
	require.NoError(t, err)

	test.GoCloudObjectExists(t, bucketDir, remoteObject)
}

func TestSaveFileWithUnknownGoCloudScheme(t *testing.T) {
	ctx, cancel := context.WithCancel(context.Background())
	defer cancel()

	mux := new(blob.URLMux)

	remoteObject := "tmp/test-file/1"
	opts := filestore.SaveFileOpts{
		RemoteID:           "test-file",
		Deadline:           testDeadline(),
		UseWorkhorseClient: true,
		RemoteTempObjectID: remoteObject,
		ObjectStorageConfig: filestore.ObjectStorageConfig{
			Provider:      "SomeCloud",
			URLMux:        mux,
			GoCloudConfig: config.GoCloudConfig{URL: "foo://test-container"},
		},
	}

	_, err := filestore.SaveFileFromReader(ctx, strings.NewReader(test.ObjectContent), test.ObjectSize, &opts)
	require.Error(t, err)
}

func TestSaveMultipartInBodyFailure(t *testing.T) {
	osStub, ts := test.StartObjectStore()
	defer ts.Close()

	// this is a broken path because it contains bucket name but no key
	// this is the only way to get an in-body failure from our ObjectStoreStub
	objectPath := "/bucket-but-no-object-key"
	objectURL := ts.URL + objectPath
	opts := filestore.SaveFileOpts{
		RemoteID:                   "test-file",
		RemoteURL:                  objectURL,
		PartSize:                   test.ObjectSize,
		PresignedParts:             []string{objectURL + "?partNumber=1", objectURL + "?partNumber=2"},
		PresignedCompleteMultipart: objectURL + "?Signature=CompleteSignature",
		Deadline:                   testDeadline(),
	}

	osStub.InitiateMultipartUpload(objectPath)

	ctx, cancel := context.WithCancel(context.Background())
	defer cancel()

	fh, err := filestore.SaveFileFromReader(ctx, strings.NewReader(test.ObjectContent), test.ObjectSize, &opts)
	require.Nil(t, fh)
	require.Error(t, err)
	require.EqualError(t, err, test.MultipartUploadInternalError().Error())
}

func TestSaveRemoteFileWithLimit(t *testing.T) {
	testhelper.ConfigureSecret()

	type remote int
	const (
		notRemote remote = iota
		remoteSingle
		remoteMultipart
	)

	remoteTypes := []remote{remoteSingle, remoteMultipart}

	tests := []struct {
		name        string
		objectSize  int64
		maxSize     int64
		expectedErr error
		testData    string
	}{
		{
			name:       "known size with no limit",
			testData:   test.ObjectContent,
			objectSize: test.ObjectSize,
		},
		{
			name:       "unknown size with no limit",
			testData:   test.ObjectContent,
			objectSize: -1,
		},
		{
			name:        "unknown object size with limit",
			testData:    test.ObjectContent,
			objectSize:  -1,
			maxSize:     test.ObjectSize - 1,
			expectedErr: filestore.ErrEntityTooLarge,
		},
		{
			name:        "large object with unknown size with limit",
			testData:    string(make([]byte, 20000)),
			objectSize:  -1,
			maxSize:     19000,
			expectedErr: filestore.ErrEntityTooLarge,
		},
	}

	for _, tc := range tests {
		t.Run(tc.name, func(t *testing.T) {
			var opts filestore.SaveFileOpts

			for _, remoteType := range remoteTypes {
				tmpFolder, err := ioutil.TempDir("", "workhorse-test-tmp")
				require.NoError(t, err)
				defer os.RemoveAll(tmpFolder)

				osStub, ts := test.StartObjectStore()
				defer ts.Close()

				switch remoteType {
				case remoteSingle:
					objectURL := ts.URL + test.ObjectPath

					opts.RemoteID = "test-file"
					opts.RemoteURL = objectURL
					opts.PresignedPut = objectURL + "?Signature=ASignature"
					opts.PresignedDelete = objectURL + "?Signature=AnotherSignature"
					opts.Deadline = testDeadline()
					opts.MaximumSize = tc.maxSize
				case remoteMultipart:
					objectURL := ts.URL + test.ObjectPath

					opts.RemoteID = "test-file"
					opts.RemoteURL = objectURL
					opts.PresignedDelete = objectURL + "?Signature=AnotherSignature"
					opts.PartSize = int64(len(tc.testData)/2) + 1
					opts.PresignedParts = []string{objectURL + "?partNumber=1", objectURL + "?partNumber=2"}
					opts.PresignedCompleteMultipart = objectURL + "?Signature=CompleteSignature"
					opts.Deadline = testDeadline()
					opts.MaximumSize = tc.maxSize

					require.Less(t, int64(len(tc.testData)), int64(len(opts.PresignedParts))*opts.PartSize, "check part size calculation")

					osStub.InitiateMultipartUpload(test.ObjectPath)
				}

				ctx, cancel := context.WithCancel(context.Background())
				defer cancel()

				fh, err := filestore.SaveFileFromReader(ctx, strings.NewReader(tc.testData), tc.objectSize, &opts)

				if tc.expectedErr == nil {
					require.NoError(t, err)
					require.NotNil(t, fh)
				} else {
					require.True(t, errors.Is(err, tc.expectedErr))
					require.Nil(t, fh)
				}
			}
		})
	}
}

func checkFileHandlerWithFields(t *testing.T, fh *filestore.FileHandler, fields map[string]string, prefix string) {
	key := func(field string) string {
		if prefix == "" {
			return field
		}

		return fmt.Sprintf("%s.%s", prefix, field)
	}

	require.Equal(t, fh.Name, fields[key("name")])
	require.Equal(t, fh.LocalPath, fields[key("path")])
	require.Equal(t, fh.RemoteURL, fields[key("remote_url")])
	require.Equal(t, fh.RemoteID, fields[key("remote_id")])
	require.Equal(t, strconv.FormatInt(test.ObjectSize, 10), fields[key("size")])
	require.Equal(t, test.ObjectMD5, fields[key("md5")])
	require.Equal(t, test.ObjectSHA1, fields[key("sha1")])
	require.Equal(t, test.ObjectSHA256, fields[key("sha256")])
	require.Equal(t, test.ObjectSHA512, fields[key("sha512")])
}
