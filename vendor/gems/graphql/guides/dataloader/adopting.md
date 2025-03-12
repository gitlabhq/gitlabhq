---
layout: guide
search: true
section: Dataloader
title: Dataloader vs. GraphQL-Batch
desc: Comparing and Contrasting Batch Loading Options
index: 3
---

{{ "GraphQL::Dataloader" | api_doc }} solves the same problem as [`GraphQL::Batch`](https://github.com/shopify/graphql-batch). There are a few major differences between the modules:


- __Concurrency Primitive:__ GraphQL-Batch uses `Promise`s from [`promise.rb`](https://github.com/lgierth/promise.rb); GraphQL::Dataloader uses Ruby's [`Fiber` API](https://ruby-doc.org/core-3.0.0/Fiber.html). These primitives dictate how batch loading code is written (see below for comparisons).
- __Maturity:__ Frankly, GraphQL-Batch is about as old as GraphQL-Ruby, and it's been in production at Shopify, GitHub, and others for many years. GraphQL::Dataloader is new, and although Ruby has supported `Fiber`s since 1.9, they still aren't widely used.
- __Scope:__ It's not currently possible to use `GraphQL::Dataloader` _outside_ GraphQL.

The incentive in writing `GraphQL::Dataloader` was to leverage `Fiber`'s ability to _transparently_ pause and resume work, which removes the need for `Promise`s (and removes the resulting complexity in the code). Additionally, `GraphQL::Dataloader` should _eventually_ support Ruby 3.0's `Fiber.scheduler` API, which runs I/O in the background by default.

## Comparison: Fetching a single object

In this example, a single object is batch-loaded to satisfy a GraphQL field.

- With __GraphQL-Batch__, you call a loader, which returns a `Promise`:

  ```ruby
  record_promise = Loaders::Record.load(1)
  ```

  Then, under the hood, GraphQL-Ruby manages the promise (using its `lazy_resolve` feature, upstreamed from GraphQL-Batch many years ago). GraphQL-Ruby will call `.sync` on it when no further execution is possible; `promise.rb` implements `Promise#sync` to execute the pending work.

- With __GraphQL::Dataloader__, you get a source, then call `.load` on it, which may pause the current Fiber, but it returns the requested object.

  ```ruby
  dataloader.with(Sources::Record).load(1)
  ```

  Since the requested object is (eventually) returned from `.load`, Nothing else is required.

## Comparison: Fetching objects in sequence (dependent)

In this example, one object is loaded, then another object is loaded _based on_ the first one.

- With __GraphQL-Batch__, `.then { ... }` is used to join dependent code blocks:

  ```ruby
  Loaders::Record.load(1).then do |record|
    Loaders::OtherRecord.load(record.other_record_id)
  end
  ```

  That call returns a `Promise`, which is stored by GraphQL-Ruby, and finally `.sync`ed.

- With __GraphQL-Dataloader__, `.load(...)` returns the requested object (after a potential `Fiber` pause), so no other method calls are necessary:

  ```ruby
  record = dataloader.with(Sources::Record).load(1)
  dataloader.with(Sources::OtherRecord).load(record.other_record_id)
  ```

## Comparison: Fetching objects concurrently (independent)

Sometimes, you need multiple _independent_ records to perform a calculation. Each record is loaded, then they're combined in some bit of work.

- With __GraphQL-Batch__, `Promise.all(...)` is used to to wait for several pending loads:

  ```ruby
  promise_1 = Loaders::Record.load(1)
  promise_2 = Loaders::OtherRecord.load(2)
  Promise.all([promise_1, promise_2]).then do |record, other_record|
    do_something(record, other_record)
  end
  ```

  If the objects are loaded from the same loader, then `.load_many` also works:

  ```ruby
  Loaders::Record.load_many([1, 2]).then do |record, other_record|
    do_something(record, other_record)
  end
  ```

- With __GraphQL::Dataloader__, each request is registered with `.request(...)` (which never pauses the Fiber), then data is loaded with `.load` (which will pause the Fiber as needed):

  ```ruby
  # first, make some requests
  request_1 = dataloader.with(Sources::Record).request(1)
  request_2 = dataloader.with(Sources::OtherRecord).request(2)
  # then, load the objects and do something
  record = request_1.load
  other_record = request_2.load
  do_something(record, other_record)
  ```

  If the objects come from the same `Source`, then `.load_all` will return the objects directly:

  ```ruby
  record, other_record = dataloader.with(Sources::Record).load_all([1, 2])
  do_something(record, other_record)
  ```
