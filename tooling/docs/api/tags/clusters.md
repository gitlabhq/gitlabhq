---
name: Clusters
external_docs: https://docs.gitlab.com/api/instance_clusters/
---
> [!warning]
> These certificate-based cluster endpoints are [deprecated](https://gitlab.com/groups/gitlab-org/configure/-/work_items/8).

Use this API to manage and discover the certificate-based Kubernetes clusters of an
[instance](../../../../doc/user/instance/clusters/_index.md), a
[group](../../../../doc/user/group/clusters/_index.md), or a
[project](../../../../doc/user/project/clusters/_index.md). Connecting a cluster to a group or an
instance lets you use the same cluster across multiple projects.

Instance endpoints require administrator access. Group and project endpoints require the Maintainer
or Owner role.
