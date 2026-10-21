---
name: Work items
external_docs: https://docs.gitlab.com/user/work_items/
---
Use this API to manage [work items](../../../../doc/user/work_items/_index.md) in a project, a group,
or a namespace. Work items are the core elements for planning and tracking work, and cover
[types](../../../../doc/user/work_items/_index.md#work-item-types) such as issues, tasks, and epics.

Alongside the work items themselves, you can retrieve their children, linked items, linked resources,
notes, discussions, emoji reactions, email participants, and the current user's to-do items.

By default, responses include only the `id`, `iid`, `global_id`, and `title` of each work item.
Use the `fields` and `features` parameters to request more attributes.

> [!note]
> The availability of these endpoints is controlled by the `work_item_rest_api` feature flag.
> They are available for testing, but not ready for production use. While the flag is disabled,
> every endpoint except the list endpoints returns `404 Not Found`.
