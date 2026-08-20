---
name: Epics
external_docs: https://docs.gitlab.com/api/group_epic_boards/
---
> [!warning]
> The Epics REST API was [deprecated](https://gitlab.com/gitlab-org/gitlab/-/issues/460668) in GitLab 17.0
> and is planned for removal in v5 of the API. From GitLab 17.4 to 18.0, if
> [the new look for epics](../../../../doc/user/group/epics/_index.md#epics-as-work-items) is enabled,
> or in GitLab 18.1 and later, use the Work Items API instead. For more information, see
> [migrate epic APIs to work items](../../../../doc/api/graphql/epic_work_items_api_migration_guide.md).
> This change is a breaking change.

Use this API to manage [epics](../../../../doc/user/group/epics/_index.md), the issues assigned to
them, their child and [related epics](../../../../doc/user/group/epics/linked_epics.md), and
[group epic boards](../../../../doc/user/group/epics/epic_boards.md).

Every call to this API must be authenticated. If a user is not a member of a private group, a `GET`
request on that group results in a `404` status code.

Epics are available only in GitLab [Premium and Ultimate](https://about.gitlab.com/pricing/). If the
Epics or Related Epics feature is not available, a `403` status code is returned.
