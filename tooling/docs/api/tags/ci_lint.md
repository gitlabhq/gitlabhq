---
name: CI lint
external_docs: https://docs.gitlab.com/api/lint/
---
Use this API to [validate a GitLab CI/CD configuration](../../../../doc/ci/yaml/lint.md).

These endpoints take JSON-encoded YAML content. To preserve the formatting of your CI/CD
configuration, it can help to escape and encode the YAML with a third-party tool such as
[`jq`](https://jqlang.org/) before you make the request.
