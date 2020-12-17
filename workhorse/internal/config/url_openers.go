package config

import (
	"context"
	"fmt"
	"net/url"

	"gocloud.dev/blob"
	"gocloud.dev/blob/azureblob"
)

// This code can be removed once https://github.com/google/go-cloud/pull/2851 is merged.

// URLOpener opens Azure URLs like "azblob://mybucket".
//
// The URL host is used as the bucket name.
//
// The following query options are supported:
//  - domain: The domain name used to access the Azure Blob storage (e.g. blob.core.windows.net)
type azureURLOpener struct {
	*azureblob.URLOpener
}

func (o *azureURLOpener) OpenBucketURL(ctx context.Context, u *url.URL) (*blob.Bucket, error) {
	opts := new(azureblob.Options)
	*opts = o.Options

	err := setOptionsFromURLParams(u.Query(), opts)
	if err != nil {
		return nil, err
	}
	return azureblob.OpenBucket(ctx, o.Pipeline, o.AccountName, u.Host, opts)
}

func setOptionsFromURLParams(q url.Values, opts *azureblob.Options) error {
	for param, values := range q {
		if len(values) > 1 {
			return fmt.Errorf("multiple values of %v not allowed", param)
		}

		value := values[0]
		switch param {
		case "domain":
			opts.StorageDomain = azureblob.StorageDomain(value)
		default:
			return fmt.Errorf("unknown query parameter %q", param)
		}
	}

	return nil
}
