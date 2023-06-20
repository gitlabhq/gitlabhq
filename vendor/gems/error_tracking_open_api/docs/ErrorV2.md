# ErrorTrackingOpenAPI::ErrorV2

## Properties

| Name | Type | Description | Notes |
| ---- | ---- | ----------- | ----- |
| **id** | **String** |  | [optional] |
| **project** | [**Project**](Project.md) |  | [optional] |
| **title** | **String** |  | [optional] |
| **actor** | **String** |  | [optional] |
| **count** | **String** |  | [optional] |
| **user_count** | **Integer** |  | [optional] |
| **last_seen** | **Time** |  | [optional] |
| **first_seen** | **Time** |  | [optional] |
| **status** | **String** | Status of the error | [optional] |

## Example

```ruby
require 'error_tracking_open_api'

instance = ErrorTrackingOpenAPI::ErrorV2.new(
  id: null,
  project: null,
  title: ActionView::MissingTemplate,
  actor: PostsController#edit,
  count: null,
  user_count: null,
  last_seen: null,
  first_seen: null,
  status: null
)
```

