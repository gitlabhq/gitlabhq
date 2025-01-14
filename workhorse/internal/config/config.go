// Package config provides configuration management for object storage,
// including support for S3, Azure Blob Storage, and Google Cloud Storage.
package config

import (
	"context"
	"crypto/tls"
	"encoding/json"
	"errors"
	"fmt"
	"math"
	"net/url"
	"os"
	"os/exec"
	"runtime"
	"strings"
	"time"

	"github.com/Azure/azure-sdk-for-go/sdk/azidentity"
	"github.com/Azure/azure-sdk-for-go/sdk/storage/azblob"
	"github.com/Azure/azure-sdk-for-go/sdk/storage/azblob/container"
	"github.com/BurntSushi/toml"
	"gocloud.dev/blob"
	"gocloud.dev/blob/azureblob"
	"gocloud.dev/blob/gcsblob"
	"gocloud.dev/gcp"
	"golang.org/x/oauth2/google"
)

// Megabyte constant for size calculations
const Megabyte = 1 << 20

// TLSVersions contains a mapping of textual TLS versions to tls.Version* constants
var TLSVersions = map[string]uint16{
	"":       0, // Default value in tls.Config
	"tls1.0": tls.VersionTLS10,
	"tls1.1": tls.VersionTLS11,
	"tls1.2": tls.VersionTLS12,
	"tls1.3": tls.VersionTLS13,
}

// TomlURL wraps url.URL for TOML unmarshalling
type TomlURL struct {
	url.URL
}

// UnmarshalText parses a TOML text representation into a TomlURL
func (u *TomlURL) UnmarshalText(text []byte) error {
	temp, err := url.Parse(string(text))
	u.URL = *temp
	return err
}

// MarshalText converts a TomlURL back to TOML text representation
func (u *TomlURL) MarshalText() ([]byte, error) {
	return []byte(u.String()), nil
}

// TomlDuration wraps time.Duration for TOML unmarshalling
type TomlDuration struct {
	time.Duration
}

// UnmarshalText parses a TOML text representation into a TomlDuration
func (d *TomlDuration) UnmarshalText(text []byte) error {
	temp, err := time.ParseDuration(string(text))
	d.Duration = temp
	return err
}

// MarshalText converts a TomlDuration back to TOML text representation
func (d TomlDuration) MarshalText() ([]byte, error) {
	return []byte(d.String()), nil
}

// ObjectStorageCredentials holds credentials for various object storage providers
type ObjectStorageCredentials struct {
	Provider string

	S3Credentials     S3Credentials     `toml:"s3" json:"s3"`
	AzureCredentials  AzureCredentials  `toml:"azurerm" json:"azurerm"`
	GoogleCredentials GoogleCredentials `toml:"google" json:"google"`
}

// ObjectStorageConfig contains the URLMux for object storage configuration
type ObjectStorageConfig struct {
	URLMux *blob.URLMux `toml:"-"`
}

// S3Credentials holds AWS S3 credentials
type S3Credentials struct {
	AwsAccessKeyID     string `toml:"aws_access_key_id" json:"aws_access_key_id"`
	AwsSecretAccessKey string `toml:"aws_secret_access_key" json:"aws_secret_access_key"`
	AwsSessionToken    string `toml:"aws_session_token" json:"aws_session_token"`
}

// S3Config holds S3-specific configuration options
type S3Config struct {
	Region               string `toml:"-"`
	Bucket               string `toml:"-"`
	PathStyle            bool   `toml:"-"`
	Endpoint             string `toml:"-"`
	UseIamProfile        bool   `toml:"-"`
	ServerSideEncryption string `toml:"-"` // Server-side encryption mode (e.g. AES256, aws:kms)
	SSEKMSKeyID          string `toml:"-"` // Server-side encryption key-management service key ID (e.g. arn:aws:xxx)
	AwsSDK               string `toml:"-"` // DEPRECATED. AWS SDK v2 is always used now.
}

// GoCloudConfig holds GoCloud-specific configuration
type GoCloudConfig struct {
	URL string `toml:"-"`
}

// AzureCredentials holds Azure Blob Storage credentials
type AzureCredentials struct {
	AccountName string `toml:"azure_storage_account_name" json:"azure_storage_account_name"`
	AccountKey  string `toml:"azure_storage_access_key" json:"azure_storage_access_key"`
}

// GoogleCredentials holds Google Cloud Storage credentials
type GoogleCredentials struct {
	ApplicationDefault bool   `toml:"google_application_default" json:"google_application_default"`
	JSONKeyString      string `toml:"google_json_key_string" json:"google_json_key_string"`
	JSONKeyLocation    string `toml:"google_json_key_location" json:"google_json_key_location"`
}

// RedisConfig holds configuration for Redis
type RedisConfig struct {
	URL              TomlURL
	Sentinel         []TomlURL
	SentinelMaster   string
	SentinelUsername string
	SentinelPassword string
	Password         string
	DB               *int
	MaxIdle          *int
	MaxActive        *int
}

// SentinelConfig contains configuration options specifically for Sentinel
type SentinelConfig struct {
	TLS *TLSConfig `toml:"tls" json:"tls"`
}

// ImageResizerConfig holds configuration for the image resizer
type ImageResizerConfig struct {
	MaxScalerProcs uint32 `toml:"max_scaler_procs" json:"max_scaler_procs"`
	MaxScalerMem   uint64 `toml:"max_scaler_mem" json:"max_scaler_mem"`
	MaxFilesize    uint64 `toml:"max_filesize" json:"max_filesize"`
}

// MetadataConfig holds configuration for metadata processing
type MetadataConfig struct {
	ZipReaderLimitBytes int64 `toml:"zip_reader_limit_bytes"`
}

