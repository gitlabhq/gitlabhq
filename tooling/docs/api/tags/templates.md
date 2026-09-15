---
name: Templates
external_docs: https://docs.gitlab.com/api/templates/dockerfiles/
---
Use this API to retrieve the file templates available to an entire instance:

- [Dockerfile templates](https://gitlab.com/gitlab-org/gitlab-foss/-/tree/master/vendor/Dockerfile)
- [`.gitignore` templates](https://git-scm.com/docs/gitignore)
- [CI/CD configuration templates](https://gitlab.com/gitlab-org/gitlab/-/tree/master/lib/gitlab/ci/templates)
- [Open source license templates](https://choosealicense.com/)

Custom CI/CD templates are not available from these endpoints. For templates specific to a project,
use the [project templates API](../../../../doc/api/project_templates.md).

Users with the Guest role can't access these templates. For more information, see
[project and group visibility](../../../../doc/user/public_access.md).
