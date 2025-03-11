---
layout: guide
doc_stub: false
search: true
section: JavaScript Client
title: OperationStore Sync
desc: Javascript tooling for persisted queries with GraphQL-Ruby
index: 1
---

JavaScript support for GraphQL projects using [graphql-pro](https://graphql.pro)'s `OperationStore` for persisted queries.

- [`sync` CLI](#sync-utility)
- [Relay <2 support](#use-with-relay-2)
- [Relay 2+ support](#use-with-relay-persisted-output)
- [Apollo Client support](#use-with-apollo-client)
- [Apollo Link support](#use-with-apollo-link)
- [Apollo Codegen Support](#use-with-apollo-codegen)
- [Apollo Android support](#use-with-apollo-android)
- [Apollo Persisted Queries Support](#use-with-apollo-persisted-queries)
- [Plain JS support](#use-with-plain-javascript)
- [Authorization](#authorization)

See the {% internal_link "OperationStore guide", "/operation_store/overview" %} for server-side setup.

## `sync` utility

This package contains a command line utility, `graphql-ruby-client sync`:

```
$ graphql-ruby-client sync # ...
Authorizing with HMAC
Syncing 4 operations to http://myapp.com/graphql/operations...
  3 added
  1 not modified
  0 failed
Generating client module in app/javascript/graphql/OperationStoreClient.js...
✓ Done!
```

`sync` Takes several options:

option | description
--------|----------
`--url` | {% internal_link "Sync API", "/operation_store/getting_started.html#add-routes" %} url
`--path` | Local directory to search for `.graphql` / `.graphql.js` files
`--relay-persisted-output` | Path to a `.json` file from `relay-compiler ... --persist-output`
`--apollo-codegen-json-output` | Path to a `.json` file from `apollo client:codegen ... --target json`
`--apollo-android-operation-output` | Path to an `OperationOutput.json` file from Apollo Android
`--client` | Client ID ({% internal_link "created on server", "/operation_store/client_workflow" %})
`--secret` | Client Secret ({% internal_link "created on server", "/operation_store/client_workflow" %})
`--outfile` | Destination for generated code
`--outfile-type` | What kind of code to generate (`js` or `json`)
`--header={key}:{value}` | Add a header to the outgoing HTTP request (may be repeated)
`--add-typename` | Add `__typename` to all selection sets (for use with Apollo Client)
`--verbose` | Output some debug information
`--changeset-version` | Set a {% internal_link "Changeset Version", "/changesets/installation#controller-setup" %} when syncing these queries. (`context[:changeset_version]` will also be required at runtime, when running these stored operations.)
`--dump-payload` | A file to write the HTTP Post payload into, or if no filename is passed, then the payload will be written to stdout.

You can see these and a few others with `graphql-ruby-client sync --help`.

## Use with Relay <2

`graphql-ruby-client` can persist queries from `relay-compiler` using the embedded `@relayHash` value. (This was created in Relay before 2.0.0. See below for Relay 2.0+.)

To sync your queries with the server, use the `--path` option to point to your `__generated__` directory, for example:

```bash
# sync a Relay project
$ graphql-ruby-client sync --path=src/__generated__  --outfile=src/OperationStoreClient.js --url=...
```

Then, the generated code may be integrated with Relay's [Network Layer](https://facebook.github.io/relay/docs/network-layer.html):

```js
// ...
// require the generated module:
const OperationStoreClient = require('./OperationStoreClient')

// ...
function fetchQuery(operation, variables, cacheConfig, uploadables) {
  const requestParams = {
    variables,
    operationName: operation.name,
  }

  if (process.env.NODE_ENV === "production")
    // In production, use the stored operation
    requestParams.operationId = OperationStoreClient.getOperationId(operation.name)
  } else {
    // In development, use the query text
    requestParams.query = operation.text,
  }

  return fetch('/graphql', {
    method: 'POST',
    headers: { /*...*/ },
    body: JSON.stringify(requestParams),
  }).then(/* ... */);
}

// ...
```

(Only Relay Modern is supported. Legacy Relay can't generate static queries.)

## Use With Relay Persisted Output

To use Relay's persisted output, add a `"file": ...` to your project's [`persistConfig` object](https://relay.dev/docs/guides/persisted-queries/). For example:

```json
  "relay": {
    ...
    "persistConfig": {
      "file": "./persisted-queries.json"
    }
  },
```

Then, push Relay's generated queries to your OperationStore server with `--relay-persisted-output`:

```
$ graphql-ruby-client sync --relay-persisted-output=path/to/persisted-queries.json --url=...
```

In this case, `sync` _won't_ generate a JavaScript module because `relay-compiler` has already prepared its queries for persisted use. Instead, update your network layer to include the _client name_ and _operation id_ in the HTTP params:

```js
const operationStoreClientName = "MyRelayApp";

function fetchQuery(operation, variables,) {
  return fetch('/graphql', {
    method: 'POST',
    headers: {
      'content-type': 'application/json'
    },
    body: JSON.stringify({
      // Pass the client name and the operation ID, joined by `/`
      documentId: operationStoreClientName + "/" + operation.id,
      // query: operation.text, // this is now obsolete because text is null
      variables,
    }),
  }).then(response => {
    return response.json();
  });
}
```

(Inspired by https://relay.dev/docs/guides/persisted-queries/#network-layer-changes.)

Now, your Relay app will only send operation IDs over the wire to the server.

## Use with Apollo Client

Use the `--path` option to point at your `.graphql` files:

```
$ graphql-ruby-client sync --path=src/graphql/ --url=...
```

Then, load the generated module and add its `.apolloMiddleware` to your network interface with `.use([...])`:

```js
// load the generated module
var OperationStoreClient = require("./OperationStoreClient")

// attach it as middleware in production
// (in development, send queries to the server as normal)
if (process.env.NODE_ENV === "production") {
  MyNetworkInterface.use([OperationStoreClient.apolloMiddleware])
}
```

Now, the middleware will replace query strings with `operationId`s.

## Use with Apollo Link

Use the `--path` option to point at your `.graphql` files:

```
$ graphql-ruby-client sync --path=src/graphql/ --url=...
```

Then, load the generated module and add its `.apolloLink` to your Apollo Link:

```js
// load the generated module
var OperationStoreClient = require("./OperationStoreClient")

// Integrate the link to another link:
const link = ApolloLink.from([
  authLink,
  OperationStoreClient.apolloLink,
  httpLink,
])

// Create a client
const client = new ApolloClient({
  link: link,
  cache: new InMemoryCache(),
});
```

__Update the controller__: Apollo Link supports extra parameters _nested_ as `params[:extensions][:operationId]`, so update your controller to add that param to context:

```ruby
# app/controllers/graphql_controller.rb
context = {
  # ...
  # Support Apollo Link:
  operation_id: params[:extensions][:operationId]
}
```

Now, `context[:operation_id]` will be used to fetch a query from the database.

## Use with Apollo Codegen

Use `apollo client:codegen ... --target json` to build a JSON artifact containing your app's queries. Then, pass the path to that artifact to `graphql-ruby-client sync --apollo-codegen-json-output path/to/output.json ...`. `sync` will use Apollo-generated `operationId`s to populate the `OperationStore`.

Then, to use Apollo-style persisted query IDs, hook up the __Persisted Queries Link__ as described in [Apollo's documentation](https://www.apollographql.com/docs/react/api/link/persisted-queries/)

Finally, __update the controller__ to pass the Apollo-style persisted query ID as the operation ID:

```ruby
# app/controllers/graphql_controller.rb
context = {
  # ...
  # Support already-synced Apollo Persisted Queries:
  operation_id: params[:extensions][:operationId]
}
```

Now, Apollo-style persisted query IDs will be used to fetch operations from the server's `OperationStore`.

## Use with Apollo Android

Apollo Android's [generateOperationOutput option](https://www.apollographql.com/docs/android/advanced/persisted-queries/#operationoutputjson) builds an `OperationOutput.json` file which works with the OperationStore. To sync those queries, __use the `--apollo-android-operation-output` option__:

```sh
graphql-ruby-client sync --apollo-android-operation-output=path/to/OperationOutput.json --url=...
```

That way, the OperationStore will use the query IDs generated by Apollo Android.

On the server, you'll have to __update your controller__ to receive the client name and the operation ID. For example:

```ruby
# app/controllers/graphql_controller.rb
context = { ... }

# Check for an incoming operation ID from Apollo Client:
apollo_android_operation_id = request.headers["X-APOLLO-OPERATION-ID"]
if apollo_android_operation_id.present?
  # Check the incoming request to confirm that
  # it's your first-party client with stored operations
  client_name = # ...
  if client_name.present?
    # If we received an incoming operation ID
    # _and_ identified the client, run a persisted operation.
    context[:operation_id] = "#{client_name}/#{apollo_android_operation_id}"
  end
end
```

You may also have to __update your app__ to send an identifier, so that the server can determine the "client name" used with the operation store. (Apollo Android sends a query hash, but the operation store expects IDs in the form `#{client_name}/#{query_hash}`.)

## Use with Apollo Persisted Queries

Apollo client has a [Persisted Queries Link](https://www.apollographql.com/docs/react/api/link/persisted-queries/). You can use that link with GraphQL-Pro's {% internal_link "OperationStore", "/operation_store/overview" %}. First, create a manifest with [`generate-persisted-query-manifest`](https://www.apollographql.com/docs/react/api/link/persisted-queries/#1-generate-operation-manifests), then, pass the path to that file to `sync`:

```sh
$ graphql-ruby-client sync --apollo-persisted-query-manifest=path/to/manifest.json ...
```

Then, configure Apollo Client to [use your persisted query manifest](https://www.apollographql.com/docs/react/api/link/persisted-queries/#persisted-queries-implementation).

Finally, update your controller to receive the operation ID and pass it as `context[:operation_id]`:

```ruby
client_name = "..." # TODO: send the client name as a query param or header
persisted_query_hash = params[:extensions][:persistedQuery][:sha256Hash]
context = {
  # ...
  operation_id: "#{client_name}/#{persisted_query_hash}"
}
```

The `operation_id` will also need your client name. Using Apollo Client, you could send this as a [custom header](https://www.apollographql.com/docs/react/networking/basic-http-networking/#customizing-request-headers) or another way that works for your application (eg, session or user agent).

## Use with plain JavaScript

`OperationStoreClient.getOperationId` takes an operation name as input and returns the server-side alias for that operation:

```js
var OperationStoreClient = require("./OperationStoreClient")

OperationStoreClient.getOperationId("AppHomeQuery")       // => "my-frontend-app/7a8078c7555e20744cb1ff5a62e44aa92c6e0f02554868a15b8a1cbf2e776b6f"
OperationStoreClient.getOperationId("ProductDetailQuery") // => "my-frontend-app/6726a3b816e99b9971a1d25a1205ca81ecadc6eb1d5dd3a71028c4b01cc254c1"
```

Post the `operationId` in your GraphQL requests:

```js
// Lookup the operation name:
var operationId = OperationStoreClient.getOperationId(operationName)

// Include it in the params:
$.post("/graphql", {
  operationId: operationId,
  variables: queryVariables,
}, function(response) {
  // ...
})
```

## Authorization

`OperationStore` uses HMAC-SHA256 to {% internal_link "authenticate requests" , "/operation_store/access_control" %}.

Pass the key to `graphql-ruby-client sync` as `--secret` to authenticate it:

```bash
$ export MY_SECRET_KEY= "abcdefg..."
$ graphql-ruby-client sync ... --secret=$MY_SECRET_KEY
# ...
Authenticating with HMAC
# ...
```
