package filestore_test

import (
	"testing"
	"time"

	"github.com/stretchr/testify/require"

	"gitlab.com/gitlab-org/gitlab/workhorse/internal/api"
	"gitlab.com/gitlab-org/gitlab/workhorse/internal/config"
	"gitlab.com/gitlab-org/gitlab/workhorse/internal/filestore"
	"gitlab.com/gitlab-org/gitlab/workhorse/internal/objectstore/test"
)

func TestSaveFileOptsLocalAndRemote(t *testing.T) {
	tests := []struct {
		name          string
		localTempPath string
		presignedPut  string
		partSize      int64
		isLocal       bool
		isRemote      bool
		isMultipart   bool
	}{
		{
			name:          "Only LocalTempPath",
			localTempPath: "/tmp",
			isLocal:       true,
		},
		{
			name: "No paths",
		},
		{
			name:         "Only remoteUrl",
			presignedPut: "http://example.com",
		},
		{
			name:        "Multipart",
			partSize:    10,
			isMultipart: true,
		},
	}

	for _, test := range tests {
		t.Run(test.name, func(t *testing.T) {
			opts := filestore.SaveFileOpts{
				LocalTempPath: test.localTempPath,
				PresignedPut:  test.presignedPut,
				PartSize:      test.partSize,
			}

			require.Equal(t, test.isLocal, opts.IsLocal(), "IsLocal() mismatch")
			require.Equal(t, test.isMultipart, opts.IsMultipart(), "IsMultipart() mismatch")
		})
	}
}

func TestGetOpts(t *testing.T) {
	tests := []struct {
		name             string
		multipart        *api.MultipartUploadParams
		customPutHeaders bool
		putHeaders       map[string]string
	}{
		{
			name: "Single upload",
		},
		{
			name: "Multipart upload",
			multipart: &api.MultipartUploadParams{
				PartSize:    10,
				CompleteURL: "http://complete",
				AbortURL:    "http://abort",
				PartURLs:    []string{"http://part1", "http://part2"},
			},
		},
		{
			name:             "Single upload with custom content type",
			customPutHeaders: true,
			putHeaders:       map[string]string{"Content-Type": "image/jpeg"},
		}, {
			name: "Multipart upload with custom content type",
			multipart: &api.MultipartUploadParams{
				PartSize:    10,
				CompleteURL: "http://complete",
				AbortURL:    "http://abort",
				PartURLs:    []string{"http://part1", "http://part2"},
			},
			customPutHeaders: true,
			putHeaders:       map[string]string{"Content-Type": "image/jpeg"},
		},
	}

	for _, test := range tests {
		t.Run(test.name, func(t *testing.T) {
			apiResponse := &api.Response{
				RemoteObject: api.RemoteObject{
					Timeout:          10,
					ID:               "id",
					GetURL:           "http://get",
					StoreURL:         "http://store",
					DeleteURL:        "http://delete",
					MultipartUpload:  test.multipart,
					CustomPutHeaders: test.customPutHeaders,
					PutHeaders:       test.putHeaders,
				},
			}
			deadline := time.Now().Add(time.Duration(apiResponse.RemoteObject.Timeout) * time.Second)
			opts, err := filestore.GetOpts(apiResponse)
			require.NoError(t, err)

			require.Equal(t, apiResponse.TempPath, opts.LocalTempPath)
			require.WithinDuration(t, deadline, opts.Deadline, time.Second)
			require.Equal(t, apiResponse.RemoteObject.ID, opts.RemoteID)
			require.Equal(t, apiResponse.RemoteObject.GetURL, opts.RemoteURL)
			require.Equal(t, apiResponse.RemoteObject.StoreURL, opts.PresignedPut)
			require.Equal(t, apiResponse.RemoteObject.DeleteURL, opts.PresignedDelete)
			if test.customPutHeaders {
				require.Equal(t, opts.PutHeaders, apiResponse.RemoteObject.PutHeaders)
			} else {
				require.Equal(t, opts.PutHeaders, map[string]string{"Content-Type": "application/octet-stream"})
			}

			if test.multipart == nil {
				require.False(t, opts.IsMultipart())
				require.Empty(t, opts.PresignedCompleteMultipart)
				require.Empty(t, opts.PresignedAbortMultipart)
				require.Zero(t, opts.PartSize)
				require.Empty(t, opts.PresignedParts)
			} else {
				require.True(t, opts.IsMultipart())
				require.Equal(t, test.multipart.CompleteURL, opts.PresignedCompleteMultipart)
				require.Equal(t, test.multipart.AbortURL, opts.PresignedAbortMultipart)
				require.Equal(t, test.multipart.PartSize, opts.PartSize)
				require.Equal(t, test.multipart.PartURLs, opts.PresignedParts)
			}
		})
	}
}

func TestGetOptsFail(t *testing.T) {
	testCases := []struct {
		desc string
		in   api.Response
	}{
		{
			desc: "neither local nor remote",
			in:   api.Response{},
		},
		{
			desc: "both local and remote",
			in:   api.Response{TempPath: "/foobar", RemoteObject: api.RemoteObject{ID: "id"}},
		},
	}

	for _, tc := range testCases {
		t.Run(tc.desc, func(t *testing.T) {
			_, err := filestore.GetOpts(&tc.in)
			require.Error(t, err, "expect input to be rejected")
		})
	}
}

func TestGetOptsDefaultTimeout(t *testing.T) {
	deadline := time.Now().Add(filestore.DefaultObjectStoreTimeout)
	opts, err := filestore.GetOpts(&api.Response{TempPath: "/foo/bar"})
	require.NoError(t, err)

	require.WithinDuration(t, deadline, opts.Deadline, time.Minute)
}

