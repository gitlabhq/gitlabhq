---
layout: guide
doc_stub: false
search: true
section: Subscriptions
title: Broadcasts
desc: Delivering the same GraphQL result to multiple subscribers
index: 3
---

GraphQL subscription updates may _broadcast_ data to multiple subscribers.

A broadcast is a subscription update which is executed _once_, then delivered to _any number_ of subscribers. This reduces the time your server spends running GraphQL queries, since it doesn't have to re-run the query for every subscriber.

But, __take care__: this approach risks leaking information to subscribers who shouldn't receive it.

## Setup

To enable broadcasts, add `broadcast: true` to your subscription setup:

```ruby
class MyAppSchema < GraphQL::Schema
  # ...
  use SomeSubscriptionImplementation,
    broadcast: true # <----
end
```

Then, any broadcastable field can be configured with `broadcastable: true`:

```ruby
field :name, String, null: false,
  broadcastable: true
```

When a subscription comes in where _all_ of its fields are `broadcastable: true`, then it will be handled as a broadcast.

Additionally, you can set `default_broadcastable: true`:

```ruby
class MyAppSchema < GraphQL::Schema
  # ...
  use SomeSubscriptionImplementation,
    broadcast: true,
    default_broadcastable: true # <----
end
```

With this setting, fields are broadcastable by default. Only a field with `broadcastable: false` in its configuration will cause a subscription to be handled on a subscriber-by-subscriber basis.

## What fields are broadcastable?

GraphQL-Ruby can't infer whether a field is broadcastable or not. You must configure it explicitly with `broadcastable: true` or `broadcastable: false`. (The subscription plugin also accepts `default_broadcastable: true|false`.)

A field is broadcastable if _all clients who request the field will see the same value_. For example:

- General facts: celebrity names, laws of physics, historical dates
- Public information: object names, document updated-at timestamps, boilerplate info

For fields like this, you can add `broadcastable: true`.

A field is __not broadcastable__ if its value is different for different clients. For example:

- __Viewer-specific information:__ if a field is specifically viewer-based, then it can't be broadcasted to other viewers. For example, `discussion { viewerCanModerate }` might be true for a moderator, but it shouldn't be broadcasted to other viewers.
- __Context-specific information:__ if a field's value takes the request context into consideration, it shouldn't be broadcasted. For example, IP addresses or HTTP header values probably can't be broadcasted. If a field reflects the viewer's timezone, it can't be broadcasted.
- __Restricted information:__ if some viewers see one value, while other viewers see a different value, then it's not broadcastable. Broadcasting this data might leak private information to unauthorized clients. (This includes filtered lists: if the filtering is viewer-by-viewer, it's not broadcastable.)
- __Fields with side effects:__ if the system requires a side effect (eg, logging a metric, updating a database, incrementing a counter) whenever a resolver is executed, it's not a good candidate for broadcasting because some executions will be optimized away.

These fields can be tagged with `broadcastable: false` so that GraphQL-Ruby will handle them on a subscriber-by-subscriber basis.

If you want to use subscriptions but have a lot of non-broadcastable fields in your schema, consider building a new set of subscription fields with limited access to other schema objects. Instead, optimize those subscriptions for broacastability.

## Under the Hood

GraphQL-Ruby determines which subscribers can receive a broadcast by inspecting:

- __Query string__. Only exactly-matching query strings will receive the same broadcast.
- __Variables__. Only exactly-matching variable values will receive the same broadcast.
- __Field and Arguments__ given to `.trigger`. They must match the ones initially sent when subscribing. (Subscriptions always worked this way.)
- __Subscription scope__. Only clients with exactly-matching subscription scope can receive the same broadcasts.

So, take care to {% internal_link "set subscription_scope", "subscriptions/subscription_classes#scope" %} whenever a subscription should be implicitly scoped!

(See {{ "GraphQL::Subscriptions::Event#fingerprint" | api_doc }} for the implementation of broadcast fingerprints.)

## Checking for Broadcastable

For testing purposes, you can confirm that a GraphQL query string is broadcastable by using {{ "Subscriptions#broadcastable?" | api_doc }}:

```ruby
subscription_string = "subscription { ... }"
MySchema.subscriptions.broadcastable?(subscription_string)
# => true or false
```

Use this in your application's tests to make sure that broadcastable fields aren't accidentally made non-broadcastable.

## Connections and Edges

You can configure your generated `Connection` and `Edge` types to be broadcastable by setting `default_broadcastable(true)` in their definition:

```ruby
# app/types/base_connection.rb
class Types::BaseConnection < Types::BaseObject
  include GraphQL::Types::Relay::ConnectionBehaviors
  default_broadcastable(true)
end

# app/types/base_edge.rb
class Types::BaseEdge < Types::BaseObject
  include GraphQL::Types::Relay::EdgeBehaviors
  default_broadcastable(true)
end
```

(In your `BaseObject`, you should also have `connection_type_class(Types::BaseConnection)` and `edge_type_class(Types::BaseEdge)`.)

`PageInfo` is broadcastable by default.
