---
name: Group import and export
external_docs: https://docs.gitlab.com/api/group_import_export/
---
Use this API to [migrate a group structure](../../../../doc/user/group/import/_index.md) by exporting
and importing a file. When you use it with the
[project import and export API](../../../../doc/api/project_import_export.md), you can
preserve relationships that span the group, such as connections between project issues and group
epics. Run the group export and import first, then import the project exports into the group
structure.

A group export includes group milestones, boards, labels, badges, members, events, wikis (Premium
and Ultimate only), and subgroups. Each subgroup includes all of the same data.

To preserve the member list and permissions of an imported group, make sure those users exist on the
destination instance before you import.

Because of [issue 405168](https://gitlab.com/gitlab-org/gitlab/-/issues/405168), imported groups have
a `private` visibility level unless you import them into a parent group. By default, groups imported
into a parent group inherit the visibility of the parent.

The destination instance uses the group relations export endpoints during
[group migration by direct transfer](../../../../doc/user/group/import/_index.md). You don't
usually need to call them yourself. In this context, a relation is an exportable item such as an
epic, including any related items such as a label. These endpoints require your instance to meet certain
[prerequisites](../../../../doc/user/group/import/direct_transfer_migrations.md#prerequisites),
and can't be used with the file-based export and import endpoints.
