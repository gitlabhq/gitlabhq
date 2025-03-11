---
layout: guide
doc_stub: false
search: true
enterprise: true
section: GraphQL Enterprise - Object Cache
title: Runtime Considerations
desc: Settings and observability per-query
index: 4
---

With caching configured, here are a few more things to keep in mind while queries are running.

## Skipping the cache

You can set `skip_object_cache: true` in your query `context: { ... }` to disable `ObjectCache` for a given query.

## Manually adding an object to caching

By default, `ObjectCache` gathers the objects "behind" each GraphQL object in the result, then uses their fingerprints as cache keys. To manually register another object with the cache while a query is running, call `Schema::Object.cacheable_object(...)`, passing the object and `context`. For example:

```ruby
field :team_member_count, Integer, null: true do
  argument :name, String, required: true
end

def team_member_count(name:)
  team = Team.find_by(name: name)
  if team
    # Register this object so that the cached result
    # will be invalidated when the team is updated:
    Types::Team.cacheable_object(team, context)
    team.members.count
  else
    nil
  end
end
```

(When the cache is disabled, `cacheable_object(...)` is a no-op.)

## Measuring the cache

While the cache is running, it logs some data in a Hash as `context[:object_cache]`. For example:

```ruby
result = MySchema.execute(...)
pp result.context[:object_cache]
{
  key: "...",                 # the cache key used for this query
  write: true,                # if this query caused an update to the cache
  ttl: 15,                    # the smallest `ttl:` value encountered in this query (used for this query's result)
  hit: true,                  # if this query returned a cached result
  public: false,              # true or false, whether this query used a public cache key or a private one
  messages: ["...", "..."],   # status messages about the cache's behavior
  objects: Set(...),          # application objects encountered during the query
  uncacheable: true,          # if ObjectCache found a reason that this query couldn't be cached (see `messages: ...` for reason)
  reauthorized_cached_objects: true,
                              # if `.authorized?` was checked for cached objects, see "Disabling Reauthorization"
}
```

## Manually refreshing the cache

If you need to manually clear the cache for a query, pass `context: { refresh_object_cache: true, ... }`. This will cause the `ObjectCache` to remove the already-cached result (if there was one), reassess the query for cache validity, and return a freshly-executed result.

Usually, this shouldn't be necessary; making sure objects update their {% internal_link "cache fingerprints", "/object_cache/schema_setup.html#object-fingerprint" %} will cause entries to expire when they should be re-executed. See also {% internal_link "Schema fingerprint", "/object_cache/schema_setup.html#schema-fingerprint %} for expiring _all_ results in the cache.
