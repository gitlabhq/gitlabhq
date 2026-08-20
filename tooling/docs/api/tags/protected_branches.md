---
name: Protected branches
external_docs: https://docs.gitlab.com/api/protected_branches/
---
Use this API to manage [protected branches](../../../../doc/user/project/repository/branches/protected.md)
for a project, and the [protected branch settings](../../../../doc/user/project/repository/branches/protected.md#in-a-group)
that all projects in a group inherit.

GitLab Premium and GitLab Ultimate support more granular protections for pushing to branches.
Administrators can grant permission to modify and push to protected branches only to deploy keys,
instead of specific users.

> [!warning]
> Group protected branch settings are restricted to top-level groups. They support only
> [valid access levels](../../../../doc/api/group_protected_branches.md#valid-access-levels),
> and cannot name individual users or groups.
