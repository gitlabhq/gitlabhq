---
name: Boards
external_docs: https://docs.gitlab.com/api/boards/
---
Use this API to manage [issue boards](../../../../doc/user/project/issue_board.md) and their lists, for both projects and [groups](../../../../doc/user/project/issue_board.md#group-issue-boards).

Every call to this API requires authentication. If the project or group is private and the
authenticated user is not a member, a `GET` request results in a `404` status code.
