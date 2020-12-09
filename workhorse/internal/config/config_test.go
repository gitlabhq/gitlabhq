package config

import (
	"testing"

	"github.com/stretchr/testify/require"
)

const azureConfig = `
[object_storage]
provider = "AzureRM"

[object_storage.azurerm]
azure_storage_account_name = "azuretester"
azure_storage_access_key = "deadbeef"
`

func TestLoadEmptyConfig(t *testing.T) {
	config := ``

	cfg, err := LoadConfig(config)
	require.NoError(t, err)

	require.Empty(t, cfg.AltDocumentRoot)
	require.Equal(t, cfg.ImageResizerConfig.MaxFilesize, uint64(250000))
	require.GreaterOrEqual(t, cfg.ImageResizerConfig.MaxScalerProcs, uint32(2))

	require.Equal(t, ObjectStorageCredentials{}, cfg.ObjectStorageCredentials)
	require.NoError(t, cfg.RegisterGoCloudURLOpeners())
}

func TestLoadObjectStorageConfig(t *testing.T) {
	config := `
[object_storage]
provider = "AWS"

[object_storage.s3]
aws_access_key_id = "minio"
aws_secret_access_key = "gdk-minio"
`

	cfg, err := LoadConfig(config)
	require.NoError(t, err)

	require.NotNil(t, cfg.ObjectStorageCredentials, "Expected object storage credentials")

	expected := ObjectStorageCredentials{
		Provider: "AWS",
		S3Credentials: S3Credentials{
			AwsAccessKeyID:     "minio",
			AwsSecretAccessKey: "gdk-minio",
		},
	}

	require.Equal(t, expected, cfg.ObjectStorageCredentials)
}

func TestRegisterGoCloudURLOpeners(t *testing.T) {
	cfg, err := LoadConfig(azureConfig)
	require.NoError(t, err)

	require.NotNil(t, cfg.ObjectStorageCredentials, "Expected object storage credentials")

	expected := ObjectStorageCredentials{
		Provider: "AzureRM",
		AzureCredentials: AzureCredentials{
			AccountName: "azuretester",
			AccountKey:  "deadbeef",
		},
	}

	require.Equal(t, expected, cfg.ObjectStorageCredentials)
	require.Nil(t, cfg.ObjectStorageConfig.URLMux)

	require.NoError(t, cfg.RegisterGoCloudURLOpeners())
	require.NotNil(t, cfg.ObjectStorageConfig.URLMux)

	require.True(t, cfg.ObjectStorageConfig.URLMux.ValidBucketScheme("azblob"))
	require.Equal(t, []string{"azblob"}, cfg.ObjectStorageConfig.URLMux.BucketSchemes())
}

func TestLoadImageResizerConfig(t *testing.T) {
	config := `
[image_resizer]
max_scaler_procs = 200
max_filesize = 350000
`

	cfg, err := LoadConfig(config)
	require.NoError(t, err)

	require.NotNil(t, cfg.ImageResizerConfig, "Expected image resizer config")

	expected := ImageResizerConfig{
		MaxScalerProcs: 200,
		MaxFilesize:    350000,
	}

	require.Equal(t, expected, cfg.ImageResizerConfig)
}

func TestAltDocumentConfig(t *testing.T) {
	config := `
alt_document_root = "/path/to/documents"
`

	cfg, err := LoadConfig(config)
	require.NoError(t, err)

	require.Equal(t, "/path/to/documents", cfg.AltDocumentRoot)
}
