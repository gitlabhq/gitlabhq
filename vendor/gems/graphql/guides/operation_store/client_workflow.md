---
layout: guide
doc_stub: false
search: true
section: GraphQL Pro - OperationStore
title: Client Workflow
desc: Add clients to the system, then sync their operations with the database.
index: 4
pro: true
---

To use persisted queries with your client application, you must:

- Set up `OperationStore`, as described in {% internal_link "Getting Started","/operation_store/getting_started" %}
- [Add the client](#add-a-client) to the system
- [Sync operations](#syncing) from the client to the server
- [Send `params[:operationId]`](#client-usage) from the client app

This documentation also touches on {% internal_link "graphql-ruby-client sync", "/javascript_client/sync" %}, a JavaScript client library for using `OperationStore`.

## Add a Client

Clients are registered via {% internal_link "the dashboard","/operation_store/getting_started#add-routes" %}:

{{ "/operation_store/add_a_client.png" | link_to_img:"Add a Client for Persisted Queries" }}

A default `secret` is provided for you, but you can also enter your own. The `secret` is used for {% internal_link "HMAC authentication", "/operation_store/access_control" %}.

(Are you interested in a Ruby API for this? Please {% open_an_issue "OperationStore Ruby API" %} or email `support@graphql.pro`.)

## Syncing

Once a client is registered, it can push queries to the server via {% internal_link "the Sync API","/operation_store/getting_started#add-routes" %}.

The easiest way to sync is with `graphql-ruby-client sync`, a command-line tool written in JavaScript ({% internal_link "Sync Guide", "/javascript_client/sync" %})

In short, it:

- Finds GraphQL queries from `.graphql` files or `relay-compiler` output in the provided `--path`
- Adds an {% internal_link "Authentication header","/operation_store/access_control" %} based on the provided `--client` and `--secret`
- Sends the operations to the provided `--url`
- Generates a JavaScript module into the provided `--outfile`

For example:

{{ "/operation_store/sync_example.png" | link_to_img:"OperationStore client sync" }}

For help syncing in another language, you can take inspiration from the [JavaScript implementation](https://github.com/rmosolgo/graphql-ruby/tree/master/javascript_client), {% open_an_issue "Implementing operation sync in another language" %}, or email `support@graphql.pro`.

## Client Usage

See the {% internal_link "Sync Guide", "/javascript_client/sync" %} for using OperationStore with Relay Modern, Apollo 1.x, Apollo Link, or plain JavaScript.

To run stored operations from another client, send a param called `operationId` which is composed of:


```ruby
 {
   # ...
   operationId: "my-relay-app/ce79aa2784fc..."
   #            ^ client id  / ^ operation id
 }
```

The server will use those values to fetch an operation from the database.

### Next Steps

Learn more about `OperationStore`'s {% internal_link "authentication", "/operation_store/access_control" %} or read some tips for {% internal_link "server management","/operation_store/server_management" %}.
