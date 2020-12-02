package config

import (
	"context"
	"net/url"
	"testing"

	"github.com/stretchr/testify/require"
	"gocloud.dev/blob/azureblob"
)

func TestURLOpeners(t *testing.T) {
	cfg, err := LoadConfig(azureConfig)
	require.NoError(t, err)

	require.NotNil(t, cfg.ObjectStorageCredentials, "Expected object storage credentials")

	require.NoError(t, cfg.RegisterGoCloudURLOpeners())
	require.NotNil(t, cfg.ObjectStorageConfig.URLMux)

	tests := []struct {
		url   string
		valid bool
	}{

		{
			url:   "azblob://container/object",
			valid: true,
		},
		{
			url:   "azblob://container/object?domain=core.windows.net",
			valid: true,
		},
		{
			url:   "azblob://container/object?domain=core.windows.net&domain=test",
			valid: false,
		},
		{
			url:   "azblob://container/object?param=value",
			valid: false,
		},
		{
			url:   "s3://bucket/object",
			valid: false,
		},
	}

	for _, test := range tests {
		t.Run(test.url, func(t *testing.T) {
			ctx := context.Background()
			url, err := url.Parse(test.url)
			require.NoError(t, err)

			bucket, err := cfg.ObjectStorageConfig.URLMux.OpenBucketURL(ctx, url)
			if bucket != nil {
				defer bucket.Close()
			}

			if test.valid {
				require.NotNil(t, bucket)
				require.NoError(t, err)
			} else {
				require.Error(t, err)
			}
		})
	}
}

func TestTestURLOpenersForParams(t *testing.T) {
	tests := []struct {
		name     string
		currOpts azureblob.Options
		query    url.Values
		wantOpts azureblob.Options
		wantErr  bool
	}{
		{
			name: "InvalidParam",
			query: url.Values{
				"foo": {"bar"},
			},
			wantErr: true,
		},
		{
			name: "StorageDomain",
			query: url.Values{
				"domain": {"blob.core.usgovcloudapi.net"},
			},
			wantOpts: azureblob.Options{StorageDomain: "blob.core.usgovcloudapi.net"},
		},
		{
			name: "duplicate StorageDomain",
			query: url.Values{
				"domain": {"blob.core.usgovcloudapi.net", "blob.core.windows.net"},
			},
			wantErr: true,
		},
	}

	for _, test := range tests {
		t.Run(test.name, func(t *testing.T) {
			o := &azureURLOpener{
				URLOpener: &azureblob.URLOpener{
					Options: test.currOpts,
				},
			}
			err := setOptionsFromURLParams(test.query, &o.Options)

			if test.wantErr {
				require.NotNil(t, err)
			} else {
				require.Nil(t, err)
				require.Equal(t, test.wantOpts, o.Options)
			}
		})
	}
}
