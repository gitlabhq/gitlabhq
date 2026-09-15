---
name: Resource events
external_docs: https://docs.gitlab.com/api/resource_label_events/
---
Use this API to retrieve the events that track changes to issues, merge requests, and epics:

- [Label](../../../../doc/user/project/labels.md) events record who added or removed a label, and when.
- [Iteration](../../../../doc/user/group/iterations/_index.md) events record iteration changes for issues.
- Milestone events record milestone changes for issues and merge requests.
- State events record state changes for issues, merge requests, and epics.
- Weight events record weight changes for issues.

State events do not track the initial state (`created` or `opened`) of a resource. For a resource
that was never closed or reopened, an empty list is returned.
