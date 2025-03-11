---
layout: guide
doc_stub: false
search: true
enterprise: true
section: GraphQL Enterprise - Object Cache
title: Dalli Configuration
desc: Setting up the Memcached backend
index: 3
---

`GraphQL::Enterprise::ObjectCache` can also run with a Memcached backend via the [Dalli](https://github.com/petergoldstein/dalli) client gem.

Set it up by passing a `Dalli::Client` instance as `dalli: ...`, for example:

```ruby
use GraphQL::Enterprise::OperationStore, dalli: Dalli::Client.new(...)
```
