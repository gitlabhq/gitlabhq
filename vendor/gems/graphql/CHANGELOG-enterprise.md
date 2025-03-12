# graphql-enterprise

### Breaking Changes

### Deprecations

### New Features

### Bug Fix

# 1.5.6 (13 Dec 2024)

- ObjectCache: Add `CacheableRelation` helper for top-level ActiveRecord relations

# 1.5.5 (10 Dec 2024)

- Changesets: Add missing `ensure_loaded` call for class-based changesets

# 1.5.4 (31 Oct 2024)

- ObjectCache: Add `reauthorize_cached_objects: false`

# 1.5.3 (1 Oct 2024)

- Limiters: Add expiration to rate limit data (to reduce Redis footprint)

# 1.5.2 (6 Sept 2024)

- Limiters: Add `connection_pool:` support

# 1.5.1 (30 Aug 2024)

- ObjectCache: Add `connection_pool:` support

# 1.5.0 (26 Jul 2024)

- ObjectCache: Add Dalli backend for Memcached

# 1.4.2 (11 Jun 2024)

- ObjectCache: Add `Schema.fingerprint` hook and `context[:refresh_object_cache]`

# 1.4.1 (30 May 2024)

- ObjectCache: properly handle when object fingerprints are evicted but the cached result wasn't

# 1.4.0 (11 Apr 2024)

- ObjectCache: add support for `redis_cluster: ...` backend

# 1.3.4 (18 Mar 2024)

- ObjectCache: use new `trace_with` API for instrumentation

# 1.3.3 (30 Jan 2024)

- ObjectCache: fix compatibility with `run_graphql_field` test helper #4816

# 1.3.2 (15 Jan 2024)

### Bug Fix

- Limiters: Migrate to new `trace_with` instrumentation API, requires GraphQL-Ruby 2.0.18+

# 1.3.1 (12 June 2023)

### Bug Fix

- Add missing `require "graphql"` #4511

# 1.3.0 (29 May 2023)

### New Features

- Changesets: Add `added_in: ...` and `removed_in: ...` for inline definition changes

# 1.2.0 (10 February 2023)

### New Features

- Support the `redis-client` gem as `redis:` (requires graphql-pro 1.24.0+)

# 1.1.14 (3 November 2022)

### New Features

- Limiters: Support `dashboard_charts: false` to disable built-in instrumentation
- Limiters: Support `assign_as:` to use a different accessor method for storing limiter instances on schema classes (add a corresponding `class << self; attr_accessor ...; end` to the schema class to use it)
- Limiters: Support `context_key:` to put runtime info in a different key in query context
- Runtime Limiter: Add `window_ms:` to runtime info

# 1.1.13 (21 October 2022)

### Bug Fix

- Limiter: handle missing fields in MutationLimiter

# 1.1.12 (18 October 2022)

### New Features

- Limiters: add MutationLimiter

### Bug Fix

- ObjectCache: Update Redis calls to support redis-rb 5.0

# 1.1.11 (25 August 2022)

### Bug Fix

- ObjectCache: also update `delete` to handle more than 1000 objects in Lua

# 1.1.10 (19 August 2022)

### Bug Fix

- ObjectCache: read and write objects 1000-at-a-time to avoid overloading Lua scripts in Redis

# 1.1.9 (3 August 2022)

### New Features

- ObjectCache: Add a message to context when a type or field causes a query to be treated as "private"

### Bug Fix

- ObjectCache: skip the query analyzer when `context[:skip_object_cache]` is present

# 1.1.8 (1 August 2022)

### New Features

- ObjectCache: Add `ObjectType.cache_dependencies_for(object, context)` to customize dependencies for an object

### Bug Fix

- ObjectCache: Fix to make `context[:object_cache][:objects]` a Set
# 1.1.7 (28 July 2022)

### Bug Fix

- ObjectCache: remove needless `resolve_type` calls

# 1.1.6 (28 July 2022)

### Bug Fix

- ObjectCache: persist the type names of cached objects, pass them to `Schema.resolve_type` when validating cached responses.

# 1.1.5 (22 July 2022)

### New Features

- ObjectCache: add `cache_introspection: { ttl: ... }` for setting an expiration (in seconds) on introspection fields.

# 1.1.4 (19 March 2022)

### Bug Fix

- ObjectCache: don't create a cache fingerprint if the query is found to be uncacheable during analysis.

# 1.1.3 (3 March 2022)

### Bug Fix

- Changesets: Return an empty set when a schema doesn't use changesets #3972

# 1.1.2 (1 March 2022)

### New Features

- Changesets: Add introspection methods `Schema.changesets` and `Changeset.changes`

# 1.1.1 (14 February 2021)

### Bug Fix

- Changesets: don't require `context.schema` for plain-Ruby calls to introspection methods #3929

# 1.1.0 (24 November 2021)

### New Features

- Changesets: Add `GraphQL::Enterprise::Changeset`

# 1.0.1 (9 November 2021)

### Bug Fix

- Object Cache: properly handle invalid queries #3703

# 1.0.0 (13 October 2021)

### New Features

- Rate limiters: first release
- Object cache: first release
