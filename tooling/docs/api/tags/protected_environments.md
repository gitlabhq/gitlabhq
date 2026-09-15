---
name: Protected environments
external_docs: https://docs.gitlab.com/api/protected_environments/
---
Use this API to manage [protected environments](../../../../doc/ci/environments/protected_environments.md)
for a project, and [protected environments for a group](../../../../doc/ci/environments/protected_environments.md#protected-environments-for-groups)
for a group.

> [!note]
> The project endpoints require CI/CD to be turned on for the project. If
> [CI/CD is turned off](../../../../doc/user/project/settings/_index.md#turn-off-cicd-for-a-project),
> requests return `403 Forbidden`, even for users who otherwise have permission to manage protected
> environments.