func TestUseWorkhorseClientEnabled(t *testing.T) {
	cfg := filestore.ObjectStorageConfig{
		Provider: "AWS",
		S3Config: config.S3Config{
			Bucket: "test-bucket",
			Region: "test-region",
		},
		S3Credentials: config.S3Credentials{
			AwsAccessKeyID:     "test-key",
			AwsSecretAccessKey: "test-secret",
		},
	}

	missingCfg := cfg
	missingCfg.S3Credentials = config.S3Credentials{}

	iamConfig := missingCfg
	iamConfig.S3Config.UseIamProfile = true

	missingRegion := cfg
	missingRegion.S3Config.Region = ""

	tests := []struct {
		name                string
		UseWorkhorseClient  bool
		remoteTempObjectID  string
		objectStorageConfig filestore.ObjectStorageConfig
		expected            bool
	}{
		{
			name:                "all direct access settings used",
			UseWorkhorseClient:  true,
			remoteTempObjectID:  "test-object",
			objectStorageConfig: cfg,
			expected:            true,
		},
		{
			name:                "missing AWS credentials",
			UseWorkhorseClient:  true,
			remoteTempObjectID:  "test-object",
			objectStorageConfig: missingCfg,
			expected:            false,
		},
		{
			name:                "direct access disabled",
			UseWorkhorseClient:  false,
			remoteTempObjectID:  "test-object",
			objectStorageConfig: cfg,
			expected:            false,
		},
		{
			name:                "with IAM instance profile",
			UseWorkhorseClient:  true,
			remoteTempObjectID:  "test-object",
			objectStorageConfig: iamConfig,
			expected:            true,
		},
		{
			name:                "missing remote temp object ID",
			UseWorkhorseClient:  true,
			remoteTempObjectID:  "",
			objectStorageConfig: cfg,
			expected:            false,
		},
		{
			name:               "missing S3 config",
			UseWorkhorseClient: true,
			remoteTempObjectID: "test-object",
			expected:           false,
		},
		{
			name:               "missing S3 bucket",
			UseWorkhorseClient: true,
			remoteTempObjectID: "test-object",
			objectStorageConfig: filestore.ObjectStorageConfig{
				Provider: "AWS",
				S3Config: config.S3Config{},
			},
			expected: false,
		},
		{
			name:                "missing S3 region",
			UseWorkhorseClient:  true,
			remoteTempObjectID:  "test-object",
			objectStorageConfig: missingRegion,
			expected:            true,
		},
	}

	for _, test := range tests {
		t.Run(test.name, func(t *testing.T) {
			apiResponse := &api.Response{
				RemoteObject: api.RemoteObject{
					Timeout:            10,
					ID:                 "id",
					UseWorkhorseClient: test.UseWorkhorseClient,
					RemoteTempObjectID: test.remoteTempObjectID,
				},
			}
			deadline := time.Now().Add(time.Duration(apiResponse.RemoteObject.Timeout) * time.Second)
			opts, err := filestore.GetOpts(apiResponse)
			require.NoError(t, err)
			opts.ObjectStorageConfig = test.objectStorageConfig

			require.Equal(t, apiResponse.TempPath, opts.LocalTempPath)
			require.WithinDuration(t, deadline, opts.Deadline, time.Second)
			require.Equal(t, apiResponse.RemoteObject.ID, opts.RemoteID)
			require.Equal(t, apiResponse.RemoteObject.UseWorkhorseClient, opts.UseWorkhorseClient)
			require.Equal(t, test.expected, opts.UseWorkhorseClientEnabled())
		})
	}
}

func TestGoCloudConfig(t *testing.T) {
	mux, _, cleanup := test.SetupGoCloudFileBucket(t, "azblob")
	defer cleanup()

	tests := []struct {
		name     string
		provider string
		url      string
		valid    bool
	}{
		{
			name:     "valid AzureRM config",
			provider: "AzureRM",
			url:      "azblob:://test-container",
			valid:    true,
		},
		{
			name:     "invalid GoCloud scheme",
			provider: "AzureRM",
			url:      "unknown:://test-container",
			valid:    true,
		},
	}

	for _, test := range tests {
		t.Run(test.name, func(t *testing.T) {
			apiResponse := &api.Response{
				RemoteObject: api.RemoteObject{
					Timeout:            10,
					ID:                 "id",
					UseWorkhorseClient: true,
					RemoteTempObjectID: "test-object",
					ObjectStorage: &api.ObjectStorageParams{
						Provider: test.provider,
						GoCloudConfig: config.GoCloudConfig{
							URL: test.url,
						},
					},
				},
			}
			deadline := time.Now().Add(time.Duration(apiResponse.RemoteObject.Timeout) * time.Second)
			opts, err := filestore.GetOpts(apiResponse)
			require.NoError(t, err)
			opts.ObjectStorageConfig.URLMux = mux

			require.Equal(t, apiResponse.TempPath, opts.LocalTempPath)
			require.Equal(t, apiResponse.RemoteObject.RemoteTempObjectID, opts.RemoteTempObjectID)
			require.WithinDuration(t, deadline, opts.Deadline, time.Second)
			require.Equal(t, apiResponse.RemoteObject.ID, opts.RemoteID)
			require.Equal(t, apiResponse.RemoteObject.UseWorkhorseClient, opts.UseWorkhorseClient)
			require.Equal(t, test.provider, opts.ObjectStorageConfig.Provider)
			require.Equal(t, apiResponse.RemoteObject.ObjectStorage.GoCloudConfig, opts.ObjectStorageConfig.GoCloudConfig)
			require.True(t, opts.UseWorkhorseClientEnabled())
			require.Equal(t, test.valid, opts.ObjectStorageConfig.IsValid())
			require.False(t, opts.IsLocal())
		})
	}
}
