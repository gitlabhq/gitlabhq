---
layout: guide
search: true
section: Dataloader
title: Async Source Execution
desc: Using AsyncDataloader to fetch external data in parallel
index: 5
---

`AsyncDataloader` will run {{ "GraphQL::Dataloader::Source#fetch" | api_doc }} calls in parallel, so that external service calls (like database queries or network calls) don't have to wait in a queue.

To use `AsyncDataloader`, hook it up in your schema _instead of_ `GraphQL::Dataloader`:

```diff
- use GraphQL::Dataloader
+ use GraphQL::Dataloader::AsyncDataloader
```

__Also__, add [the `async` gem](https://github.com/socketry/async) to your project, for example:

```
bundle add async
```

Now, {{ "GraphQL::Dataloader::AsyncDataloader" | api_doc }} will create `Async::Task` instances instead of plain `Fiber`s and the `async` gem will manage parallelism.

For a demonstration of this behavior, see: [https://github.com/rmosolgo/rails-graphql-async-demo](https://github.com/rmosolgo/rails-graphql-async-demo)

_You can also implement {% internal_link "manual parallelism", "/dataloader/parallelism" %} using `dataloader.yield`._

## Rails

For Rails, you'll need **Rails 7.1**, which properly supports fiber-based concurrency, and you'll also want to configure Rails to use Fibers for isolation:

```ruby
class Application < Rails::Application
  # ...
  config.active_support.isolation_level = :fiber
end
```
### ActiveRecord Connections

You can use Dataloader's {% internal_link "Fiber lifecycle hooks", "/dataloader/dataloader#fiber-lifecycle-hooks" %} to improve ActiveRecord connection handling:

- In Rails < 7.2, connections are not reused when a Fiber exits; instead, they're only reused when a request or background job finishes. You can add manual `release_connection` calls to improve this.
- With `isolation_level = :fiber`, new Fibers don't inherit `connected_to ...` settings from their parent fibers.

Altogether, it can be improved like this:

```ruby
def get_fiber_variables
  vars = super
  # Collect the current connection config to pass on:
  vars[:connected_to] = {
    role: ActiveRecord::Base.current_role,
    shard: ActiveRecord::Base.current_shard,
    prevent_writes: ActiveRecord::Base.current_preventing_writes
  }
  vars
end

def set_fiber_variables(vars)
  connection_config = vars.delete(:connected_to)
  # Reset connection config from the parent fiber:
  ActiveRecord::Base.connecting_to(**connection_config)
  super(vars)
end

def cleanup_fiber
  super
  # Release the current connection
  ActiveRecord::Base.connection_pool.release_connection
end
```

Modify the example according to your database configuration and abstract class hierarchy.

## Other Options

You can also manually implement parallelism with Dataloader. See the {% internal_link "Dataloader Parallelism", "/dataloader/parallelism" %} guide for details.
