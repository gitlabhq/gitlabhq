---
name: GLQL
external_docs: https://docs.gitlab.com/api/glql/
---
Use this API to execute [GitLab Query Language (GLQL)](../../../../doc/user/glql/_index.md) queries
programmatically. GLQL provides a simplified query language to search and filter
[GitLab resources](../../../../doc/user/glql/_index.md#supported-areas) such as issues, merge requests,
and epics across projects and groups.

The group or project must allow access to its data. For private groups and projects, you must
authenticate with a [personal access token](../../../../doc/user/profile/personal_access_tokens.md)
that has the appropriate permissions.
