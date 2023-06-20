# ErrorTrackingOpenAPI::Error

## Properties

| Name | Type | Description | Notes |
| ---- | ---- | ----------- | ----- |
| **fingerprint** | **Integer** |  | [optional] |
| **project_id** | **Integer** |  | [optional] |
| **name** | **String** |  | [optional] |
| **description** | **String** |  | [optional] |
| **actor** | **String** |  | [optional] |
| **event_count** | **Integer** |  | [optional] |
| **approximated_user_count** | **Integer** |  | [optional] |
| **last_seen_at** | **Time** |  | [optional] |
| **first_seen_at** | **Time** |  | [optional] |
| **status** | **String** | Status of the error | [optional] |
| **stats** | [**ErrorStats**](ErrorStats.md) |  | [optional] |

## Example

```ruby
require 'error_tracking_open_api'

instance = ErrorTrackingOpenAPI::Error.new(
  fingerprint: null,
  project_id: null,
  name: ActionView::MissingTemplate,
  description: Missing template posts/edit,
  actor: PostsController#edit,
  event_count: null,
  approximated_user_count: null,
  last_seen_at: null,
  first_seen_at: null,
  status: null,
  stats: null
)
```

