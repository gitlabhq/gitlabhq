---
layout: guide
doc_stub: false
search: true
enterprise: true
section: GraphQL Enterprise - Rate Limiters
title: Runtime Limiter
desc: Limit the total runtime of a client's GraphQL Operations
index: 3
---

`GraphQL::Enterprise::RuntimeLimiter` applies an upper bound to processing time consumed by a single client. It uses {% internal_link "Redis", "limiters/redis" %} track time with a [token bucket](https://en.wikipedia.org/wiki/Token_bucket) algorithm.

## Why?

This limiter prevents a single client from consuming too much processing time, regardless of whether it comes a burst of short-lived queries (which the {% internal_link "Active Operation Limiter", "/limiters/active_operations" %} can prevent) or a small number of long-running queries. Unlike request counters or complexity calculations, the runtime limiter pays no attention to the structure of the incoming request. Instead, it simply measures the time spent on the request _as a whole_ and halts queries when a client consumes more than the limit.

## Setup

To use this limiter, update the schema configuration and include `context[:limiter_key]` in your queries.

### Schema Setup

To setup the schema, add `use GraphQL::Enterprise::RuntimeLimiter` with a default `limit_ms:` value:

```ruby
class MySchema < GraphQL::Schema
  # ...
  use GraphQL::Enterprise::RuntimeLimiter,
    redis: Redis.new(...),
    limit_ms: 90 * 1000 # 90 seconds per minute
end
```

`limit_ms: false` may also be given, which defaults to _no limit_ for this limiter.

It also accepts a `window_ms:` option, which is the duration over which `limit_ms:` is added to a client's bucket. It defaults to `60_000` (one minute).

Before requests will actually be halted, {% internal_link "soft mode", "/limiters/deployment#soft-limits" %} must be disabled.

### Query Setup

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

`GraphQL::Enterprise::RuntimeLimiter` provides several hooks for customizing its behavior. To use these, make a subclass of the limiter and override methods as described:

```ruby
# app/graphql/limiters/runtime.rb
class Limiters::Runtime < GraphQL::Enterprise::RuntimeLimiter
  # override methods here
end
```

The hooks are:

- `def limiter_key(query)` should return a string which identifies the current client for `query`.
- `def limit_for(key, query)` should return an integer or `nil`. If an integer is returned, that limit is applied for the current query. If `nil` is returned, no limit is applied to the current query.
- `def soft_limit?(key, query)` can be implemented to customize the application of "soft mode". By default, it checks a setting in redis.
- `def handle_redis_error(err)` is called when the limit rescues an error from Redis. By default, it's passed to `warn` and the query is _not_ halted.

## Instrumentation

While the limiter is installed, it adds some information to the query context about its operation. It can be accessed at `context[:runtime_limiter]`:


```ruby
result = MySchema.execute(...)

pp result.context[:runtime_limiter]
# {:key=>"custom-key-9",
#  :limit_ms=>800,
#  :remaining_ms=>0,
#  :soft=>true,
#  :limited=>true,
#  :window_ms=>60_000}
```

It returns a Hash containing:

- `key: [String]`, the limiter key used for this query
- `limit_ms: [Integer, nil]`, the limit applied to this query
- `remaining_ms: [Integer, nil]`, the amount of time remaining in this client's bucket
- `soft: [Boolean]`, `true` if the query was run in "soft mode"
- `limited: [Boolean]`, `true` if the query exceeded the rate limit (but if `soft:` was also `true`, then the query was _not_ halted)
- `window_ms: [Integer]` the configured `window_ms:` for the limiter

You could use this to add detailed metrics to your application monitoring system, for example:

```ruby
MyMetrics.increment("graphql.runtime_limiter", tags: result.context[:runtime_limiter])
```

## Some Caveats

The limiter will not _interrupt_ a long-running field. Instead, it stops executing new fields after a client exceeds its allowed processing time. This is because interrupting arbitrary code may have unintended consequences for I/O operations, see ["Timeout: Ruby's most dangerous API"](https://www.mikeperham.com/2015/05/08/timeout-rubys-most-dangerous-api/).

Also, the limiter only checks remaining time at the _start_ of a query and it only decreases the remaining time at the _end_ of a query. This means that simulaneous queries may consume the remainder at the same time. Use the {% internal_link "Active Operation Limiter", "/limiters/active_operations" %} to limit behavior in this regard. This implementation is basically a trade-off: more granular updates would require more communication with Redis which would add overhead to each request.
