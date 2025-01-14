package destination

import (
	"context"
	"fmt"
	"os"
	"path"
	"strconv"
	"strings"
	"testing"
	"time"

	"github.com/golang-jwt/jwt/v5"
	"github.com/stretchr/testify/require"
	"gocloud.dev/blob"

	"gitlab.com/gitlab-org/gitlab/workhorse/internal/config"
	"gitlab.com/gitlab-org/gitlab/workhorse/internal/testhelper"
	"gitlab.com/gitlab-org/gitlab/workhorse/internal/upload/destination/objectstore/test"
)

const (
	remoteObject           = "tmp/test-file/1"
	partNumberParam1       = "?partNumber=1"
	partNumberParam2       = "?partNumber=2"
	testFile               = "test-file"
	ASignatureParam        = "?Signature=ASignature"
	AnotherSignatureParam  = "?Signature=AnotherSignature"
	CompleteSignatureParam = "?Signature=CompleteSignature"
)

func testDeadline() time.Time {
	return time.Now().Add(DefaultObjectStoreTimeout)
}

func requireFileGetsRemovedAsync(t *testing.T, filePath string) {
	var err error
	require.Eventually(t, func() bool {
		_, err = os.Stat(filePath)
		return err != nil
	}, 10*time.Second, 10*time.Millisecond)
	require.True(t, os.IsNotExist(err), "File hasn't been deleted during cleanup")
}

func requireObjectStoreDeletedAsync(t *testing.T, expectedDeletes int, osStub *test.ObjectstoreStub) {
	require.Eventually(t, func() bool { return osStub.DeletesCnt() == expectedDeletes }, time.Second, time.Millisecond, "Object not deleted")
}

func TestUploadWrongSize(t *testing.T) {
	ctx, cancel := context.WithCancel(context.Background())
	defer cancel()

	tmpFolder := t.TempDir()

	opts := &UploadOpts{LocalTempPath: tmpFolder}
	fh, err := Upload(ctx, strings.NewReader(test.ObjectContent), test.ObjectSize+1, "upload", opts)
	require.Error(t, err)
	_, isSizeError := err.(SizeError)
	require.True(t, isSizeError, "Should fail with SizeError")
	require.Nil(t, fh)
}

func TestUploadWithKnownSizeExceedLimit(t *testing.T) {
	ctx, cancel := context.WithCancel(context.Background())
	defer cancel()

	tmpFolder := t.TempDir()

	opts := &UploadOpts{LocalTempPath: tmpFolder, MaximumSize: test.ObjectSize - 1}
	fh, err := Upload(ctx, strings.NewReader(test.ObjectContent), test.ObjectSize, "upload", opts)
	require.Error(t, err)
	_, isSizeError := err.(SizeError)
	require.True(t, isSizeError, "Should fail with SizeError")
	require.Nil(t, fh)
}

func TestUploadWithUnknownSizeExceedLimit(t *testing.T) {
	ctx, cancel := context.WithCancel(context.Background())
	defer cancel()

	tmpFolder := t.TempDir()

	opts := &UploadOpts{LocalTempPath: tmpFolder, MaximumSize: test.ObjectSize - 1}
	fh, err := Upload(ctx, strings.NewReader(test.ObjectContent), -1, "upload", opts)
	require.Equal(t, err, ErrEntityTooLarge)
	require.Nil(t, fh)
}

