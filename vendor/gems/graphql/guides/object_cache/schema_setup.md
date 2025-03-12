---
layout: guide
doc_stub: false
search: true
enterprise: true
section: GraphQL Enterprise - Object Cache
title: Schema Setup
desc: Prepare your schema to serve cached responses
index: 1
---

To prepare the schema to serve cached responses, you have to add `GraphQL::Enterprise::ObjectCache` and implement a few hooks.

## Add the Cache

In your schema, add `use GraphQL::Enterprise::ObjectCache, redis: ...`:

```ruby
class MySchema < GraphQL::Schema
  use GraphQL::Enterprise::ObjectCache, redis: CACHE_REDIS
end
```

See the {% internal_link "Redis guide", "/object_cache/redis" %} or {% internal_link "Memcached guide", "/object_cache/memcached" %} for details about configuring cache storage.

Additionally, it accepts some options for customizing how introspection is cached, see {% internal_link "Caching Introspection", "/object_cache/caching#caching-introspection" %}

## Context Fingerprint

Additionally, you should implement `def self.private_context_fingerprint_for(context)` to return a string identifying the private scope of the given context. This method will be called whenever a query includes a {% internal_link "`public: false` type or field", "/object_cache/caching#public" %}. For example:

```ruby
class MySchema < GraphQL::Schema
  # ...
  def self.private_context_fingerprint_for(context)
    viewer = context[:viewer]
    if viewer.nil?
      # This should never happen, but just in case:
      raise("Invariant: No viewer in context! Can't create a private context fingerprint" )
    end

    # include permissions in the fingerprint so that if the viewer's permissions change, the cache will be invalidated
    permission_fingerprint = viewer.team_memberships.map { |tm| "#{tm.team_id}/#{tm.permission}" }.join(":")

    "user:#{viewer.id}:#{permission_fingerprint}"
  end
end
```

Whenever queries including `public: false` are cached, the private context fingerprint will be part of the cache key, preventing responses from being shared between different viewers.

The returned String should reflect any aspects of `context` that, if changed, should invalidate the cache. For example, if a user's permission level or team memberships change, then any previously-cached responses should be ignored.

## Object Fingerprint

In order to determine whether cached results should be returned or invalidated, GraphQL needs a way to determine the "version" of each object in the query. It uses `Schema.object_fingerprint_for(object)` to do this. By default, it checks `.cache_key_with_version` (implemented by Rails), then `.to_param`, then it returns `nil`. Returning `nil` tells the cache not to use the cache _at all_. To customize this behavior, you can implement `def self.object_fingerprint_for(object)` in your schema:

```ruby
class MySchema < GraphQL::Schema
  # ...

  # For example, if you defined `.custom_cache_key` and `.uncacheable?`
  # on objects in your application:
  def self.object_fingerprint_for(object)
    if object.respond_to?(:custom_cache_key)
      object.custom_cache_key
    elsif object.respond_to?(:uncacheable?) && object.uncacheable?
      nil # don't cache queries containing this object
    else
      super
    end
  end
end
```

The returned strings are used as cache keys in the database -- whenever they change, stale data is left to be {% internal_link "cleaned up by Redis", "/object_cache/redis#memory-management" %}.

## Object Identification

`ObjectCache` depends on object identification hooks used elsewhere in GraphQL-Ruby:

- `def self.id_from_object(object, type, context)` which returns a globally-unique String id for `object`
- `def self.object_from_id(id, context)` which returns the application object for the given globally-unique `id`
- `def self.resolve_type(abstract_type, object, context)` which returns a GraphQL object type definition to use for `object`

After your schema is setup, you can {% internal_link "configure caching on your types and fields", "/object_cache/caching", %}.

## Schema Fingerprint

 `ObjectCache` will also call `.fingerprint` on your Schema class. You can implement this method to return a new string if you make breaking changes to your schema, for example:

 ```ruby
class MySchema < GraphQL::Schema
  def self.fingerprint
    "v2" # increment this if there are breaking changes to the schema
  end
end
```

By returning a new `MySchema.fingerprint`, _all_ previously-cached results will be expired.

## Disabling Reauthorization

By default, `ObjectCache` checks `.authorized?` on each object before returning a cached result. However, if all authorization-related considerations are present in the object's cache fingerprint, then you can disable this check in two ways:

- __per-query__, by passing `context: { reauthorize_cached_objects: false }`
- __globally__, by configuring `use GraphQL::Enterprise::ObjectCache, ... reauthorize_cached_objects: false`
