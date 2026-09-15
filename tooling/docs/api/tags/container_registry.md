---
name: Container registry
external_docs: https://docs.gitlab.com/api/container_registry/
---
Use this API to manage the [GitLab container registry](../../../../doc/user/packages/container_registry/_index.md):
list the registry repositories in a project or a group, retrieve or delete individual repositories and
their tags, and receive registry events.

To authenticate with these endpoints from a CI/CD job, pass the [`$CI_JOB_TOKEN`](../../../../doc/ci/jobs/ci_job_token.md)
variable as the `JOB-TOKEN` header. The job token only has access to the container registry
of the project that created the pipeline.
