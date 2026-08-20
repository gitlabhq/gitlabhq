---
name: Project import
external_docs: https://docs.gitlab.com/api/project_import_export/
---
Use this API to [import repositories from external sources](../../../../doc/user/import/_index.md)
and to [migrate a project](../../../../doc/user/project/settings/import_export.md) between
GitLab instances.

If you first migrate the parent group structure with the
[group import and export API](../../../../doc/api/group_import_export.md), you can preserve
relationships that span the group, such as connections between project issues and group epics.
After an import, use the [project-level CI/CD variables API](../../../../doc/api/project_level_variables.md)
to restore CI/CD variables. You must still migrate your
[container registry](../../../../doc/user/packages/container_registry/_index.md) over a series of
Docker pulls and pushes, and re-run any CI/CD pipelines to retrieve build artifacts.

The project relations export endpoints are used by the destination instance during
[group migration by direct transfer](../../../../doc/user/group/import/_index.md) to migrate a
project structure, and you don't usually need to call them yourself. In this context, a relation is
an exportable item such as a merge request, including any related items such as a label.

> [!note]
> User contribution mapping is not supported when you import projects to a
> [personal namespace](../../../../doc/user/namespace/_index.md#types-of-namespaces). All
> contributions are assigned to the personal namespace owner and cannot be reassigned.
