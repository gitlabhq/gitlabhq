---
layout: guide
doc_stub: false
search: true
section: Type Definitions
title: Non-Null Types
desc: Values which must be present
index: 7
---

GraphQL's concept of _non-null_ is expressed in the [Schema Definition Language](https://graphql.org/learn/schema/#type-language) (SDL) with `!`, for example:

```graphql
type User {
  # This field _always_ returns a String, never returns `null`
  handle: String!
  # `since:` _must_ be passed a `DateTime` value, it can never be omitted or passed `null`
  followers(since: DateTime!): [User!]!
}
```

In Ruby, this concept is expressed with `null:` for fields and `required:` for arguments.

## Non-null return types

When `!` is used for field return types (like `handle: String!` above), it means that the field will _never_ (and may never) return `nil`.

To make a field non-null in Ruby, use `null: false` in the field definition:

```ruby
# equivalent to `handle: String!` above
field :handle, String, null: false
```

This means that the field will _never_ be `nil` (and if it is, it will be removed from the response, as described below).

### Non-null error propagation

 If a non-null field ever returns `nil`, then the entire selection will be removed from the response and replaced with `nil`. If this removal would result in _another_ invalid `nil`, then it cascades upward, until it reaches the root `"data"` key. This is to support clients in strongly-typed languages. Any non-null field will _never_ return `null`, and client developers can depend on that.

## Non-null argument types

When `!` is used for arguments (like `followers(since: DateTime!)` above), it means that the argument is _required_ for the query to execute. Any query which doesn't have a value for that argument will be rejected immediately.

Arguments are non-null by default. You can use `required: false` to mark arguments as optional:

```ruby
# This will be `since: DateTime` instead of `since: DateTime!`
argument :since, Types::DateTime, required: false
```

Without `required: false`, any query _without_ a value for `since:` will be rejected.
