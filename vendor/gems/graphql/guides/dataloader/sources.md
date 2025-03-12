---
layout: guide
search: true
section: Dataloader
title: Sources
desc: Batch-loading objects for GraphQL::Dataloader
index: 1
---

_Sources_ are what {{ "GraphQL::Dataloader" | api_doc }} uses to fetch data from external services.

## Source Concepts

Sources are classes that inherit from `GraphQL::Dataloader::Source`. A Source _must_ implement `def fetch(keys)` to return a list of objects, one for each of the given keys. A source _may_ implement `def initialize(...)` to accept other batching parameters.

Sources will receive two kinds of inputs from `GraphQL::Dataloader`:

- _keys_, which correspond to objects requested by the application.

  Keys are passed to `def fetch(keys)`, which must return an object (or `nil`) for each of `keys`, in the same order as `keys`.

  Under the hood, each Source instance maintains a `key => object` cache.

- _batch parameters_, which are the basis of batched groups. For example, if you're loading records from different database tables, the table name would be a batch parameter.

  Batch parameters are given to `dataloader.with(source_class, *batch_parameters)`, and the default is _no batch parameters_. When you define a source, you should add the batch parameters to `def initialize(...)` and store them in instance variables.

  (`dataloader.with(source_class, *batch_parameters)` returns an instance of `source_class` with the given batch parameters -- but it might be an instance which was cached by `dataloader`.)

  Additionally, batch parameters are used to de-duplicate Source initializations during a query run. `.with(...)` calls that have the same batch parameters will use the same Source instance under the hood. To customize how Sources are de-duplicated, see {{ "GraphQL::Dataloader::Source.batch_key_for" | api_doc }}.

## Example: Loading Strings from Redis by Key

The simplest source might fetch values based on their keys. For example:

```ruby
# app/graphql/sources/redis_string.rb
class Sources::RedisString < GraphQL::Dataloader::Source
  REDIS = Redis.new
  def fetch(keys)
    # Redis's `mget` will return a value for each key with a `nil` for any not-found key.
    REDIS.mget(*keys)
  end
end
```

This loader could be used in GraphQL like this:

```ruby
some_string = dataloader.with(Sources::RedisString).load("some_key")
```

Calls to `.load(key)` will be batched, and when `GraphQL::Dataloader` can't go any further, it will dispatch a call to `def fetch(keys)` above.

## Example: Loading ActiveRecord Objects by ID

To fetch ActiveRecord objects by ID, the source should also accept the _model class_ as a batching parameter. For example:

```ruby
# app/graphql/sources/active_record_object.rb
class Sources::ActiveRecordObject < GraphQL::Dataloader::Source
  def initialize(model_class)
    @model_class = model_class
  end

  def fetch(ids)
    records = @model_class.where(id: ids)
    # return a list with `nil` for any ID that wasn't found
    ids.map { |id| records.find { |r| r.id == id.to_i } }
  end
end
```

This source could be used for any `model_class`, for example:

```ruby
author = dataloader.with(Sources::ActiveRecordObject, ::User).load(1)
post = dataloader.with(Sources::ActiveRecordObject, ::Post).load(1)
```

## Example: Batched Calculations

Besides fetching objects, Sources can return values from batched calculations. For example, a system could batch up checks for who a user follows:

```ruby
# for a given user, batch checks to see whether this user follows another user.
# (The default `user.followings.where(followed_user_id: followed).exists?` would cause N+1 queries.)
class Sources::UserFollowingExists < GraphQL::Dataloader::Source
  def initialize(user)
    @user = user
  end

  def fetch(handles)
    # Prepare a `SELECT id FROM users WHERE handle IN(...)` statement
    user_ids = ::User.where(handle: handles).select(:id)
    # And use it to filter this user's followings:
    followings = @user.followings.where(followed_user_id: user_ids)
    # Now, for followings that _actually_ hit a user, get the handles for those users:
    followed_users = ::User.where(id: followings.select(:followed_user_id))
    # Finally, return a result set, with one entry (true or false) for each of the given `handles`
    handles.map { |h| !!followed_users.find { |u| u.handle == h }}
  end
end
```

It could be used like this:

```ruby
is_following = dataloader.with(Sources::UserFollowingExists, context[:viewer]).load(handle)
```

After all requests were batched, `#fetch` will return a Boolean result to `is_following`.

## Example: Loading in a background thread

Inside `Source#fetch(keys)`, you can call `dataloader.yield` to return control to the Dataloader. This way, it will proceed loading other Sources (if there are any), then return the source that yielded.

A simple example, spinning up a new Thread:

```ruby
def fetch(keys)
  # spin up some work in a background thread
  thread = Thread.new {
    fetch_external_data(keys)
  }
  # return control to the dataloader
  dataloader.yield
  # at this point,
  # the dataloader has tried everything else and come back to this source,
  # so block if necessary:
  thread.value
end
```

See the {% internal_link "parallelism guide", "/dataloader/parallelism" %} for details about this approach.

## Filling the Dataloader Cache

If you load records from the database, you can use them to populate a source's cache by using {{ "Dataloader::Source#merge" | api_doc }}. For example:

```ruby
# Build a `{ key => value }` map to populate the cache
comments_by_id = post.comments.each_with_object({}) { |comment, hash| hash[comment.id] = comment }
# Merge the map into the source's cache
dataloader.with(Sources::ActiveRecordObject, Comment).merge(comments_by_id)
```

After that, any calls to `.load(id)` will use those already-loaded records if they're available.

## De-duplicating equivalent objects

Sometimes, _different_ objects in the application should load the same object from `fetch`. You can customize this behavior by implementing `def result_key_for(key)` in your application. For example, to map records from your ORM to their database ID:

```ruby
# Load the `created_by` person for a record from our database
class CreatedBySource < GraphQL::Dataloader::Source
  def result_key_for(key)
    key.id # Use the record's ID to deduplicate different `.load` calls
  end

  # Fetch a `person` for each of `records`, based on their created_by_id
  def fetch(records)
    PersonService.find_each(records.map(&:created_by_id))
  end
end
```

In this case, `records` will include the _first_ object for each unique `record.id` -- subsequent records with the same `.id` will be assumed to be duplicates. Under the hood, the `Source` will cache the result based on the record's `id`.

Alternatively, you could use this to make the `Source` retain each incoming object, even when they would _otherwise_ be treated as duplicates. (This would come in handy when you need `def fetch` to mutate each object). For example, to treat _every_ incoming object as distinct:

```ruby
def result_key_for(record)
  record.object_id # even if the records are equivalent, handle each distinct Ruby object separately
end
```
