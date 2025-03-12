---
layout: guide
doc_stub: false
search: true
enterprise: true
section: GraphQL Enterprise - Rate Limiters
title: Rate Limiters for GraphQL
desc: Manage access to your GraphQL API
index: 0
---


`GraphQL::Enterprise` includes rate limiters built especially for GraphQL.

For REST APIs, rate limiters often count _requests_ and block clients when they exceed their limit over a certain period of time. However, this paradigm doesn't translate well to GraphQL because the cost of serving a request may vary dramatically depending on the GraphQL query contained in the request. Instead, `GraphQL::Enterprise` implements two other kinds of limiters:

- An __active operation limiter__ which allows clients to run a certain number of operations _at a time_. For example, if the limit is five concurrent operations, and a client sends six requests simultaneously, then only five of those incoming operations will be executed; the sixth will be returned with an error and it may be retried when one of the five others finishes.
- A __runtime limiter__ which limits the amount of processing time a client may consume during a given window. For example, a limit of 120 seconds per minute would allow two concurrent requests on average -- although in practice, it might be spiky: perhaps five concurrent, 20-second-long requests, followed by 40 seconds of no requests.

There's some overlap in these limiters; both of them constrain the amount of _time_ a client may force the server to spend in handling requests. The active operation limiter puts an upper bound on how _many_ processes a client may occupy while the runtime limiter puts a bound on total processing time (regardless of the number of concurrent operations at a given moment).

To get started, read on:

- {% internal_link "Configure Redis", "limiters/redis" %} for the limiters' backend
- {% internal_link "Active Operation Limiter", "limiters/active_operations" %}
- {% internal_link "Runtime Limiter", "limiters/runtime" %}
