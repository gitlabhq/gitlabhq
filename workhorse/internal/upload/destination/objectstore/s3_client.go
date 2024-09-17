package objectstore

import (
	"context"
	"sync"
	"time"

	"github.com/aws/aws-sdk-go-v2/aws"
	awsConfig "github.com/aws/aws-sdk-go-v2/config"
	"github.com/aws/aws-sdk-go-v2/credentials"
	"github.com/aws/aws-sdk-go-v2/service/s3"

	"gitlab.com/gitlab-org/gitlab/workhorse/internal/config"
)

type s3Client struct {
	client *s3.Client
	expiry time.Time
}

type s3ClientCache struct {
	// An S3 client is cached by its input configuration (e.g. region,
	// endpoint, path style, etc.), but the bucket is actually
	// determined by the type of object to be uploaded (e.g. CI
	// artifact, LFS, etc.) during runtime. In practice, we should only
	// need one client per Workhorse process if we only allow one
	// configuration for many different buckets. However, using a map
	// indexed by the config avoids potential pitfalls in case the
	// bucket configuration is supplied at startup or we need to support
	// multiple S3 endpoints.
	clients map[config.S3Config]*s3Client
	sync.Mutex
}

var (
	// By default, it looks like IAM instance profiles may last 6 hours
	// (via curl http://169.254.169.254/latest/meta-data/iam/security-credentials/<role_name>),
	// but this may be configurable from anywhere for 15 minutes to 12
	// hours. To be safe, refresh AWS clients every 10 minutes.
	clientExpiration = 10 * time.Minute
	clientCache      = &s3ClientCache{clients: make(map[config.S3Config]*s3Client)}
)

func (c *s3Client) isExpired() bool {
	return time.Now().After(c.expiry)
}

// setupS3Client initializes a new AWS S3 client and refreshes one if
// necessary. AWS SDK v2 appears to refreshes credentials automatically in
// s3.Client already, but let's retain the v1 behavior of caching
// the client in to ensure there isn't some behavior users are relying on
// some behavior, such as dynamically updating the user's credentials file.
// Better documentation is needed: https://github.com/aws/aws-sdk-go-v2/issues/2775
func setupS3Client(s3Credentials config.S3Credentials, s3Config config.S3Config) (*s3.Client, error) {
	clientCache.Lock()
	defer clientCache.Unlock()

	if c, ok := clientCache.clients[s3Config]; ok && !c.isExpired() {
		return c.client, nil
	}

	options := []func(*awsConfig.LoadOptions) error{
		awsConfig.WithRegion(s3Config.Region),
	}

	if s3Credentials.AwsAccessKeyID != "" && s3Credentials.AwsSecretAccessKey != "" {
		options = append(options,
			awsConfig.WithCredentialsProvider(
				credentials.NewStaticCredentialsProvider(s3Credentials.AwsAccessKeyID, s3Credentials.AwsSecretAccessKey, "")))
	}

	ctx, cancel := context.WithTimeout(context.Background(), 30*time.Second) // lint:allow context.Background
	defer cancel()

	cfg, err := awsConfig.LoadDefaultConfig(ctx, options...)
	if err != nil {
		return nil, err
	}

	client := s3.NewFromConfig(cfg, func(o *s3.Options) {
		if s3Config.Endpoint != "" {
			o.BaseEndpoint = aws.String(s3Config.Endpoint)
		}
		o.UsePathStyle = s3Config.PathStyle
	})

	clientCache.clients[s3Config] = &s3Client{
		client: client,
		expiry: time.Now().Add(clientExpiration),
	}

	return client, nil
}
