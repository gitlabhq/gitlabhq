# ErrorTrackingOpenAPI::ErrorsV2Api

All URIs are relative to *https://localhost/errortracking/api/v1*

| Method | HTTP request | Description |
| ------ | ------------ | ----------- |
| [**get_stats_v2**](ErrorsV2Api.md#get_stats_v2) | **GET** /api/0/organizations/{groupId}/stats_v2 | Stats of events received for the group |
| [**list_errors_v2**](ErrorsV2Api.md#list_errors_v2) | **GET** /api/0/organizations/{groupId}/issues/ | List of errors(V2) |
| [**list_projects**](ErrorsV2Api.md#list_projects) | **GET** /api/0/organizations/{groupId}/projects/ | List of projects |


## get_stats_v2

> <Array<StatsObject>> get_stats_v2(group_id)

Stats of events received for the group

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

api_instance = ErrorTrackingOpenAPI::ErrorsV2Api.new
group_id = 56 # Integer | ID of the group

begin
  # Stats of events received for the group
  result = api_instance.get_stats_v2(group_id)
  p result
rescue ErrorTrackingOpenAPI::ApiError => e
  puts "Error when calling ErrorsV2Api->get_stats_v2: #{e}"
end
```

#### Using the get_stats_v2_with_http_info variant

This returns an Array which contains the response data, status code and headers.

> <Array(<Array<StatsObject>>, Integer, Hash)> get_stats_v2_with_http_info(group_id)

```ruby
begin
  # Stats of events received for the group
  data, status_code, headers = api_instance.get_stats_v2_with_http_info(group_id)
  p status_code # => 2xx
  p headers # => { ... }
  p data # => <Array<StatsObject>>
rescue ErrorTrackingOpenAPI::ApiError => e
  puts "Error when calling ErrorsV2Api->get_stats_v2_with_http_info: #{e}"
end
```

### Parameters

| Name | Type | Description | Notes |
| ---- | ---- | ----------- | ----- |
| **group_id** | **Integer** | ID of the group |  |

### Return type

[**Array&lt;StatsObject&gt;**](StatsObject.md)

### Authorization

[internalToken](../README.md#internalToken)

### HTTP request headers

- **Content-Type**: Not defined
- **Accept**: */*


## list_errors_v2

> <Array<ErrorV2>> list_errors_v2(project, group_id, opts)

List of errors(V2)

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

api_instance = ErrorTrackingOpenAPI::ErrorsV2Api.new
project = [37] # Array<Integer> | ID of the project where the error was created
group_id = 56 # Integer | ID of the group
opts = {
  status: 'unresolved', # String | 
  query: 'query_example', # String | 
  start: 'start_example', # String | Optional start of the stat period in format 2006-01-02T15:04:05
  _end: '_end_example', # String | Optional end of the stat period in format 2006-01-02T15:04:05
  environment: 'environment_example', # String | 
  limit: 56, # Integer | Number of entries to return
  sort: 'date' # String | Optional sorting column of the entries
}

begin
  # List of errors(V2)
  result = api_instance.list_errors_v2(project, group_id, opts)
  p result
rescue ErrorTrackingOpenAPI::ApiError => e
  puts "Error when calling ErrorsV2Api->list_errors_v2: #{e}"
end
```

#### Using the list_errors_v2_with_http_info variant

This returns an Array which contains the response data, status code and headers.

> <Array(<Array<ErrorV2>>, Integer, Hash)> list_errors_v2_with_http_info(project, group_id, opts)

```ruby
begin
  # List of errors(V2)
  data, status_code, headers = api_instance.list_errors_v2_with_http_info(project, group_id, opts)
  p status_code # => 2xx
  p headers # => { ... }
  p data # => <Array<ErrorV2>>
rescue ErrorTrackingOpenAPI::ApiError => e
  puts "Error when calling ErrorsV2Api->list_errors_v2_with_http_info: #{e}"
end
```

### Parameters

| Name | Type | Description | Notes |
| ---- | ---- | ----------- | ----- |
| **project** | [**Array&lt;Integer&gt;**](Integer.md) | ID of the project where the error was created |  |
| **group_id** | **Integer** | ID of the group |  |
| **status** | **String** |  | [optional][default to &#39;unresolved&#39;] |
| **query** | **String** |  | [optional] |
| **start** | **String** | Optional start of the stat period in format 2006-01-02T15:04:05 | [optional] |
| **_end** | **String** | Optional end of the stat period in format 2006-01-02T15:04:05 | [optional] |
| **environment** | **String** |  | [optional] |
| **limit** | **Integer** | Number of entries to return | [optional][default to 20] |
| **sort** | **String** | Optional sorting column of the entries | [optional][default to &#39;date&#39;] |

### Return type

[**Array&lt;ErrorV2&gt;**](ErrorV2.md)

### Authorization

[internalToken](../README.md#internalToken)

### HTTP request headers

- **Content-Type**: Not defined
- **Accept**: */*


## list_projects

> <Array<Project>> list_projects(group_id)

List of projects

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

api_instance = ErrorTrackingOpenAPI::ErrorsV2Api.new
group_id = 56 # Integer | ID of the group

begin
  # List of projects
  result = api_instance.list_projects(group_id)
  p result
rescue ErrorTrackingOpenAPI::ApiError => e
  puts "Error when calling ErrorsV2Api->list_projects: #{e}"
end
```

#### Using the list_projects_with_http_info variant

This returns an Array which contains the response data, status code and headers.

> <Array(<Array<Project>>, Integer, Hash)> list_projects_with_http_info(group_id)

```ruby
begin
  # List of projects
  data, status_code, headers = api_instance.list_projects_with_http_info(group_id)
  p status_code # => 2xx
  p headers # => { ... }
  p data # => <Array<Project>>
rescue ErrorTrackingOpenAPI::ApiError => e
  puts "Error when calling ErrorsV2Api->list_projects_with_http_info: #{e}"
end
```

### Parameters

| Name | Type | Description | Notes |
| ---- | ---- | ----------- | ----- |
| **group_id** | **Integer** | ID of the group |  |

### Return type

[**Array&lt;Project&gt;**](Project.md)

### Authorization

[internalToken](../README.md#internalToken)

### HTTP request headers

- **Content-Type**: Not defined
- **Accept**: */*

