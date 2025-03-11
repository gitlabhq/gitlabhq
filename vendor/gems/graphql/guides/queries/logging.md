---
layout: guide
doc_stub: false
search: true
section: Queries
title: Logging
desc: Development output from GraphQL-Ruby
index: 12
---

At runtime, GraphQL-Ruby will output debug information using {{ "GraphQL::Query.logger" | api_doc }}. By default, this uses `Rails.logger`. To see output, make sure `config.log_level = :debug` is set. (This information isn't meant for production logs.)

You can configure a custom logger with {{ "GraphQL::Schema.default_logger" | api_doc }}, for example:

```ruby
class MySchema < GraphQL::Schema
  # This logger will be used by queries during execution:
  default_logger MyCustomLogger.new
end
```

You can also pass `context[:logger]` to provide a logger during execution.
