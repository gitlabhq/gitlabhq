# ErrorTrackingOpenAPI::EventsApi

All URIs are relative to *https://localhost/errortracking/api/v1*

| Method | HTTP request | Description |
| ------ | ------------ | ----------- |
| [**list_events**](EventsApi.md#list_events) | **GET** /projects/{projectId}/errors/{fingerprint}/events | Get information about the events related to the error |
| [**projects_api_project_id_envelope_post**](EventsApi.md#projects_api_project_id_envelope_post) | **POST** /projects/api/{projectId}/envelope | Ingestion endpoint for error events sent from client SDKs |
| [**projects_api_project_id_store_post**](EventsApi.md#projects_api_project_id_store_post) | **POST** /projects/api/{projectId}/store | Ingestion endpoint for error events sent from client SDKs |


## list_events

> <Array<ErrorEvent>> list_events(project_id, fingerprint, opts)

Get information about the events related to the error

### Examples

```ruby
require 'time'
require 'error_tracking_open_api'
# setup authorization
ErrorTrackingOpenAPI.configure do |config|
  # Configure API key authorization: internalToken
  config.api_key['internalToken'] = 'YOUR API KEY'
  # Uncomment the following line to set a prefix for the API key, e.g. 'Bearer' (defaults to nil)
  # config.api_key_prefix['internalToken'] = 'Bearer'
end

api_instance = ErrorTrackingOpenAPI::EventsApi.new
project_id = 56 # Integer | ID of the project where the error was created
fingerprint = 56 # Integer | ID of the error within the project
opts = {
  sort: 'occurred_at_asc', # String | 
  cursor: 'cursor_example', # String | Base64 encoded information for pagination
  limit: 56 # Integer | Number of entries to return
}

begin
  # Get information about the events related to the error
  result = api_instance.list_events(project_id, fingerprint, opts)
  p result
rescue ErrorTrackingOpenAPI::ApiError => e
  puts "Error when calling EventsApi->list_events: #{e}"
end
```

#### Using the list_events_with_http_info variant

This returns an Array which contains the response data, status code and headers.

> <Array(<Array<ErrorEvent>>, Integer, Hash)> list_events_with_http_info(project_id, fingerprint, opts)

```ruby
begin
  # Get information about the events related to the error
  data, status_code, headers = api_instance.list_events_with_http_info(project_id, fingerprint, opts)
  p status_code # => 2xx
  p headers # => { ... }
  p data # => <Array<ErrorEvent>>
rescue ErrorTrackingOpenAPI::ApiError => e
  puts "Error when calling EventsApi->list_events_with_http_info: #{e}"
end
```

### Parameters

| Name | Type | Description | Notes |
| ---- | ---- | ----------- | ----- |
| **project_id** | **Integer** | ID of the project where the error was created |  |
| **fingerprint** | **Integer** | ID of the error within the project |  |
| **sort** | **String** |  | [optional][default to &#39;occurred_at_asc&#39;] |
| **cursor** | **String** | Base64 encoded information for pagination | [optional] |
| **limit** | **Integer** | Number of entries to return | [optional][default to 20] |

### Return type

[**Array&lt;ErrorEvent&gt;**](ErrorEvent.md)

### Authorization

[internalToken](../README.md#internalToken)

### HTTP request headers

- **Content-Type**: Not defined
- **Accept**: */*


## projects_api_project_id_envelope_post

> <ErrorEvent> projects_api_project_id_envelope_post(project_id)

Ingestion endpoint for error events sent from client SDKs

### Examples

```ruby
require 'time'
require 'error_tracking_open_api'
# setup authorization
ErrorTrackingOpenAPI.configure do |config|
  # Configure API key authorization: internalToken
  config.api_key['internalToken'] = 'YOUR API KEY'
  # Uncomment the following line to set a prefix for the API key, e.g. 'Bearer' (defaults to nil)
  # config.api_key_prefix['internalToken'] = 'Bearer'
end

api_instance = ErrorTrackingOpenAPI::EventsApi.new
project_id = 56 # Integer | ID of the project where the error was created

begin
  # Ingestion endpoint for error events sent from client SDKs
  result = api_instance.projects_api_project_id_envelope_post(project_id)
  p result
rescue ErrorTrackingOpenAPI::ApiError => e
  puts "Error when calling EventsApi->projects_api_project_id_envelope_post: #{e}"
end
```

#### Using the projects_api_project_id_envelope_post_with_http_info variant

This returns an Array which contains the response data, status code and headers.

> <Array(<ErrorEvent>, Integer, Hash)> projects_api_project_id_envelope_post_with_http_info(project_id)

```ruby
begin
  # Ingestion endpoint for error events sent from client SDKs
  data, status_code, headers = api_instance.projects_api_project_id_envelope_post_with_http_info(project_id)
  p status_code # => 2xx
  p headers # => { ... }
  p data # => <ErrorEvent>
rescue ErrorTrackingOpenAPI::ApiError => e
  puts "Error when calling EventsApi->projects_api_project_id_envelope_post_with_http_info: #{e}"
end
```

### Parameters

| Name | Type | Description | Notes |
| ---- | ---- | ----------- | ----- |
| **project_id** | **Integer** | ID of the project where the error was created |  |

### Return type

[**ErrorEvent**](ErrorEvent.md)

### Authorization

[internalToken](../README.md#internalToken)

### HTTP request headers

- **Content-Type**: Not defined
- **Accept**: */*


## projects_api_project_id_store_post

> <ErrorEvent> projects_api_project_id_store_post(project_id)

Ingestion endpoint for error events sent from client SDKs

### Examples

```ruby
require 'time'
require 'error_tracking_open_api'
# setup authorization
ErrorTrackingOpenAPI.configure do |config|
  # Configure API key authorization: internalToken
  config.api_key['internalToken'] = 'YOUR API KEY'
  # Uncomment the following line to set a prefix for the API key, e.g. 'Bearer' (defaults to nil)
  # config.api_key_prefix['internalToken'] = 'Bearer'
end

api_instance = ErrorTrackingOpenAPI::EventsApi.new
project_id = 56 # Integer | ID of the project where the error was created

begin
  # Ingestion endpoint for error events sent from client SDKs
  result = api_instance.projects_api_project_id_store_post(project_id)
  p result
rescue ErrorTrackingOpenAPI::ApiError => e
  puts "Error when calling EventsApi->projects_api_project_id_store_post: #{e}"
end
```

#### Using the projects_api_project_id_store_post_with_http_info variant

This returns an Array which contains the response data, status code and headers.

> <Array(<ErrorEvent>, Integer, Hash)> projects_api_project_id_store_post_with_http_info(project_id)

```ruby
begin
  # Ingestion endpoint for error events sent from client SDKs
  data, status_code, headers = api_instance.projects_api_project_id_store_post_with_http_info(project_id)
  p status_code # => 2xx
  p headers # => { ... }
  p data # => <ErrorEvent>
rescue ErrorTrackingOpenAPI::ApiError => e
  puts "Error when calling EventsApi->projects_api_project_id_store_post_with_http_info: #{e}"
end
```

### Parameters

| Name | Type | Description | Notes |
| ---- | ---- | ----------- | ----- |
| **project_id** | **Integer** | ID of the project where the error was created |  |

### Return type

[**ErrorEvent**](ErrorEvent.md)

### Authorization

[internalToken](../README.md#internalToken)

### HTTP request headers

- **Content-Type**: Not defined
- **Accept**: */*

