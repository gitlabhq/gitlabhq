---
name: Merge request approvals
external_docs: https://docs.gitlab.com/api/merge_request_approvals/
---
Use this API to manage [merge request approvals](../../../../doc/user/project/merge_requests/approvals/_index.md)
and the group and project [approval settings](../../../../doc/user/project/merge_requests/approvals/settings.md)
that govern them. All endpoints require authentication.

Endpoints to approve, unapprove, reset approvals, and retrieve approval state are available on all
tiers, including Free. All other endpoints require Premium or Ultimate, and each one shows its tier.

> [!note]
> The `merge_request_iid` and `id` path parameters must each be a single value.
> Passing multiple space-separated values (for example, `451 454 458`) is not
> supported and returns `400 Bad Request`. To act on multiple merge requests,
> make one request per merge request IID.
