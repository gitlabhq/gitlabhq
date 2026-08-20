---
name: Events
external_docs: https://docs.gitlab.com/api/events/
---
Use this API to review event activity for a user, a project, or an instance. Events cover a wide
range of actions, such as joining a project, commenting on an issue, pushing changes to a merge
request, or closing an epic.

Activity is subject to retention limits. For more information, see the
[user activity time period limit](../../../../doc/user/profile/contributions_calendar.md#event-time-period-limit)
and the [project activity time period limit](../../../../doc/user/project/working_with_projects.md#view-project-activity).

These endpoints have some limitations:

- Some epic features, such as child items, linked items, start dates, due dates, and health statuses, are not returned.
- Some merge request notes use the `DiscussionNote` type instead, which is [not supported](../../../../doc/api/discussions.md#understand-note-types-in-the-api).
- Bulk push events, created when a push exceeds the [push event activities limit](../../../../doc/administration/settings/push_event_activities_limit.md), are returned with limited details.
