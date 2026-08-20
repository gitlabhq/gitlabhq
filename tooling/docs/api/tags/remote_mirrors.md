---
name: Remote mirrors
external_docs: https://docs.gitlab.com/api/remote_mirrors/
---
Use this API to manage [remote mirrors](../../../../doc/user/project/repository/mirror/push.md).
You can query and modify the state of these mirrors.

For security reasons, the `url` attribute in the API response is always scrubbed of username
and password information.

> [!note]
> [Pull mirrors](../../../../doc/user/project/repository/mirror/pull.md) use
> [a different API endpoint](../../../../doc/api/project_pull_mirroring.md#update-project-pull-mirroring-settings) to
> display and update them.
