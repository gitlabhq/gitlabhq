---
layout: guide
search: true
section: Dataloader
title: Overview
desc: Getting started with the Fiber-based Dataloader
index: 0
---

 {{ "GraphQL::Dataloader" | api_doc }} provides efficient, batched access to external services, backed by Ruby's `Fiber` concurrency primitive. It has a per-query result cache and {% internal_link "AsyncDataloader", "/dataloader/async_dataloader" %} supports truly parallel execution out-of-the-box.

`GraphQL::Dataloader` is inspired by [`@bessey`'s proof-of-concept](https://github.com/bessey/graphql-fiber-test/tree/no-gem-changes) and [shopify/graphql-batch](https://github.com/shopify/graphql-batch).

## Batch Loading

`GraphQL::Dataloader` facilitates a two-stage approach to fetching data from external sources (like databases or APIs):

- First, GraphQL fields register their data requirements (eg, object IDs or query parameters)
- Then, after as many requirements have been gathered as possible, `GraphQL::Dataloader` initiates _actual_ fetches to external services

That cycle is repeated during execution: data requirements are gathered until no further GraphQL fields can be executed, then `GraphQL::Dataloader` triggers external calls based on those requirements and GraphQL execution resumes.

## Fibers

`GraphQL::Dataloader` uses Ruby's `Fiber`, a lightweight concurrency primitive which supports application-level scheduling _within_ a `Thread`. By using `Fiber`, `GraphQL::Dataloader` can pause GraphQL execution when data is requested, then resume execution after the data is fetched.

At a high level, `GraphQL::Dataloader`'s usage of `Fiber` looks like this:

- GraphQL execution is run inside a Fiber.
- When that Fiber returns, if the Fiber was paused to wait for data, then GraphQL execution resumes with the _next_ (sibling) GraphQL field inside a new Fiber.
- That cycle continues until no further sibling fields are available and all known Fibers are paused.
- `GraphQL::Dataloader` takes the first paused Fiber and resumes it, causing the `GraphQL::Dataloader::Source` to execute its `#fetch(...)` call. That Fiber continues execution as far as it can.
- Likewise, paused Fibers are resumed, causing GraphQL execution to continue, until all paused Fibers are evaluated completely.

Whenever `GraphQL::Dataloader` creates a new `Fiber`, it copies each pair from `Thread.current[...]` and reassigns them inside the new `Fiber`.

`AsyncDataloader`, built on top of the [`async` gem](https://github.com/socketry/async), supports parallel I/O operations (like network and database communication) via Ruby's non-blocking `Fiber.schedule` API. {% internal_link "Learn more →", "/dataloader/async_dataloader" %}.

## Getting Started

To install {{ "GraphQL::Dataloader" | api_doc }}, add it to your schema with `use ...`, for example:

```ruby
class MySchema < GraphQL::Schema
  # ...
  use GraphQL::Dataloader
end
```

Then, inside your schema, you can request batch-loaded objects by their lookup key with `dataloader.with(...).load(...)`:

```ruby
field :user, Types::User do
  argument :handle, String
end

def user(handle:)
  dataloader.with(Sources::UserByHandle).load(handle)
end
```

Or, load several objects by passing an array of lookup keys to `.load_all(...)`:

```ruby
field :is_following, Boolean, null: false do
  argument :follower_handle, String
  argument :followed_handle, String
end

def is_following(follower_handle:, followed_handle:)
  follower, followed = dataloader
    .with(Sources::UserByHandle)
    .load_all([follower_handle, followed_handle])

  followed && follower && follower.follows?(followed)
end
```

To prepare requests from several sources, use `.request(...)`, then call `.load` after all requests are registered:

```ruby
class AddToList < GraphQL::Schema::Mutation
  argument :handle, String
  argument :list, String, as: :list_name

  field :list, Types::UserList

  def resolve(handle:, list_name:)
    # first, register the requests:
    user_request = dataloader.with(Sources::UserByHandle).request(handle)
    list_request = dataloader.with(Sources::ListByName, context[:viewer]).request(list_name)
    # then, use `.load` to wait for the external call and return the object:
    user = user_request.load
    list = list_request.load
    # Now, all objects are ready.
    list.add_user!(user)
    { list: list }
  end
end
```

### `loads:` and `object_from_id`

`dataloader` is also available as `context.dataloader`, so you can use it to implement `MySchema.object_from_id`. For example:

```ruby
class MySchema < GraphQL::Schema
  def self.object_from_id(id, ctx)
    model_class, database_id = IdDecoder.decode(id)
    ctx.dataloader.with(Sources::RecordById, model_class).load(database_id)
  end
end
```

Then, any arguments with `loads:` will use that method to fetch objects. For example:

```ruby
class FollowUser < GraphQL::Schema::Mutation
  argument :follow_id, ID, loads: Types::User

  field :followed, Types::User

  def resolve(follow:)
    # `follow` was fetched using the Schema's `object_from_id` hook
    context[:viewer].follow!(follow)
    { followed: follow }
  end
end
```

## Data Sources

To implement batch-loading data sources, see the {% internal_link "Sources guide", "/dataloader/sources" %}.

## Parallelism

You can run I/O operations in parallel with GraphQL::Dataloader. There are two approaches:

- `AsyncDataloader` uses the `async` gem to automatically background I/O from `Dataloader::Source#fetch` calls. {% internal_link "Read More", "/dataloader/async_dataloader" %}
- You can manually call `dataloader.yield` after starting work in the background. {% internal_link "Read More", "/dataloader/parallelism" %}
