---
layout: guide
doc_stub: false
search: true
enterprise: true
section: GraphQL Enterprise - Object Cache
title: Caching Results
desc: Configuration options for caching objects and fields
index: 2
---

`GraphQL::Enterprise::ObjectCache` supports several different caching configurations for objects and fields. To get started, include the extension in your base object class and base field class and use `cacheable(...)` to set up the default cache behavior:

```ruby
# app/graphql/types/base_object.rb
class Types::BaseObject < GraphQL::Schema::Object
  include GraphQL::Enterprise::ObjectCache::ObjectIntegration
  field_class Types::BaseField
  cacheable(...) # see below
  # ...
end
```

```ruby
# app/graphql/types/base_field.rb
class Types::BaseField < GraphQL::Schema::Field
  include GraphQL::Enterprise::ObjectCache::FieldIntegration
  cacheable(...) # see below
  # ...
end
```

Also, make sure your base interface module is using your field class:

```ruby
# app/graphql/types/base_interface.md
module Types::BaseInterface
 field_class Types::BaseField
end
```

Field caching can be configured per-field, too, for example:

```ruby
field :latest_update, Types::Update, null: false, cacheable: { ttl: 60 }

field :random_number, Int, null: false, cacheable: false
```

Only _queries_ are cached. `ObjectCache` skips mutations and subscriptions altogether.

## `cacheable(true|false)`

