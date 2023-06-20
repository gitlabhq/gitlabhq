package gitaly

import "gitlab.com/gitlab-org/gitaly/v16/proto/go/gitalypb"

// NamespaceClient encapsulates NamespaceService calls
type NamespaceClient struct {
	gitalypb.NamespaceServiceClient
}
