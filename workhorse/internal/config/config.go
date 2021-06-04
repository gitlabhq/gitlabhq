package config

import (
	"math"
	"net/url"
	"runtime"
	"strings"
	"time"

	"github.com/Azure/azure-storage-blob-go/azblob"
	"github.com/BurntSushi/toml"
	"gitlab.com/gitlab-org/labkit/log"
	"gocloud.dev/blob"
	"gocloud.dev/blob/azureblob"
)

type TomlURL struct {
	url.URL
}

func (u *TomlURL) UnmarshalText(text []byte) error {
	temp, err := url.Parse(string(text))
	u.URL = *temp
	return err
}

type TomlDuration struct {
	time.Duration
}

func (d *TomlDuration) UnmarshalText(text []byte) error {
	temp, err := time.ParseDuration(string(text))
	d.Duration = temp
	return err
}

type ObjectStorageCredentials struct {
	Provider string

	S3Credentials    S3Credentials    `toml:"s3"`
	AzureCredentials AzureCredentials `toml:"azurerm"`
}

type ObjectStorageConfig struct {
	URLMux *blob.URLMux `toml:"-"`
}

type S3Credentials struct {
	AwsAccessKeyID     string `toml:"aws_access_key_id"`
	AwsSecretAccessKey string `toml:"aws_secret_access_key"`
}

type S3Config struct {
	Region               string `toml:"-"`
	Bucket               string `toml:"-"`
	PathStyle            bool   `toml:"-"`
	Endpoint             string `toml:"-"`
	UseIamProfile        bool   `toml:"-"`
	ServerSideEncryption string `toml:"-"` // Server-side encryption mode (e.g. AES256, aws:kms)
	SSEKMSKeyID          string `toml:"-"` // Server-side encryption key-management service key ID (e.g. arn:aws:xxx)
}

type GoCloudConfig struct {
	URL string `toml:"-"`
}

type AzureCredentials struct {
	AccountName string `toml:"azure_storage_account_name"`
	AccountKey  string `toml:"azure_storage_access_key"`
}

type RedisConfig struct {
	URL            TomlURL
	Sentinel       []TomlURL
	SentinelMaster string
	Password       string
	DB             *int
	MaxIdle        *int
	MaxActive      *int
}

type ImageResizerConfig struct {
	MaxScalerProcs uint32 `toml:"max_scaler_procs"`
	MaxFilesize    uint64 `toml:"max_filesize"`
}

type Config struct {
	Redis                    *RedisConfig             `toml:"redis"`
	Backend                  *url.URL                 `toml:"-"`
	CableBackend             *url.URL                 `toml:"-"`
	Version                  string                   `toml:"-"`
	DocumentRoot             string                   `toml:"-"`
	DevelopmentMode          bool                     `toml:"-"`
	Socket                   string                   `toml:"-"`
	CableSocket              string                   `toml:"-"`
	ProxyHeadersTimeout      time.Duration            `toml:"-"`
	APILimit                 uint                     `toml:"-"`
	APIQueueLimit            uint                     `toml:"-"`
	APIQueueTimeout          time.Duration            `toml:"-"`
	APICILongPollingDuration time.Duration            `toml:"-"`
	ObjectStorageConfig      ObjectStorageConfig      `toml:"-"`
	ObjectStorageCredentials ObjectStorageCredentials `toml:"object_storage"`
	PropagateCorrelationID   bool                     `toml:"-"`
	ImageResizerConfig       ImageResizerConfig       `toml:"image_resizer"`
	AltDocumentRoot          string                   `toml:"alt_document_root"`
	ShutdownTimeout          TomlDuration             `toml:"shutdown_timeout"`
}

var DefaultImageResizerConfig = ImageResizerConfig{
	MaxScalerProcs: uint32(math.Max(2, float64(runtime.NumCPU())/2)),
	MaxFilesize:    250 * 1000, // 250kB,
}

func LoadConfig(data string) (*Config, error) {
	cfg := &Config{ImageResizerConfig: DefaultImageResizerConfig}

	if _, err := toml.Decode(data, cfg); err != nil {
		return nil, err
	}

	return cfg, nil
}

func (c *Config) RegisterGoCloudURLOpeners() error {
	c.ObjectStorageConfig.URLMux = new(blob.URLMux)

	creds := c.ObjectStorageCredentials
	if strings.EqualFold(creds.Provider, "AzureRM") && creds.AzureCredentials.AccountName != "" && creds.AzureCredentials.AccountKey != "" {
		accountName := azureblob.AccountName(creds.AzureCredentials.AccountName)
		accountKey := azureblob.AccountKey(creds.AzureCredentials.AccountKey)

		credential, err := azureblob.NewCredential(accountName, accountKey)
		if err != nil {
			log.WithError(err).Error("error creating Azure credentials")
			return err
		}

		pipeline := azureblob.NewPipeline(credential, azblob.PipelineOptions{})

		azureURLOpener := &azureURLOpener{
			&azureblob.URLOpener{
				AccountName: accountName,
				Pipeline:    pipeline,
				Options:     azureblob.Options{Credential: credential},
			},
		}

		c.ObjectStorageConfig.URLMux.RegisterBucket(azureblob.Scheme, azureURLOpener)
	}

	return nil
}
