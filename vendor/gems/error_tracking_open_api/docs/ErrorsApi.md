# ErrorTrackingOpenAPI::ErrorsApi

All URIs are relative to *https://localhost/errortracking/api/v1*

| Method | HTTP request | Description |
| ------ | ------------ | ----------- |
| [**get_error**](ErrorsApi.md#get_error) | **GET** /projects/{projectId}/errors/{fingerprint} | Get information about the error |
| [**list_errors**](ErrorsApi.md#list_errors) | **GET** /projects/{projectId}/errors | List of errors |
| [**list_events**](ErrorsApi.md#list_events) | **GET** /projects/{projectId}/errors/{fingerprint}/events | Get information about the events related to the error |
| [**update_error**](ErrorsApi.md#update_error) | **PUT** /projects/{projectId}/errors/{fingerprint} | Update the status of the error |


## get_error

> <Error> get_error(project_id, fingerprint)

Get information about the error

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

api_instance = ErrorTrackingOpenAPI::ErrorsApi.new
project_id = 56 # Integer | ID of the project where the error was created
fingerprint = 56 # Integer | ID of the error that needs to be updated deleted

begin
  # Get information about the error
  result = api_instance.get_error(project_id, fingerprint)
  p result
rescue ErrorTrackingOpenAPI::ApiError => e
  puts "Error when calling ErrorsApi->get_error: #{e}"
end
```

#### Using the get_error_with_http_info variant

This returns an Array which contains the response data, status code and headers.

> <Array(<Error>, Integer, Hash)> get_error_with_http_info(project_id, fingerprint)

```ruby
begin
  # Get information about the error
  data, status_code, headers = api_instance.get_error_with_http_info(project_id, fingerprint)
  p status_code # => 2xx
  p headers # => { ... }
  p data # => <Error>
rescue ErrorTrackingOpenAPI::ApiError => e
  puts "Error when calling ErrorsApi->get_error_with_http_info: #{e}"
end
```

### Parameters

| Name | Type | Description | Notes |
| ---- | ---- | ----------- | ----- |
| **project_id** | **Integer** | ID of the project where the error was created |  |
| **fingerprint** | **Integer** | ID of the error that needs to be updated deleted |  |

### Return type

[**Error**](Error.md)

### Authorization

[internalToken](../README.md#internalToken)

### HTTP request headers

- **Content-Type**: Not defined
- **Accept**: */*


## list_errors

> <Array<Error>> list_errors(project_id, opts)

List of errors

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

api_instance = ErrorTrackingOpenAPI::ErrorsApi.new
project_id = 56 # Integer | ID of the project where the error was created
opts = {
  sort: 'last_seen_desc', # String | 
  status: 'unresolved', # String | 
  query: 'query_example', # String | 
  cursor: 'cursor_example', # String | Base64 encoded information for pagination
  limit: 56, # Integer | Number of entries to return
  stats_period: '15m', # String | 
  query_period: '15m' # String | 
}

begin
  # List of errors
  result = api_instance.list_errors(project_id, opts)
  p result
rescue ErrorTrackingOpenAPI::ApiError => e
  puts "Error when calling ErrorsApi->list_errors: #{e}"
end
```

#### Using the list_errors_with_http_info variant

This returns an Array which contains the response data, status code and headers.

> <Array(<Array<Error>>, Integer, Hash)> list_errors_with_http_info(project_id, opts)

```ruby
begin
  # List of errors
  data, status_code, headers = api_instance.list_errors_with_http_info(project_id, opts)
  p status_code # => 2xx
  p headers # => { ... }
  p data # => <Array<Error>>
rescue ErrorTrackingOpenAPI::ApiError => e
  puts "Error when calling ErrorsApi->list_errors_with_http_info: #{e}"
end
```

### Parameters

| Name | Type | Description | Notes |
| ---- | ---- | ----------- | ----- |
| **project_id** | **Integer** | ID of the project where the error was created |  |
| **sort** | **String** |  | [optional][default to &#39;last_seen_desc&#39;] |
| **status** | **String** |  | [optional][default to &#39;unresolved&#39;] |
| **query** | **String** |  | [optional] |
| **cursor** | **String** | Base64 encoded information for pagination | [optional] |
| **limit** | **Integer** | Number of entries to return | [optional][default to 20] |
| **stats_period** | **String** |  | [optional][default to &#39;24h&#39;] |
| **query_period** | **String** |  | [optional][default to &#39;30d&#39;] |

### Return type

[**Array&lt;Error&gt;**](Error.md)

### Authorization

[internalToken](../README.md#internalToken)

### HTTP request headers

- **Content-Type**: Not defined
- **Accept**: */*


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

api_instance = ErrorTrackingOpenAPI::ErrorsApi.new
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
  puts "Error when calling ErrorsApi->list_events: #{e}"
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
  puts "Error when calling ErrorsApi->list_events_with_http_info: #{e}"
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


## update_error

> <Error> update_error(project_id, fingerprint, body)

Update the status of the error

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

api_instance = ErrorTrackingOpenAPI::ErrorsApi.new
project_id = 56 # Integer | ID of the project where the error was created
fingerprint = 56 # Integer | ID of the error that needs to be updated deleted
body = ErrorTrackingOpenAPI::ErrorUpdatePayload.new # ErrorUpdatePayload | Error update object with the new values

begin
  # Update the status of the error
  result = api_instance.update_error(project_id, fingerprint, body)
  p result
rescue ErrorTrackingOpenAPI::ApiError => e
  puts "Error when calling ErrorsApi->update_error: #{e}"
end
```

#### Using the update_error_with_http_info variant

This returns an Array which contains the response data, status code and headers.

> <Array(<Error>, Integer, Hash)> update_error_with_http_info(project_id, fingerprint, body)

```ruby
begin
  # Update the status of the error
  data, status_code, headers = api_instance.update_error_with_http_info(project_id, fingerprint, body)
  p status_code # => 2xx
  p headers # => { ... }
  p data # => <Error>
rescue ErrorTrackingOpenAPI::ApiError => e
  puts "Error when calling ErrorsApi->update_error_with_http_info: #{e}"
end
```

### Parameters

| Name | Type | Description | Notes |
| ---- | ---- | ----------- | ----- |
| **project_id** | **Integer** | ID of the project where the error was created |  |
| **fingerprint** | **Integer** | ID of the error that needs to be updated deleted |  |
| **body** | [**ErrorUpdatePayload**](ErrorUpdatePayload.md) | Error update object with the new values |  |

### Return type

[**Error**](Error.md)

### Authorization

[internalToken](../README.md#internalToken)

### HTTP request headers

- **Content-Type**: application/json
- **Accept**: application/json

