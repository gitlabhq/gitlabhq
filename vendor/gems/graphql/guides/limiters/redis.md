---
layout: guide
doc_stub: false
search: true
enterprise: true
section: GraphQL Enterprise - Rate Limiters
title: Configuring Redis
desc: Preparing the rate limiter backend
index: 1
---

Rate limiting requires persistent Redis instance, just like [Sidekiq](https://github.com/mperham/sidekiq/wiki/Using-Redis) or the {% internal_link "Operation Store", "/operation_store/redis_backend" %}. Set `maxmemory-policy noeviction` in `redis.conf` to ensure that Redis doesn't silently drop keys when it reaches its memory limit.

## Memory Usage

Estimating memory usage depends on the string used to identify clients, since those are used in the Redis keys. Using 100-character client keys, the runtime limiter uses 400 bytes per client (two keys). Memory usage by the active operation limiter depends on the limit because each concurrent operation uses some memory; a higher limit permits more concurrent operations. With 10 active operations and a 100-character client key, the active operation limiter uses 350 bytes per client. Additionally, the limiters use up to 35kb for dashboards (2 limiters, for each one: 2x 60 per-minute keys, 24 hourly keys, and 30 daily keys @ 72 bytes per key).

By those estimates, 1 gigabyte of memory would support both rate limiters for over 1.4 million active clients.
