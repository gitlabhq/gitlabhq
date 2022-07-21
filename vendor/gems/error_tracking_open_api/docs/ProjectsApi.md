# ErrorTrackingOpenAPI::ProjectsApi

All URIs are relative to *https://localhost/errortracking/api/v1*

| Method | HTTP request | Description |
| ------ | ------------ | ----------- |
| [**delete_project**](ProjectsApi.md#delete_project) | **DELETE** /projects/{id} | Deletes all project related data. Mostly for testing purposes and later for production to clean updeleted projects. |


## delete_project

> delete_project(id)

Deletes all project related data. Mostly for testing purposes and later for production to clean updeleted projects.

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

api_instance = ErrorTrackingOpenAPI::ProjectsApi.new
id = 56 # Integer | ID of the project

begin
  # Deletes all project related data. Mostly for testing purposes and later for production to clean updeleted projects.
  api_instance.delete_project(id)
rescue ErrorTrackingOpenAPI::ApiError => e
  puts "Error when calling ProjectsApi->delete_project: #{e}"
end
```

#### Using the delete_project_with_http_info variant

This returns an Array which contains the response data (`nil` in this case), status code and headers.

> <Array(nil, Integer, Hash)> delete_project_with_http_info(id)

```ruby
begin
  # Deletes all project related data. Mostly for testing purposes and later for production to clean updeleted projects.
  data, status_code, headers = api_instance.delete_project_with_http_info(id)
  p status_code # => 2xx
  p headers # => { ... }
  p data # => nil
rescue ErrorTrackingOpenAPI::ApiError => e
  puts "Error when calling ProjectsApi->delete_project_with_http_info: #{e}"
end
```

### Parameters

| Name | Type | Description | Notes |
| ---- | ---- | ----------- | ----- |
| **id** | **Integer** | ID of the project |  |

### Return type

nil (empty response body)

### Authorization

[internalToken](../README.md#internalToken)

### HTTP request headers

- **Content-Type**: Not defined
- **Accept**: Not defined

