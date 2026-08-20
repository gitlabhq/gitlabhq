---
name: Merge trains
external_docs: https://docs.gitlab.com/api/merge_trains/
---
Use this API to retrieve the [merge trains](../../../../doc/ci/pipelines/merge_trains.md) of a
project. These endpoints require the Developer, Maintainer, or Owner role, and support
[offset-based pagination](../../../../doc/api/rest/_index.md#offset-based-pagination).

Each object in a response represents one merge request in a train, not an entire train. Requesting
merge trains without a target branch can return entries from more than one train in the project.

Responses do not include an explicit queue position, and return merge requests as a flat list rather
than grouped by train:

- For an exact queue position, sort by `id` in ascending order, or use the GraphQL API
  [`MergeTrainCar.index`](../../../../doc/api/graphql/reference/_index.md#mergetraincar-index) field.
- To group merge requests by train, use the `target_branch` attribute, or query the GraphQL API
  [`Project.mergeTrains`](../../../../doc/api/graphql/reference/_index.md#projectmergetrains) and
  [`MergeTrain.cars`](../../../../doc/api/graphql/reference/_index.md#mergetraincars) fields.
