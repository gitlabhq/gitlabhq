package config

import (
	"os"
	"path/filepath"
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

const azureConfigWithManagedIdentity = `
[object_storage]
provider = "AzureRM"

[object_storage.azurerm]
azure_storage_account_name = "azuretester"
`

const googleConfigWithKeyLocation = `
[object_storage]
provider = "Google"

[object_storage.google]
google_json_key_location = "../../testdata/google_dummy_credentials.json"
`

const googleConfigWithKeyString = `
[object_storage]
provider = "Google"

[object_storage.google]
google_json_key_string = """
{
  "type": "service_account"
}
"""
`

const googleConfigWithApplicationDefault = `
[object_storage]
provider = "Google"

[object_storage.google]
google_application_default = true
`

func TestLoadEmptyConfig(t *testing.T) {
	config := ``

	cfg, err := LoadConfig(config)
	require.NoError(t, err)

	require.Empty(t, cfg.AltDocumentRoot)
	require.Equal(t, uint64(250000), cfg.ImageResizerConfig.MaxFilesize)
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

func TestRegisterGoCloudAzureURLOpeners(t *testing.T) {
	cfg, err := LoadConfig(azureConfig)
	require.NoError(t, err)

	expected := ObjectStorageCredentials{
		Provider: "AzureRM",
		AzureCredentials: AzureCredentials{
			AccountName: "azuretester",
			AccountKey:  "deadbeef",
		},
	}

	require.Equal(t, expected, cfg.ObjectStorageCredentials)
	testRegisterGoCloudURLOpener(t, cfg, "azblob")
}

func TestRegisterGoCloudAzureURLOpenersWithManagedIdentity(t *testing.T) {
	cfg, err := LoadConfig(azureConfigWithManagedIdentity)
	require.NoError(t, err)

	expected := ObjectStorageCredentials{
		Provider: "AzureRM",
		AzureCredentials: AzureCredentials{
			AccountName: "azuretester",
		},
	}

	require.Equal(t, expected, cfg.ObjectStorageCredentials)
	testRegisterGoCloudURLOpener(t, cfg, "azblob")
}

func TestRegisterGoCloudGoogleURLOpenersWithJSONKeyLocation(t *testing.T) {
	cfg, err := LoadConfig(googleConfigWithKeyLocation)
	require.NoError(t, err)

	expected := ObjectStorageCredentials{
		Provider: "Google",
		GoogleCredentials: GoogleCredentials{
			JSONKeyLocation: "../../testdata/google_dummy_credentials.json",
		},
	}

	require.Equal(t, expected, cfg.ObjectStorageCredentials)
	testRegisterGoCloudURLOpener(t, cfg, "gs")
}

func TestRegisterGoCloudGoogleURLOpenersWithJSONKeyString(t *testing.T) {
	cfg, err := LoadConfig(googleConfigWithKeyString)
	require.NoError(t, err)

	expected := ObjectStorageCredentials{
		Provider: "Google",
		GoogleCredentials: GoogleCredentials{
			JSONKeyString: `{
  "type": "service_account"
}
`,
		},
	}

	require.Equal(t, expected, cfg.ObjectStorageCredentials)
	testRegisterGoCloudURLOpener(t, cfg, "gs")
}

func TestRegisterGoCloudGoogleURLOpenersWithApplicationDefault(t *testing.T) {
	cfg, err := LoadConfig(googleConfigWithApplicationDefault)
	require.NoError(t, err)

	expected := ObjectStorageCredentials{
		Provider: "Google",
		GoogleCredentials: GoogleCredentials{
			ApplicationDefault: true,
		},
	}

	require.Equal(t, expected, cfg.ObjectStorageCredentials)

	path, err := filepath.Abs("../../testdata/google_dummy_credentials.json")
	require.NoError(t, err)

	t.Setenv("GOOGLE_APPLICATION_CREDENTIALS", path)

	testRegisterGoCloudURLOpener(t, cfg, "gs")
}

func testRegisterGoCloudURLOpener(t *testing.T, cfg *Config, bucketScheme string) {
	t.Helper()
	require.NoError(t, cfg.RegisterGoCloudURLOpeners())
	require.Equal(t, []string{bucketScheme}, cfg.ObjectStorageConfig.URLMux.BucketSchemes())
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

func TestDefaultConfig(t *testing.T) {
	cfg := NewDefaultConfig()

	require.Equal(t, uint64(250000), cfg.ImageResizerConfig.MaxFilesize)
}

func TestLoadConfigFromFile(t *testing.T) {
	config := `
[image_resizer]
max_filesize = 350000
`

	fileName := createTempFile(t, []byte(config))

	cfg, err := LoadConfigFromFile(&fileName)
	require.NoError(t, err)

	require.Equal(t, uint64(350000), cfg.ImageResizerConfig.MaxFilesize)
}

func createTempFile(t *testing.T, contents []byte) string {
	t.Helper()

	tmpFile, err := os.CreateTemp(t.TempDir(), "config.toml")
	require.NoError(t, err)
	defer tmpFile.Close()

	_, err = tmpFile.Write(contents)
	require.NoError(t, err)

	return tmpFile.Name()
}
