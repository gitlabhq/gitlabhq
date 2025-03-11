---
layout: guide
doc_stub: false
search: true
section: GraphQL Pro - OperationStore
title: Overview
desc: Learn how persisted queries work and how OperationStore implements them.
index: 0
pro: true
---

`GraphQL::Pro::OperationStore` uses `Rack` and a storage backend ({% internal_link "ActiveRecord", "/operation_store/active_record_backend" %} or {% internal_link "Redis", "/operation_store/active_record_backend" %}) to maintain a normalized, deduplicated database of _persisted queries_ for your GraphQL system.

In this guide, you'll find:

- [Description of persisted queries](#what-are-persisted-queries)
- [The rationale](#why-persisted-queries) behind them
- [How `OperationStore` works](#how-it-works), in brief

In other guides, you can read more about:

- {% internal_link "Getting Started","/operation_store/getting_started" %} installing `OperationStore` in your app
- {% internal_link "Workflow","/operation_store/client_workflow" %} and usage for client apps
- {% internal_link "Authentication","/operation_store/access_control" %} for the sync API
- {% internal_link "Server Management","/operation_store/server_management" %} after your system is running

Also, you can find a [demo app on GitHub](https://github.com/rmosolgo/graphql-pro-operation-store-example).

## What are Persisted Queries?

_Persisted queries_ are GraphQL queries (`query`, `mutation`, or `subscription`) that are saved on the server and invoked by clients by _reference_. In this arrangement, clients don't send GraphQL queries over the network. Instead, clients send:

- __Client name__, to identify the client who is making the request
- __Query alias__, to specify which stored operation to run
- __Query variables__, to provide values for the stored operation

Then, the server uses the identifier to fetch the full GraphQL document from the database.

Without persisted queries, clients send the whole document:

```ruby
# Before, without persisted queries
query_string = "query GetUserDetails($userId: ID!) { ... }"

MyGraphQLEndpoint.post({
  query: query_string,
  operationName: "GetUserDetails",
  variables: { userId: "100" },
})
```


But with persisted queries, the full document isn't sent because the server already has a copy of it:

```ruby
# After, with persisted queries:
MyGraphQLEndpoint.post({
  operationId: { "relay-app-v1/fc84dbba3623383fdc",
  #               client name / query alias (eg, @relayHash)
  variables: { userId: "100" },
})
```

## Why Persisted Queries?

Using persisted queries improves the _security_, _efficiency_ and _visibility_ of your GraphQL system.


### Security

Persisted queries improve security because you can reject arbitrary GraphQL queries, removing an attack vector from your system. The query database serves a whitelist, so you can be sure that no unexpected queries will hit your system.

For example, after all clients have migrated to persisted queries, you can reject arbitrary GraphQL in production:

```ruby
# app/controllers/graphql_controller.rb
if Rails.env.production? && params[:query].present?
  # Reject arbitrary GraphQL in production:
  render json: { errors: [{ message: "Raw GraphQL is not accepted" }]}
else
  # ...
end
```

### Efficiency

Persisted queries improve the _efficiency_ of your system by reducing HTTP traffic. Instead of repeatedly sending GraphQL over the wire, queries are fetched from the database, so your requests require less bandwidth.

For example, _before_ using persisted queries, the entire query is sent to the server:

{{ "/operation_store/request_before.png" | link_to_img:"GraphQL request without persisted queries" }}

But _after_ using persisted queries, only the query identification info is sent to the server:

{{ "/operation_store/request_after.png" | link_to_img:"GraphQL request with persisted queries" }}

### Visibility

Persisted queries improve _visibility_ because you can track GraphQL usage from a single location. `OperationStore` maintains an index of type, field and argument usage so that you can analyze your traffic.

{{ "/operation_store/operation_index.png" | link_to_img:"Index of GraphQL usage with persisted queries" }}

## How it Works

`OperationStore` uses tables in your database to store normalized, deduplicated GraphQL strings. The database is immutable: new operations may be added, but operations are never modified or removed.

When clients {% internal_link "sync their operations","/operation_store/client_workflow" %}, requests are {% internal_link "authenticated","/operation_store/access_control" %}, then the incoming GraphQL is validated, normalized, and added to the database if needed. Also, the incoming client name is associated with all operations in the payload.

Then, at runtime, clients send an _operation ID_ to run a persisted query. It looks like this in `params`:

```ruby
params[:operationId] # => "relay-app-v1/810c97f6631001..."
```

`OperationStore` uses this to fetch the matching operation from the database. From there, the query is evaluated normally.

## Getting Started

See the {% internal_link "getting started guide","/operation_store/getting_started" %} to add `OperationStore` to your app.
