---
name: Push rules
external_docs: https://docs.gitlab.com/api/group_push_rules/
---
Use this API to manage [push rules](../../../../doc/user/project/repository/push_rules.md) for
a project, and [group push rules](../../../../doc/user/project/repository/push_rules.md#group-push-rules)
that apply to newly created projects in a group.

Managing group push rules requires the Owner role for the group, or administrator access to the
instance.

> [!note]
> GitLab uses [RE2 syntax](https://github.com/google/re2/wiki/Syntax) for all regular expressions in push rules.
