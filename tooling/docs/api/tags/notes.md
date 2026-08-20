---
name: Notes
external_docs: https://docs.gitlab.com/api/notes/
---
Use this API to manage the comments and system records attached to GitLab content. You can:

- Create and modify comments on issues, merge requests, epics, snippets, commits, and wiki pages.
- Retrieve [system-generated notes](../../../../doc/user/project/system_notes.md) about object changes.
- Control visibility with confidential and internal flags.

Some system-generated notes are tracked as separate resource events instead, including
[label](../../../../doc/api/resource_label_events.md),
[state](../../../../doc/api/resource_state_events.md),
[milestone](../../../../doc/api/resource_milestone_events.md),
[weight](../../../../doc/api/resource_weight_events.md), and
[iteration](../../../../doc/api/resource_iteration_events.md) events.

By default, `GET` requests return 20 results at a time, because the results are
[paginated](../../../../doc/api/rest/_index.md#pagination).
