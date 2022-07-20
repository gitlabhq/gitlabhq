package gitaly

import "gitlab.com/gitlab-org/gitaly/v15/proto/go/gitalypb"

// NamespaceClient encapsulates NamespaceService calls
type NamespaceClient struct {
	gitalypb.NamespaceServiceClient
}
