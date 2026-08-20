---
name: Badges
external_docs: https://docs.gitlab.com/api/group_badges/
---
Use this API to manage badges for [projects](../../../../doc/user/project/badges.md) and [groups](../../../../doc/user/project/badges.md#group-badges).

## Placeholders

Badges support placeholders that are replaced in real time in both the link and image URL.
The following placeholders are available:

- `%{project_path}`: replaced by the project path.
- `%{project_title}`: replaced by the project title.
- `%{project_name}`: replaced by the project name.
- `%{project_id}`: replaced by the project ID.
- `%{project_namespace}`: replaced by the project's namespace full path.
- `%{group_name}`: replaced by the project's top-level group name.
- `%{gitlab_server}`: replaced by the project's server name.
- `%{gitlab_pages_domain}`: replaced by the domain name hosting GitLab Pages.
- `%{default_branch}`: replaced by the project default branch.
- `%{commit_sha}`: replaced by the project's last commit SHA.
- `%{latest_tag}`: replaced by the project's last tag.

Group badge endpoints operate outside a project's context, so placeholder values are taken from the
group's earliest-created project. If no projects exist in the group, the URL is returned unchanged.
