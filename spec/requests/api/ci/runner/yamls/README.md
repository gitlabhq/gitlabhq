# .gitlab-ci.yml end-to-end tests

The purpose of this folder is to provide a single job `.gitlab-ci.yml`
that will be validated against end-to-end response that is send to runner.

This allows to easily test end-to-end all CI job transformation that
and impact on how such job is rendered to be executed by the GitLab Runner.

```yaml
gitlab_ci:
  # .gitlab-ci.yml to stub

request_response:
  # exact payload that is checked as returned by `/api/v4/jobs/request`
```
