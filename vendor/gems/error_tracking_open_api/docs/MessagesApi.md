# ErrorTrackingOpenAPI::MessagesApi

All URIs are relative to *https://localhost/errortracking/api/v1*

| Method | HTTP request | Description |
| ------ | ------------ | ----------- |
| [**list_messages**](MessagesApi.md#list_messages) | **GET** /projects/{projectId}/messages | List of messages |


## list_messages

> <Array<MessageEvent>> list_messages(project_id, opts)

List of messages

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

api_instance = ErrorTrackingOpenAPI::MessagesApi.new
project_id = 56 # Integer | ID of the project where the message was created
opts = {
  limit: 56 # Integer | Number of entries to return
}

begin
  # List of messages
  result = api_instance.list_messages(project_id, opts)
  p result
rescue ErrorTrackingOpenAPI::ApiError => e
  puts "Error when calling MessagesApi->list_messages: #{e}"
end
```

#### Using the list_messages_with_http_info variant

This returns an Array which contains the response data, status code and headers.

> <Array(<Array<MessageEvent>>, Integer, Hash)> list_messages_with_http_info(project_id, opts)

```ruby
begin
  # List of messages
  data, status_code, headers = api_instance.list_messages_with_http_info(project_id, opts)
  p status_code # => 2xx
  p headers # => { ... }
  p data # => <Array<MessageEvent>>
rescue ErrorTrackingOpenAPI::ApiError => e
  puts "Error when calling MessagesApi->list_messages_with_http_info: #{e}"
end
```

### Parameters

| Name | Type | Description | Notes |
| ---- | ---- | ----------- | ----- |
| **project_id** | **Integer** | ID of the project where the message was created |  |
| **limit** | **Integer** | Number of entries to return | [optional][default to 20] |

### Return type

[**Array&lt;MessageEvent&gt;**](MessageEvent.md)

### Authorization

[internalToken](../README.md#internalToken)

### HTTP request headers

- **Content-Type**: Not defined
- **Accept**: */*