func TestUploadWrongETag(t *testing.T) {
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

			opts := &UploadOpts{
				RemoteID:        "test-file",
				RemoteURL:       objectURL,
				PresignedPut:    objectURL + ASignatureParam,
				PresignedDelete: objectURL + AnotherSignatureParam,
				Deadline:        testDeadline(),
			}
			if spec.multipart {
				opts.PresignedParts = []string{objectURL + partNumberParam1}
				opts.PresignedCompleteMultipart = objectURL + "?Signature=CompleteSig"
				opts.PresignedAbortMultipart = objectURL + "?Signature=AbortSig"
				opts.PartSize = test.ObjectSize

				osStub.InitiateMultipartUpload(test.ObjectPath)
			}
			ctx, cancel := context.WithCancel(context.Background())
			fh, err := Upload(ctx, strings.NewReader(test.ObjectContent), test.ObjectSize, "upload", opts)
			require.Nil(t, fh)
			require.Error(t, err)
			require.Equal(t, 1, osStub.PutsCnt(), "File not uploaded")

			cancel() // this will trigger an async cleanup
			requireObjectStoreDeletedAsync(t, 1, osStub)
			require.False(t, spec.multipart && osStub.IsMultipartUpload(test.ObjectPath), "there must be no multipart upload in progress now")
		})
	}
}

