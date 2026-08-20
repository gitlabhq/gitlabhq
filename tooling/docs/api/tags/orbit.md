---
name: Orbit
external_docs: https://docs.gitlab.com/api/orbit/
---
Use this API to serve repository and merge request content to
[GitLab Orbit](https://docs.gitlab.com/orbit/), which indexes a group's software development
lifecycle into a queryable knowledge graph. These endpoints expose project metadata, commits, changed
paths, blobs, repository archives, and merge request diffs, and redact sensitive values from the
content Orbit ingests.

These endpoints are internal and used by the GitLab Orbit service.

> [!note]
> The availability of these endpoints is controlled by a feature flag, and GitLab Orbit is in beta.
