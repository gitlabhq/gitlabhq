package objectstore

import (
	"testing"

	"github.com/stretchr/testify/require"
)

func TestStrategyName(t *testing.T) {
	tests := []struct {
		name     string
		strategy uploadStrategy
		want     string
	}{
		{name: "object", strategy: &Object{}, want: "presigned_put"},
		{name: "gocloud", strategy: &GoCloudObject{}, want: "gocloud"},
		{name: "multipart", strategy: &Multipart{}, want: "multipart"},
		{name: "s3v2", strategy: &S3v2Object{}, want: "s3v2"},
	}

	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			require.Equal(t, tt.want, tt.strategy.Strategy())
		})
	}
}
