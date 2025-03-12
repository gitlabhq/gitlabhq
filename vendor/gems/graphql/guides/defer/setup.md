---
layout: guide
doc_stub: false
search: true
section: GraphQL Pro - Defer
title: Server Setup
desc: Configuring the schema and server to use @defer
index: 1
pro: true
---

Before using `@defer` in queries, you have to:

- Update `graphql` and `graphql-pro` gems
- Add `@defer` to your GraphQL schema
- Update your HTTP handlers (eg, Rails controllers) to send streaming responses
- Optionally, customize `@defer` to work with GraphQL-Batch

You can also see a [full Rails & Apollo-Client demo](https://github.com/rmosolgo/graphql_defer_example).

## Updating the gems

GraphQL-Ruby 1.9+ and GraphQL-Pro 1.10+ are required:

```ruby
gem "graphql", "~>1.9"
gem "graphql-pro", "~>1.10"
```

And then install them:

```
$ bundle update graphql graphql-pro
```

## Adding `@defer` to your schema

Then, add `GraphQL::Pro::Defer` to your schema as a plugin:

```ruby
class MySchema < GraphQL::Schema
  use GraphQL::Pro::Defer
end
```

This will:

- Attach a {% internal_link "custom directive", "/type_definitions/directives" %} called `@defer`
- Add instrumentation to queries to track deferred work and execute it later

## Sending streaming responses

Many web frameworks have support for streaming responses, for example:

- Rails has [ActionController::Live](https://api.rubyonrails.org/classes/ActionController/Live.html)
- Sinatra has [Sinatra::Streaming](http://sinatrarb.com/contrib/streaming.html)
- Hanami::Controller can [stream responses](https://github.com/hanami/controller#streamed-responses)

See below for how to integrate GraphQL's deferred patches with a streaming response API.

To investigate support with a web framework, please {% open_an_issue "Server support for @defer with ..." %} or email `support@graphql.pro`.

### Checking for deferrals

When a query has any `@defer`ed fields, you can check for `context[:defer]`:

```ruby
if context[:defer]
  # some fields were `@defer`ed
else
  # normal GraphQL, no `@defer`
end
```

### Working with deferrals

To handle deferrals, you can enumerate over `context[:defer]`, for example:

```ruby
context[:defer].each do |deferral|
  # do something with the `deferral`, eg
  # stream_to_client(deferral.to_h)
end
```

The initial result is _also_ present in the deferrals, so you can treat it just like a patch.

Each deferred patch has a few methods for building a response:

- `.to_h` returns a hash with `path:`, `data:`, and/or `errors:`. (There is no `path:` for the root result.)
- `.to_http_multipart(incremental: true)` returns a string which works with Apollo client's `@defer` support. (Use `incremental: true` to format patches for the forthcoming spec.)
- `.path` returns the path to this patch in the response
- `.data` returns successfully-resolved results of the patch
- `.errors` returns an array of errors, if there were any

Calling `.data` or `.errors` on a deferral will resume GraphQL execution until the patch is complete.

### Example: Rails with Apollo Client

In this example, a Rails controller will stream HTTP Multipart patches to the client, in Apollo Client's supported format.

```ruby
class GraphqlController < ApplicationController
  # Support `response.stream` below:
  include ActionController::Live

  def execute
    # ...
    result = MySchema.execute(query, variables: variables, context: context, operation_name: operation_name)

    # Check if this is a deferred query:
    if (deferred = result.context[:defer])
      # Required for Rack 2.2+, see https://github.com/rack/rack/issues/1619
      response.headers['Last-Modified'] = Time.now.httpdate
      # Use built-in `stream_http_multipart` with Apollo-Client & ActionController::Live
      deferred.stream_http_multipart(response, incremental: true)
    else
      # Return a plain, non-deferred result
      render json: result
    end
  ensure
    # Always make sure to close the stream
    response.stream.close
  end
end
```

You can also investigate a [full Rails & Apollo-Client demo](https://github.com/rmosolgo/graphql_defer_example)

## With GraphQL-Batch

`GraphQL-Batch` is a third-party data loading library that wraps GraphQL-Ruby execution. Deferred resolution happens outside the normal execution flow, so to work with GraphQL-Batch, you have to customize `GraphQL::Pro::Defer` a bit. Also, you'll need GraphQL-Pro `v1.24.6` or later. Here's a custom `Defer` implementation:

```ruby
# app/graphql/directives/defer.rb
module Directives
  # Modify the library's `@defer` implementation to work with GraphQL-Batch
  class Defer < GraphQL::Pro::Defer
    def self.resolve(obj, arguments, context, &block)
      # While the query is running, store the batch executor to re-use later
      context[:graphql_batch_executor] ||= GraphQL::Batch::Executor.current
      super
    end

    class Deferral < GraphQL::Pro::Defer::Deferral
      def resolve
        # Before calling the deferred execution,
        # set GraphQL-Batch back up:
        prev_executor = GraphQL::Batch::Executor.current
        GraphQL::Batch::Executor.current ||= @context[:graphql_batch_executor]
        super
      ensure
        # Clean up afterward:
        GraphQL::Batch::Executor.current = prev_executor
      end
    end
  end
end
```

And update your schema to use your custom defer implementation:

```ruby
# Use our GraphQL-Batch-compatible defer:
use Directives::Defer
```
## Next Steps

Read about {% internal_link "client usage", "/defer/usage" %} of `@defer`.
