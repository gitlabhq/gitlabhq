---
name: Vulnerabilities
external_docs: https://docs.gitlab.com/api/vulnerabilities/
---
> [!warning]
> These endpoints are in the process of being deprecated and are considered unstable.
> The response payload may be subject to change or breakage across GitLab releases. Use the
> [GraphQL API](../../../../doc/api/graphql/reference/_index.md#queryvulnerabilities) instead.
> For more information, see [replace vulnerability REST API with GraphQL](../../../../doc/api/vulnerabilities.md#replace-vulnerability-rest-api-with-graphql).

Use this API to manage [vulnerabilities](../../../../doc/user/application_security/vulnerabilities/_index.md),
retrieve vulnerability findings, and export [vulnerability reports](../../../../doc/user/application_security/vulnerability_report/_index.md)
for a project, group, or instance.

Every call to these endpoints must be [authenticated](../../../../doc/api/rest/authentication.md).
If a user isn't a member of a private project, requests return a `404 Not Found` status code. If a
user does not have permission to [view the vulnerability report](../../../../doc/user/permissions.md#project-application-security),
requests return a `403 Forbidden` status code.

> [!note]
> The former Vulnerabilities API was renamed to the Vulnerability Findings API, and the
> Vulnerabilities name now serves [vulnerability objects](https://gitlab.com/gitlab-org/gitlab/-/issues/13561).
> To fix a broken integration with the former API, change the `vulnerabilities` URL part to
> `vulnerability_findings`.
