package config

import (
	"context"
	"fmt"
	"math"
	"net/url"
	"os"
	"runtime"
	"strings"
	"time"

	"github.com/Azure/azure-sdk-for-go/sdk/storage/azblob"
	"github.com/Azure/azure-sdk-for-go/sdk/storage/azblob/container"
	"github.com/BurntSushi/toml"
	"gocloud.dev/blob"
	"gocloud.dev/blob/azureblob"
	"gocloud.dev/blob/gcsblob"
	"gocloud.dev/gcp"
	"golang.org/x/oauth2/google"
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

	S3Credentials     S3Credentials     `toml:"s3"`
	AzureCredentials  AzureCredentials  `toml:"azurerm"`
	GoogleCredentials GoogleCredentials `toml:"google"`
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

type GoogleCredentials struct {
	ApplicationDefault bool   `toml:"google_application_default"`
	JSONKeyString      string `toml:"google_json_key_string"`
	JSONKeyLocation    string `toml:"google_json_key_location"`
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

type TlsConfig struct {
	Certificate string `toml:"certificate"`
	Key         string `toml:"key"`
	MinVersion  string `toml:"min_version"`
	MaxVersion  string `toml:"max_version"`
}

type ListenerConfig struct {
	Network string     `toml:"network"`
	Addr    string     `toml:"addr"`
	Tls     *TlsConfig `toml:"tls"`
}

type Config struct {
	Redis                        *RedisConfig             `toml:"redis"`
	Backend                      *url.URL                 `toml:"-"`
	CableBackend                 *url.URL                 `toml:"-"`
	Version                      string                   `toml:"-"`
	DocumentRoot                 string                   `toml:"-"`
	DevelopmentMode              bool                     `toml:"-"`
	Socket                       string                   `toml:"-"`
	CableSocket                  string                   `toml:"-"`
	ProxyHeadersTimeout          time.Duration            `toml:"-"`
	APILimit                     uint                     `toml:"-"`
	APIQueueLimit                uint                     `toml:"-"`
	APIQueueTimeout              time.Duration            `toml:"-"`
	APICILongPollingDuration     time.Duration            `toml:"-"`
	ObjectStorageConfig          ObjectStorageConfig      `toml:"-"`
	ObjectStorageCredentials     ObjectStorageCredentials `toml:"object_storage"`
	PropagateCorrelationID       bool                     `toml:"-"`
	ImageResizerConfig           ImageResizerConfig       `toml:"image_resizer"`
	AltDocumentRoot              string                   `toml:"alt_document_root"`
	ShutdownTimeout              TomlDuration             `toml:"shutdown_timeout"`
	TrustedCIDRsForXForwardedFor []string                 `toml:"trusted_cidrs_for_x_forwarded_for"`
	TrustedCIDRsForPropagation   []string                 `toml:"trusted_cidrs_for_propagation"`
	Listeners                    []ListenerConfig         `toml:"listeners"`
	MetricsListener              *ListenerConfig          `toml:"metrics_listener"`
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
		urlOpener, err := creds.AzureCredentials.getURLOpener()
		if err != nil {
			return err
		}
		c.ObjectStorageConfig.URLMux.RegisterBucket(azureblob.Scheme, urlOpener)
	}

	if strings.EqualFold(creds.Provider, "Google") && (creds.GoogleCredentials.JSONKeyLocation != "" || creds.GoogleCredentials.JSONKeyString != "" || creds.GoogleCredentials.ApplicationDefault) {
		urlOpener, err := creds.GoogleCredentials.getURLOpener()
		if err != nil {
			return err
		}
		c.ObjectStorageConfig.URLMux.RegisterBucket(gcsblob.Scheme, urlOpener)
	}

	return nil
}

func (creds *AzureCredentials) getURLOpener() (*azureblob.URLOpener, error) {
	serviceURLOptions := azureblob.ServiceURLOptions{
		AccountName: creds.AccountName,
	}

	clientFunc := func(svcURL azureblob.ServiceURL, containerName azureblob.ContainerName) (*container.Client, error) {
		sharedKeyCred, err := azblob.NewSharedKeyCredential(creds.AccountName, creds.AccountKey)
		if err != nil {
			return nil, fmt.Errorf("error creating Azure credentials: %w", err)
		}
		containerURL := fmt.Sprintf("%s/%s", svcURL, containerName)
		return container.NewClientWithSharedKeyCredential(containerURL, sharedKeyCred, &container.ClientOptions{})
	}

	return &azureblob.URLOpener{
		MakeClient:        clientFunc,
		ServiceURLOptions: serviceURLOptions,
	}, nil
}

func (creds *GoogleCredentials) getURLOpener() (*gcsblob.URLOpener, error) {
	ctx, cancel := context.WithTimeout(context.Background(), 30*time.Second) // lint:allow context.Background
	defer cancel()

	gcpCredentials, err := creds.getGCPCredentials(ctx)
	if err != nil {
		return nil, err
	}

	client, err := gcp.NewHTTPClient(
		gcp.DefaultTransport(),
		gcp.CredentialsTokenSource(gcpCredentials),
	)
	if err != nil {
		return nil, fmt.Errorf("error creating Google HTTP client: %w", err)
	}

	return &gcsblob.URLOpener{
		Client: client,
	}, nil
}

func (creds *GoogleCredentials) getGCPCredentials(ctx context.Context) (*google.Credentials, error) {
	const gcpCredentialsScope = "https://www.googleapis.com/auth/devstorage.read_write"
	if creds.ApplicationDefault {
		return gcp.DefaultCredentials(ctx)
	}

	if creds.JSONKeyLocation != "" {
		b, err := os.ReadFile(creds.JSONKeyLocation)
		if err != nil {
			return nil, fmt.Errorf("error reading Google json key location: %w", err)
		}

		return google.CredentialsFromJSON(ctx, b, gcpCredentialsScope)
	}

	b := []byte(creds.JSONKeyString)
	return google.CredentialsFromJSON(ctx, b, gcpCredentialsScope)
}
