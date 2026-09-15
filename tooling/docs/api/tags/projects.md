---
name: Projects
external_docs: https://docs.gitlab.com/api/projects/
---
Use this API to manage [projects](../../../../doc/user/project/_index.md) and the resources they contain, including:

- Project settings, visibility, access permissions, and security settings.
- Archiving, transferring, [forking](../../../../doc/user/project/repository/forking_workflow.md), and [starring](../../../../doc/user/project/working_with_projects.md) projects.
- Project [issues](../../../../doc/user/project/issues/_index.md), issue statistics, and project statistics.
- [Markdown uploads](../../../../doc/security/user_file_uploads.md) referenced in issues, merge requests, snippets, or wiki pages.
- Protection rules for [container image tags](../../../../doc/user/packages/container_registry/protected_container_tags.md), container repositories, and [packages](../../../../doc/user/packages/package_registry/package_protection_rules.md).

If a user is not a member of a private project, a `GET` request on that project results in a
`404` status code.
