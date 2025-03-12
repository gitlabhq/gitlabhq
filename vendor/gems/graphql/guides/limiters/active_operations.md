---
layout: guide
doc_stub: false
search: true
enterprise: true
section: GraphQL Enterprise - Rate Limiters
title: Active Operation Limiter
desc: Limit the number of concurrent GraphQL operations
index: 2
---

`GraphQL::Enterprise::ActiveOperationLimiter` prevents clients from running too many GraphQL operations at the same time. It uses {% internal_link "Redis", "limiters/redis" %} to track currently-running operations.

## Why?

Some clients may suddently swamp a server with tons of requests, occupying all available Ruby processes and therefore interrupting service for other clients. This limiter aims to prevent that at the GraphQL level by halting queries when a client already has lots of queries running. That way, server processes will remain available for other clients' requests.

## Setup

To use this limiter, update the schema configuration and include `context[:limiter_key]` in your queries.

#### Schema Setup

To setup the schema, add `use GraphQL::Enterprise::ActiveOperationLimiter` with a default `limit:` value:

```ruby
class MySchema < GraphQL::Schema
  # ...
  use GraphQL::Enterprise::ActiveOperationLimiter,
    redis: Redis.new(...),
    limit: 5
end
```

`limit: false` may also be given, which defaults to _no limit_ for this limiter.

It also accepts a `stale_request_seconds:` option. The limiter uses that value to clean up request data in case of a crash or other unexpected scenario.

Before requests will actually be halted, {% internal_link "soft mode", "/limiters/deployment#soft-limits" %} must be disabled.

#### Query Setup

In order to limit clients, the limiter needs a client identifier for each GraphQL operation. By default, it checks `context[:limiter_key]` to find it:

```ruby
context = {
  viewer: current_user,
  # for example:
  limiter_key: logged_in? ? "user:#{current_user.id}" : "anon-ip:#{request.remote_ip}",
  # ...
}

result = MySchema.execute(query_str, context: context)
```

Operations with the same `context[:limiter_key]` will rate limited in the same buckets. A limiter key is required; if a query is run without one, the limiter will raise an error.

To provide a client identifier another way, see [Customization](#customization).

## Customization

`GraphQL::Enterprise::ActiveOperationLimiter` provides several hooks for customizing its behavior. To use these, make a subclass of the limiter and override methods as described:

```ruby
# app/graphql/limiters/active_operations.rb
class Limiters::ActiveOperations < GraphQL::Enterprise::ActiveOperationsLimiter
  # override methods here
end
```

The hooks are:

- `def limiter_key(query)` should return a string which identifies the current client for `query`.
- `def limit_for(key, query)` should return an integer or `nil`. If an integer is returned, that limit is applied for the current query. If `nil` is returned, no limit is applied to the current query.
- `def soft_limit?(key, query)` can be implemented to customize the application of "soft mode". By default, it checks a setting in redis.
- `def handle_redis_error(err)` is called when the limit rescues an error from Redis. By default, it's passed to `warn` and the query is _not_ halted.

## Instrumentation

While the limiter is installed, it adds some information to the query context about its operation. It can be accessed at `context[:active_operation_limiter]`:

```ruby
result = MySchema.execute(...)

pp result.context[:active_operation_limiter]
# {:key=>"user:123", :limit=>2, :soft=>false, :limited=>true}
```

It returns a Hash containing:

- `key: [String]`, the limiter key used for this query
- `limit: [Integer, nil]`, the limit applied to this query
- `soft: [Boolean]`, `true` if the query was run in "soft mode"
- `limited: [Boolean]`, `true` if the query exceeded the rate limit (but if `soft:` was also `true`, then the query was _not_ halted)

You could use this to add detailed metrics to your application monitoring system, for example:

```ruby
MyMetrics.increment("graphql.active_operation_limiter", tags: result.context[:active_operation_limiter])
```
