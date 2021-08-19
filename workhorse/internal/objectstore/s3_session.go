package objectstore

import (
	"sync"
	"time"

	"github.com/aws/aws-sdk-go/aws"
	"github.com/aws/aws-sdk-go/aws/credentials"
	"github.com/aws/aws-sdk-go/aws/session"

	"gitlab.com/gitlab-org/gitlab/workhorse/internal/config"
)

type s3Session struct {
	session *session.Session
	expiry  time.Time
}

type s3SessionCache struct {
	// An S3 session is cached by its input configuration (e.g. region,
	// endpoint, path style, etc.), but the bucket is actually
	// determined by the type of object to be uploaded (e.g. CI
	// artifact, LFS, etc.) during runtime. In practice, we should only
	// need one session per Workhorse process if we only allow one
	// configuration for many different buckets. However, using a map
	// indexed by the config avoids potential pitfalls in case the
	// bucket configuration is supplied at startup or we need to support
	// multiple S3 endpoints.
	sessions map[config.S3Config]*s3Session
	sync.Mutex
}

func (s *s3Session) isExpired() bool {
	return time.Now().After(s.expiry)
}

func newS3SessionCache() *s3SessionCache {
	return &s3SessionCache{sessions: make(map[config.S3Config]*s3Session)}
}

var (
	// By default, it looks like IAM instance profiles may last 6 hours
	// (via curl http://169.254.169.254/latest/meta-data/iam/security-credentials/<role_name>),
	// but this may be configurable from anywhere for 15 minutes to 12
	// hours. To be safe, refresh AWS sessions every 10 minutes.
	sessionExpiration = time.Duration(10 * time.Minute)
	sessionCache      = newS3SessionCache()
)

// SetupS3Session initializes a new AWS S3 session and refreshes one if
// necessary. As recommended in https://docs.aws.amazon.com/sdk-for-go/v1/developer-guide/sessions.html,
// sessions should be cached when possible. Sessions are safe to use
// concurrently as long as the session isn't modified.
func setupS3Session(s3Credentials config.S3Credentials, s3Config config.S3Config) (*session.Session, error) {
	sessionCache.Lock()
	defer sessionCache.Unlock()

	if s, ok := sessionCache.sessions[s3Config]; ok && !s.isExpired() {
		return s.session, nil
	}

	cfg := &aws.Config{
		Region:           aws.String(s3Config.Region),
		S3ForcePathStyle: aws.Bool(s3Config.PathStyle),
	}

	// In case IAM profiles aren't being used, use the static credentials
	if s3Credentials.AwsAccessKeyID != "" && s3Credentials.AwsSecretAccessKey != "" {
		cfg.Credentials = credentials.NewStaticCredentials(s3Credentials.AwsAccessKeyID, s3Credentials.AwsSecretAccessKey, "")
	}

	if s3Config.Endpoint != "" {
		cfg.Endpoint = aws.String(s3Config.Endpoint)
	}

	sess, err := session.NewSession(cfg)
	if err != nil {
		return nil, err
	}

	sessionCache.sessions[s3Config] = &s3Session{
		expiry:  time.Now().Add(sessionExpiration),
		session: sess,
	}

	return sess, nil
}

func ResetS3Session(s3Config config.S3Config) {
	sessionCache.Lock()
	defer sessionCache.Unlock()

	delete(sessionCache.sessions, s3Config)
}
