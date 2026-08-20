---
name: Issues
external_docs: https://docs.gitlab.com/api/issues/
---
Use this API to manage [issues](../../../../doc/user/project/issues/_index.md), their
[links to related issues](../../../../doc/user/project/issues/related_issues.md), and issue
statistics. You can:

- Create, update, and delete issues.
- Manage issue metadata, like assignees, labels, milestones, and time tracking.
- Cross-reference issues and merge requests.
- Track issue movement and promotion between projects and epics.
- Retrieve statistics about issues.

If a user is not a member of a private project, a `GET` request on that project results in a `404`
status code.

> [!note]
> The `references.relative` attribute is relative to the group or project of the issue being requested.
> When an issue is fetched from its project, the `relative` format is the same as the `short` format.
> When requested across groups or projects, it's expected to be the same as the `full` format.