// TLSConfig holds TLS configuration settings
type TLSConfig struct {
	Certificate   string `toml:"certificate" json:"certificate"`
	Key           string `toml:"key" json:"key"`
	CACertificate string `toml:"ca_certificate" json:"ca_certificate"`
	MinVersion    string `toml:"min_version" json:"min_version"`
	MaxVersion    string `toml:"max_version" json:"max_version"`
}

// ListenerConfig holds configuration for network listeners
type ListenerConfig struct {
	Network string     `toml:"network" json:"network"`
	Addr    string     `toml:"addr" json:"addr"`
	TLS     *TLSConfig `toml:"tls" json:"tls"`
}

// Config holds the overall application configuration
type Config struct {
	ConfigCommand                string                   `toml:"config_command,omitempty" json:"config_command"`
	Redis                        *RedisConfig             `toml:"redis" json:"redis"`
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
	ObjectStorageCredentials     ObjectStorageCredentials `toml:"object_storage" json:"object_storage"`
	PropagateCorrelationID       bool                     `toml:"-"`
	ImageResizerConfig           ImageResizerConfig       `toml:"image_resizer" json:"image_resizer"`
	MetadataConfig               MetadataConfig           `toml:"metadata" json:"metadata"`
	AltDocumentRoot              string                   `toml:"alt_document_root" json:"alt_document_root"`
	ShutdownTimeout              TomlDuration             `toml:"shutdown_timeout" json:"shutdown_timeout"`
	TrustedCIDRsForXForwardedFor []string                 `toml:"trusted_cidrs_for_x_forwarded_for" json:"trusted_cidrs_for_x_forwarded_for"`
	TrustedCIDRsForPropagation   []string                 `toml:"trusted_cidrs_for_propagation" json:"trusted_cidrs_for_propagation"`
	Listeners                    []ListenerConfig         `toml:"listeners" json:"listeners"`
	MetricsListener              *ListenerConfig          `toml:"metrics_listener" json:"metrics_listener"`
	Sentinel                     *SentinelConfig          `toml:"Sentinel" json:"Sentinel"`
}

// DefaultImageResizerConfig contains default settings for the image resizer
var DefaultImageResizerConfig = ImageResizerConfig{
	MaxScalerProcs: uint32(math.Max(2, float64(runtime.NumCPU())/2)),
	MaxFilesize:    250 * 1000, // 250kB,
}

// DefaultMetadataConfig contains default settings for metadata processing
var DefaultMetadataConfig = MetadataConfig{
	ZipReaderLimitBytes: 100 * Megabyte,
}

// NewDefaultConfig creates a new configuration with default values
func NewDefaultConfig() *Config {
	return &Config{
		ImageResizerConfig: DefaultImageResizerConfig,
		MetadataConfig:     DefaultMetadataConfig,
	}
}

// LoadConfigFromFile reads configuration from a specified file
func LoadConfigFromFile(file *string) (*Config, error) {
	tomlData := ""

	if *file != "" {
		buf, err := os.ReadFile(*file)
		if err != nil {
			return nil, fmt.Errorf("file: %v", err)
		}
		tomlData = string(buf)
	}

	return LoadConfig(tomlData)
}

// LoadConfig loads configuration from a TOML string
func LoadConfig(data string) (*Config, error) {
	cfg := NewDefaultConfig()

	if _, err := toml.Decode(data, cfg); err != nil {
		return nil, err
	}

	if cfg.ConfigCommand != "" {
		cmd, args := splitCommand(cfg.ConfigCommand)
		output, err := exec.Command(cmd, args...).Output()
		if err != nil {
			var exitErr *exec.ExitError
			if errors.As(err, &exitErr) {
				return cfg, fmt.Errorf("running config command: %w, stderr: %q", err, string(exitErr.Stderr))
			}

			return cfg, fmt.Errorf("running config command: %w", err)
		}

		if err := json.Unmarshal(output, &cfg); err != nil {
			return cfg, fmt.Errorf("unmarshalling generated config: %w", err)
		}
	}

	return cfg, nil
}

// RegisterGoCloudURLOpeners registers URL openers for GoCloud storage providers
func (c *Config) RegisterGoCloudURLOpeners() error {
	c.ObjectStorageConfig.URLMux = new(blob.URLMux)

	creds := c.ObjectStorageCredentials
	if strings.EqualFold(creds.Provider, "AzureRM") && creds.AzureCredentials.AccountName != "" {
		urlOpener := creds.AzureCredentials.getURLOpener()
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

func (creds *AzureCredentials) getURLOpener() *azureblob.URLOpener {
	serviceURLOptions := azureblob.ServiceURLOptions{
		AccountName: creds.AccountName,
	}

	clientFunc := func(svcURL azureblob.ServiceURL, containerName azureblob.ContainerName) (*container.Client, error) {
		containerURL := fmt.Sprintf("%s/%s", svcURL, containerName)

		if creds.AccountKey != "" {
			sharedKeyCred, err := azblob.NewSharedKeyCredential(creds.AccountName, creds.AccountKey)
			if err != nil {
				return nil, fmt.Errorf("error creating Azure credentials: %w", err)
			}
			return container.NewClientWithSharedKeyCredential(containerURL, sharedKeyCred, &container.ClientOptions{})
		}

		creds, err := azidentity.NewDefaultAzureCredential(nil)
		if err != nil {
			return nil, fmt.Errorf("error creating default Azure credentials: %w", err)
		}

		return container.NewClient(containerURL, creds, nil)
	}

	return &azureblob.URLOpener{
		MakeClient:        clientFunc,
		ServiceURLOptions: serviceURLOptions,
	}
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

func splitCommand(cmd string) (string, []string) {
	cmdAndArgs := strings.Split(cmd, " ")

	return cmdAndArgs[0], cmdAndArgs[1:]
}
