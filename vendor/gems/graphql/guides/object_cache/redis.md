---
layout: guide
doc_stub: false
search: true
enterprise: true
section: GraphQL Enterprise - Object Cache
title: Redis Configuration
desc: Setting up the Redis backend
index: 3
---

`GraphQL::Enterprise::ObjectCache` requires a Redis connection to store cached responses. Unlike `OperationStore` or rate limiters, this Redis instance should be configured to evict keys as needed.

## Memory Management

Memory consumption is hard to estimate since it depends on how many queries the cache receives, how many objects those queries reference, how big the response is for those queries, and how long the fingerprints are for each object and query. To manage memory, configure the Redis instance with a `maxmemory` and `maxmemory-policy` directive, for example:


```
maxmemory 1gb
maxmemory-policy allkeys-lfu
```

Additionally, consider conditionally skipping the cache to prioritize your most critical GraphQL traffic.

## Redis Cluster

`ObjectCache` also supports Redis Cluster. To use, pass `redis_cluster:`:

```ruby
use GraphQL::Enterprise::ObjectCache, redis_cluster: Redis::Cluster.new(...)
```

Under the hood, it uses query fingerprints as [hash tags](https://redis.io/docs/latest/operate/oss_and_stack/reference/cluster-spec/#hash-tags) and each cached result has its own set of object metadata.

## Connection Pool

`ObjectCache` also supports [ConnectionPool](https://github.com/mperham/connection_pool). To use it, pass `connection_pool:`:

```ruby
use GraphQL::Enterprise::ObjectCache, connection_pool: ConnectionPool.new(...) { ... }
```

## Data Structure

Under the hood, `ObjectCache` stores a mapping of queries and objects. Additionally, there are back-references from objects to queries that reference them. In general, like this:

```
"query1:result" => '{"data":{...}}'
"query1:objects" => ["obj1:v1", "obj2:v2"]

"query2:result" => '{"data":{...}}'
"query2:objects" => ["obj2:v2", "obj3:v1"]

"obj1:v1" => { "fingerprint" => "...", "id" => "...", "type_name" => "..." }
"obj2:v2" => { "fingerprint" => "...", "id" => "...", "type_name" => "..." }
"obj3:v1" => { "fingerprint" => "...", "id" => "...", "type_name" => "..." }

"obj1:v1:queries" => ["query1"]
"obj2:v2:queries" => ["query1", "query2"]
"obj3:v1:queries" => ["query2"]
```

These mappings enable proper clean-up when queries or objects are expired from the cache. Additionally, whenever `ObjectCache` finds incomplete data in storage (for example, a necessary key was evicted), then it invalidates the whole query and re-runs it.
