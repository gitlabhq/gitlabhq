---
name: CI runners
external_docs: https://docs.gitlab.com/api/runners/
---
> [!warning]
> Registering a runner with a registration token is
> [deprecated](https://gitlab.com/gitlab-org/gitlab/-/issues/380872) and disabled by default in
> GitLab 17.0 and later.

Use this API to register a [runner](../../../../doc/ci/runners/_index.md) with an instance, verify its
authentication, reset its authentication token, and unregister it. GitLab Runner uses these endpoints
itself.

To create a runner, or to manage runners that already exist, use the Runners endpoints.