func TestUpload(t *testing.T) {
	testhelper.ConfigureSecret()

	type remote int
	const (
		notRemote remote = iota
		remoteSingle
		remoteMultipart
	)

	tmpFolder := t.TempDir()

	tests := []struct {
		name       string
		local      bool
		remote     remote
		skipDelete bool
	}{
		{name: "Local only", local: true},
		{name: "Remote Single only", remote: remoteSingle},
		{name: "Remote Multipart only", remote: remoteMultipart},
		{name: "Local only With SkipDelete", local: true, skipDelete: true},
		{name: "Remote Single only With SkipDelete", remote: remoteSingle, skipDelete: true},
		{name: "Remote Multipart only With SkipDelete", remote: remoteMultipart, skipDelete: true},
	}

	for _, spec := range tests {
		t.Run(spec.name, func(t *testing.T) {
			var opts UploadOpts
			var expectedDeletes, expectedPuts int

			osStub, ts := test.StartObjectStore()
			defer ts.Close()

			switch spec.remote {
			case remoteSingle:
				objectURL := ts.URL + test.ObjectPath

				opts.RemoteID = testFile
				opts.RemoteURL = objectURL
				opts.PresignedPut = objectURL + ASignatureParam
				opts.PresignedDelete = objectURL + AnotherSignatureParam
				opts.Deadline = testDeadline()

				expectedDeletes = 1
				expectedPuts = 1
			case remoteMultipart:
				objectURL := ts.URL + test.ObjectPath

				opts.RemoteID = testFile
				opts.RemoteURL = objectURL
				opts.PresignedDelete = objectURL + AnotherSignatureParam
				opts.PartSize = int64(len(test.ObjectContent)/2) + 1
				opts.PresignedParts = []string{objectURL + partNumberParam1, objectURL + partNumberParam2}
				opts.PresignedCompleteMultipart = objectURL + CompleteSignatureParam
				opts.Deadline = testDeadline()

				osStub.InitiateMultipartUpload(test.ObjectPath)
				expectedDeletes = 1
				expectedPuts = 2
			}

			if spec.local {
				opts.LocalTempPath = tmpFolder
			}

			opts.SkipDelete = spec.skipDelete

			if opts.SkipDelete {
				expectedDeletes = 0
			}

			ctx, cancel := context.WithCancel(context.Background())
			defer cancel()

			fh, err := Upload(ctx, strings.NewReader(test.ObjectContent), test.ObjectSize, "upload", &opts)
			require.NoError(t, err)
			require.NotNil(t, fh)

			require.Equal(t, opts.RemoteID, fh.RemoteID)
			require.Equal(t, opts.RemoteURL, fh.RemoteURL)

			if spec.local {
				require.NotEmpty(t, fh.LocalPath, "File not persisted on disk")
				_, err = os.Stat(fh.LocalPath)
				require.NoError(t, err)

				dir := path.Dir(fh.LocalPath)
				require.Equal(t, opts.LocalTempPath, dir)
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

func TestUploadWithS3WorkhorseClient(t *testing.T) {
	tests := []struct {
		name        string
		objectSize  int64
		maxSize     int64
		expectedErr error
		awsSDK      string
	}{
		{
			name:       "known size with no limit",
			objectSize: test.ObjectSize,
		},
		{
			name:       "known size with no limit with v1 SDK",
			objectSize: test.ObjectSize,
			awsSDK:     "v1",
		},
		{
			name:       "unknown size with no limit",
			objectSize: -1,
		},
		{
			name:        "unknown object size with limit",
			objectSize:  -1,
			maxSize:     test.ObjectSize - 1,
			expectedErr: ErrEntityTooLarge,
		},
		{
			name:       "S3 v2 known size with no limit",
			objectSize: test.ObjectSize,
			awsSDK:     "v2",
		},
		{
			name:       "S3 v2 unknown size with no limit",
			objectSize: -1,
			awsSDK:     "v2",
		},
		{
			name:        "S3 v2 unknown object size with limit",
			objectSize:  -1,
			maxSize:     test.ObjectSize - 1,
			expectedErr: ErrEntityTooLarge,
			awsSDK:      "v2",
		},
	}

	for _, tc := range tests {
		t.Run(tc.name, func(t *testing.T) {
			s3Creds, s3Config, client, ts := test.SetupS3(t, "")
			defer ts.Close()

			if tc.awsSDK != "" {
				s3Config.AwsSDK = tc.awsSDK
			}

			ctx, cancel := context.WithCancel(context.Background())
			defer cancel()

			opts := UploadOpts{
				RemoteID:           "test-file",
				Deadline:           testDeadline(),
				UseWorkhorseClient: true,
				RemoteTempObjectID: remoteObject,
				ObjectStorageConfig: ObjectStorageConfig{
					Provider:      "AWS",
					S3Credentials: s3Creds,
					S3Config:      s3Config,
				},
				MaximumSize: tc.maxSize,
			}

			_, err := Upload(ctx, strings.NewReader(test.ObjectContent), tc.objectSize, "upload", &opts)

			if tc.expectedErr == nil {
				require.NoError(t, err)
				test.S3ObjectExists(ctx, t, client, s3Config, remoteObject, test.ObjectContent)
			} else {
				require.Equal(t, tc.expectedErr, err)
				test.S3ObjectDoesNotExist(ctx, t, client, s3Config, remoteObject)
			}
		})
	}
}

func TestUploadWithAzureWorkhorseClient(t *testing.T) {
	mux, bucketDir := test.SetupGoCloudFileBucket(t, "azblob")

	ctx, cancel := context.WithCancel(context.Background())
	defer cancel()

	opts := UploadOpts{
		RemoteID:           "test-file",
		Deadline:           testDeadline(),
		UseWorkhorseClient: true,
		RemoteTempObjectID: remoteObject,
		ObjectStorageConfig: ObjectStorageConfig{
			Provider:      "AzureRM",
			URLMux:        mux,
			GoCloudConfig: config.GoCloudConfig{URL: "azblob://test-container"},
		},
	}

	_, err := Upload(ctx, strings.NewReader(test.ObjectContent), test.ObjectSize, "upload", &opts)
	require.NoError(t, err)

	test.GoCloudObjectExists(t, bucketDir, remoteObject)
}

func TestUploadWithUnknownGoCloudScheme(t *testing.T) {
	ctx, cancel := context.WithCancel(context.Background())
	defer cancel()

	mux := new(blob.URLMux)

	opts := UploadOpts{
		RemoteID:           "test-file",
		Deadline:           testDeadline(),
		UseWorkhorseClient: true,
		RemoteTempObjectID: remoteObject,
		ObjectStorageConfig: ObjectStorageConfig{
			Provider:      "SomeCloud",
			URLMux:        mux,
			GoCloudConfig: config.GoCloudConfig{URL: "foo://test-container"},
		},
	}

	_, err := Upload(ctx, strings.NewReader(test.ObjectContent), test.ObjectSize, "upload", &opts)
	require.Error(t, err)
}

func TestUploadMultipartInBodyFailure(t *testing.T) {
	tests := []struct {
		name       string
		skipDelete bool
	}{
		{name: "With skipDelete false", skipDelete: false},
		{name: "With skipDelete true", skipDelete: true},
	}

	for _, spec := range tests {
		t.Run(spec.name, func(t *testing.T) {
			osStub, ts := test.StartObjectStore()
			defer ts.Close()

			// this is a broken path because it contains bucket name but no key
			// this is the only way to get an in-body failure from our ObjectStoreStub
			objectPath := "/bucket-but-no-object-key"
			objectURL := ts.URL + objectPath
			opts := UploadOpts{
				RemoteID:                   "test-file",
				RemoteURL:                  objectURL,
				PartSize:                   test.ObjectSize,
				PresignedParts:             []string{objectURL + partNumberParam1, objectURL + partNumberParam2},
				PresignedCompleteMultipart: objectURL + CompleteSignatureParam,
				PresignedDelete:            objectURL + AnotherSignatureParam,
				Deadline:                   testDeadline(),
				SkipDelete:                 spec.skipDelete,
			}

			osStub.InitiateMultipartUpload(objectPath)

			ctx, cancel := context.WithCancel(context.Background())
			defer cancel()

			fh, err := Upload(ctx, strings.NewReader(test.ObjectContent), test.ObjectSize, "upload", &opts)
			require.Nil(t, fh)
			require.Error(t, err)
			require.EqualError(t, err, test.MultipartUploadInternalError().Error())

			cancel() // this will trigger an async cleanup
			requireObjectStoreDeletedAsync(t, 1, osStub)
		})
	}
}

func TestUploadRemoteFileWithLimit(t *testing.T) {
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
			expectedErr: ErrEntityTooLarge,
		},
		{
			name:        "large object with unknown size with limit",
			testData:    string(make([]byte, 20000)),
			objectSize:  -1,
			maxSize:     19000,
			expectedErr: ErrEntityTooLarge,
		},
	}

	for _, tc := range tests {
		t.Run(tc.name, func(t *testing.T) {
			var opts UploadOpts

			for _, remoteType := range remoteTypes {
				osStub, ts := test.StartObjectStore()
				defer ts.Close()

				switch remoteType {
				case remoteSingle:
					objectURL := ts.URL + test.ObjectPath

					opts.RemoteID = testFile
					opts.RemoteURL = objectURL
					opts.PresignedPut = objectURL + ASignatureParam
					opts.PresignedDelete = objectURL + AnotherSignatureParam
					opts.Deadline = testDeadline()
					opts.MaximumSize = tc.maxSize
				case remoteMultipart:
					objectURL := ts.URL + test.ObjectPath

					opts.RemoteID = testFile
					opts.RemoteURL = objectURL
					opts.PresignedDelete = objectURL + AnotherSignatureParam
					opts.PartSize = int64(len(tc.testData)/2) + 1
					opts.PresignedParts = []string{objectURL + partNumberParam1, objectURL + partNumberParam2}
					opts.PresignedCompleteMultipart = objectURL + CompleteSignatureParam
					opts.Deadline = testDeadline()
					opts.MaximumSize = tc.maxSize

					require.Less(t, int64(len(tc.testData)), int64(len(opts.PresignedParts))*opts.PartSize, "check part size calculation")

					osStub.InitiateMultipartUpload(test.ObjectPath)
				}

				ctx, cancel := context.WithCancel(context.Background())
				defer cancel()

				fh, err := Upload(ctx, strings.NewReader(tc.testData), tc.objectSize, "upload", &opts)

				if tc.expectedErr == nil {
					require.NoError(t, err)
					require.NotNil(t, fh)
				} else {
					require.ErrorIs(t, err, tc.expectedErr)
					require.Nil(t, fh)
				}
			}
		})
	}
}

func checkFileHandlerWithFields(t *testing.T, fh *FileHandler, fields map[string]string, prefix string) {
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
	require.NotEmpty(t, fields[key("upload_duration")])
}