`cacheable(true)` means that the configured type or field may be stored in the cache until its cache fingerprint changes. It also defaults to `public: false`, meaning that clients will _not_ share cached responses. See [`public:`](#public) below for more about this option.

`cacheable(false)` disables caching for the configured type or field. Any query that includes this type or field will neither check for an already-cached value nor update the cache with its result.

## `public:`

`cacheable(public: false)` means that a type or field may be _cached_, but {% internal_link "`Schema.private_context_fingerprint_for(ctx)`", "/object_cache/schema_setup#context-fingerprint" %} should be included in its cache key. In practice, this means that each client can have its own cached responses. Any query that contains a `cacheable(public: false)` type or field will use a private cache key.

`cacheable(public: true)` means that cached values from this type or field may be shared by _all_ clients. Use this for public-facing data which is the same for all viewers. Queries that include _only_ `public: true` types and fields will not include `Schema.private_context_fingerprint_for(ctx)` in their cache keys. That way their responses will be shared by all clients who request them.

## `ttl:`

`cacheable(ttl: seconds)` expires any cached value after the given number of seconds, regardless of cache fingerprint. `ttl:` shines in a few cases:

- Objects that can't reliably generate a fingerprint value (for example, they have no `.updated_at` timestamp). In this case, a conservative `ttl` may be the only option for cache expiration.
- Or, root-level fields that should be expired after a certain amount of time. The root-level `Query` often has _no_ backing object, so it won't have a cache fingerprint, either. Adding `cacheable: { ttl: ... }` to root level fields will provide some caching along with a guarantee about when they'll be expired.
- Or, list responses that may be difficult to invalidate properly (see below).

Under the hood, `ttl:` is implemented with Redis's `EXPIRE`.

## Caching lists and connections

Lists and connections require a little extra consideration. By default, each _item_ in a list is registered with the cache, but when new items are created, they are unknown to the cache and therefore don't invalidate the cached result. There are two main approaches to address this.

### `has_many` lists

In order to effectively bust the cache, items that belong to the list of "parent" object should __update the parent__ (eg, Rails `.touch`) whenever they're created, destroyed, or updated. For example, if there's a list of players on a team:

```graphql
{
  team { players { totalCount } }
}
```

None of the _specific_ `Player`s will be part of the cached response, but the `Team` will be. To properly invalidate the cache, the `Team`'s `updated_at` (or other cache key) should be updated whenever a `Player` is added or removed from the `Team`.

If a list may be sorted, then updates to `Player`s should also update the `Team` so that any sorted results in the cache are invalidated, too. Alternatively (or additionally), you could use a `ttl:` to expire cached results after a certain duration, just to be sure that results are eventually expired.

With Rails, you can accomplish this with:

```ruby
  # update the team whenever a player is saved or destroyed:
  belongs_to :team, touch: true
```

### Top-level lists

For `ActiveRecord::Relation`s _without_ a "parent" object, you can use `GraphQL::Enterprise::ObjectCache::CacheableRelation` to make a synthetic cache entry for the _whole_ relation. To use this class, make a subclass and implement `def items`, for example:

```ruby
class AllTeams < GraphQL::Enterprise::ObjectCache::CacheableRelation
  def items(division: nil)
    teams = Team.all
    if division
      teams = teams.where(division: division)
    end
    teams
  end
end
```

Then, in your resolver, use your new class to retrieve the items:

```ruby
class Query < GraphQL::Schema::Object
  field :teams, Team.connection_type do
    argument :division, Division, required: false
  end

  def teams(division: nil)
    AllTeams.items_for(self, division: division)
  end
end
```

If you're using {{ "GraphQL::Schema::Resolver" | api_doc }}, you'd call `.items_for` slightly differently:

```ruby
def resolve(division: nil)
  # use `context[:current_object]` to get the GraphQL::Schema::Object instance whose field is being resolved
  AllTeams.items_for(context[:current_object], division: division)
end
```

Finally, you'll need to handle `CacheableRelation`s in your object identification methods, for example:

```ruby
class MySchema < GraphQL::Schema
  # ...
  def self.id_from_object(object, type, ctx)
    if object.is_a?(GraphQL::Enterprise::ObjectCache::CacheableRelation)
      object.id
    else
      # The rest of your id_from_object logic here...
    end
  end

  def self.object_from_id(id, ctx)
    if (cacheable_rel = GraphQL::Enterprise::ObjectCache::CacheableRelation.find?(id))
      cacheable_rel
    else
      # The rest of your object_from_id logic here...
    end
  end
end
```

In this example, `AllTeams` implements several methods to support caching:

- `#id` creates a cache-friendly, stable global ID
- `#to_param` creates a cache fingerprint (using Rails's `#cache_key` under the hood)
- `.find?` retrieves the list based on its ID

This way, if a `Team` is created, the cached result will be invalidated and a fresh result will be created.

Alternatively (or additionally), you could use a `ttl:` to expire cached results after a certain duration, just to be sure that results are eventually expired.

### Connections

By default, connection-related objects (like `*Connection` and `*Edge` types) "inherit" cacheability from their node types. You can override this in your base classes as long as `GraphQL::Enterprise::ObjectCache::ObjectIntegration` is included in the inheritance chain somewhere.

## Caching Introspection

By default, introspection fields are considered _public_ for all queries. This means that they are considered cacheable and their results will be reused for any clients who request them. When {% internal_link "adding the ObjectCache to your schema", "/object_cache/schema_setup#add-the-cache", %}, you can provide some options to customize this behavior:

- `cache_introspection: { public: false, ... }` to use [`public: false`](#public) for all introspection fields. Use this if you hide schema members for some clients.
- `cache_introspection: false` to completely disable caching on introspection fields.
- `cache_introspection: { ttl: ..., ... }` to set a [ttl](#ttl) (in seconds) for introspection fields.

## Object Dependencies

By default, the `object` of a GraphQL Object type is used for caching the fields selected on that object. But, you can specify what object (or objects) should be used to check the cache by implementing `def self.cache_dependencies_for(object, context)` in your type definition. For example:

```ruby
class Types::Player
  def self.cache_dependencies_for(player, context)
    # we update the team's timestamp whenever player details change,
    # so ignore the `player` for caching purposes
    player.team
  end
end
```

Use this to:

- improve performance when caching lists of children that belong to a parent object
- register other objects with the ObjectCache when running a query. (`cacheable_object(obj)` or `def self.object_fingerprint_for` can also be used in this case.)

If this method returns an `Array`, each object in the array will be registered with the cache.
