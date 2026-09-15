---
name: Storage moves
external_docs: https://docs.gitlab.com/api/group_repository_storage_moves/
---
Use this API to schedule and track [repository storage moves](../../../../doc/administration/operations/moving_repositories.md)
for groups, projects, and snippets. Project moves cover wiki and design repositories, and group
moves cover [group wikis](../../../../doc/user/project/wiki/group.md). Moving repositories
can help you [migrate to Gitaly Cluster (Praefect)](../../../../doc/administration/gitaly/praefect/_index.md#migrate-to-gitaly-cluster-praefect).

To ensure data integrity, GitLab places the group, project, or snippet in a temporary read-only
state for the duration of the move. During this time, users receive this message if they try to
push new commits:

```plaintext
The repository is temporarily read-only. Please try again later.
```

This API requires you to [authenticate yourself](../../../../doc/api/rest/authentication.md) as an administrator.

## States

As GitLab processes a storage move, it transitions through different states. Values of `state` are:

- `initial`: The record has been created, but the background job has not yet been scheduled.
- `scheduled`: The background job has been scheduled.
- `started`: The repositories are being copied to the destination storage.
- `replicated`: The repositories have been moved.
- `failed`: The repositories failed to copy, or the checksums did not match.
- `finished`: The repositories have been moved, and the repositories on the source storage have been deleted.
- `cleanup failed`: The repositories have been moved, but the repositories on the source storage could not be deleted.
