---
layout: guide
doc_stub: false
search: true
section: JavaScript Client
title: Relay Subscriptions
desc: GraphQL subscriptions with GraphQL-Ruby and Relay Modern
index: 3
---

`graphql-ruby-client` includes three kinds of support for subscriptions with Relay Modern:

- [Pusher](#pusher)
- [Ably](#ably)
- [ActionCable](#actioncable)

To use it, require `graphql-ruby-client/subscriptions/createRelaySubscriptionHandler` and call the function with your client and optionally, your OperationStoreClient.

__Note:__ For Relay <11, use `import { createLegacyRelaySubscriptionHandler } from "graphql-ruby-client/subscriptions/createRelaySubscriptionHandler"` instead; the signature changed in Relay 11.


See the {% internal_link "Subscriptions guide", "/subscriptions/overview" %} for information about server-side setup.

## Pusher

Subscriptions with {% internal_link "Pusher", "/subscriptions/pusher_implementation" %} require two things:

- A client from the [`pusher-js` library](https://github.com/pusher/pusher-js)
- A [`fetchOperation` function](#fetchoperation-function) for sending the `subscription` operation to the server

### Pusher client

Pass `pusher:` to get Subscription updates over Pusher:

```js
// Load the helper function
import createRelaySubscriptionHandler from "graphql-ruby-client/subscriptions/createRelaySubscriptionHandler"

// Prepare a Pusher client
var Pusher = require("pusher-js")
var pusherClient = new Pusher(appKey, options)

// Create a fetchOperation, see below for more details
function fetchOperation(operation, variables, cacheConfig) {
  return fetch(...)
}

// Create a Relay Modern-compatible handler
var subscriptionHandler = createRelaySubscriptionHandler({
  pusher: pusherClient,
  fetchOperation: fetchOperation
})

// Create a Relay Modern network with the handler
var network = Network.create(fetchQuery, subscriptionHandler)
```

### Compressed Payloads

If you're using {% internal_link "compressed payloads", "/subscriptions/pusher_implementation#compressed-payloads" %}, configure a `decompress:` function, too:

```javascript
// Add `pako` to the project for gunzipping
import pako from "pako"

var subscriptionHandler = createRelaySubscriptionHandler({
  pusher: pusherClient,
  fetchOperation: fetchOperation,
  decompress: function(compressed) {
    // Decode base64
    const data = btoa(compressed)
    // Decompress
    const payloadString = pako.inflate(data, { to: 'string' })
    // Parse into an object
    return JSON.parse(payloadString);
  }
})
```

## Ably

Subscriptions with {% internal_link "Ably", "/subscriptions/ably_implementation" %} require two things:

- A client from the [`ably-js` library](https://github.com/ably/ably-js)
- A [`fetchOperation` function](#fetchoperation-function) for sending the `subscription` operation to the server

### Ably client

Pass `ably:` to get Subscription updates over Ably:

```js
// Load the helper function
import createRelaySubscriptionHandler from "graphql-ruby-client/subscriptions/createRelaySubscriptionHandler"

// Load Ably and create a client
const Ably = require("ably")
const ablyClient = new Ably.Realtime({ key: "your-app-key" })

// create a fetchOperation, see below for more details
function fetchOperation(operation, variables, cacheConfig) {
  return fetch(...)
}

// Create a Relay Modern-compatible handler
var subscriptionHandler = createRelaySubscriptionHandler({
  ably: ablyClient,
  fetchOperation: fetchOperation
})

// Create a Relay Modern network with the handler
var network = Network.create(fetchQuery, subscriptionHandler)
```

## ActionCable

With this configuration, `subscription` queries will be routed to {% internal_link "ActionCable", "/subscriptions/action_cable_implementation" %}.

For example:

```js
// Require the helper function
import createRelaySubscriptionHandler from "graphql-ruby-client/subscriptions/createRelaySubscriptionHandler")
// Optionally, load your OperationStoreClient
var OperationStoreClient = require("./OperationStoreClient")

// Create a Relay Modern-compatible handler
var subscriptionHandler = createRelaySubscriptionHandler({
  cable: createConsumer(...),
  operations: OperationStoreClient,
})

// Create a Relay Modern network with the handler
var network = Network.create(fetchQuery, subscriptionHandler)
```

## With Relay Persisted Queries

If you're using Relay's built-in [persisted query support](https://relay.dev/docs/guides/persisted-queries/), you can pass `clientName:` to the handler in order to build IDs that work with the {% internal_link "OperationStore", "/operation_store/overview.html" %}. For example:

```js
var subscriptionHandler = createRelaySubscriptionHandler({
  cable: createConsumer(...),
  clientName: "web-frontend", // This should match the one you use for `sync`
})

// Create a Relay Modern network with the handler
var network = Network.create(fetchQuery, subscriptionHandler)
```

Then, the ActionCable handler will use Relay's provided operation IDs to interact with the OperationStore.

## fetchOperation function

The `fetchOperation` function can be extracted from your `fetchQuery` function. Its signature is:

```js
// Returns a promise from `fetch`
function fetchOperation(operation, variables, cacheConfig) {
  return fetch(...)
}
```

- `operation`, `variables`, and `cacheConfig` are the first three arguments to the `fetchQuery` function.
- The function should call `fetch` and return the result (a Promise of a `Response`).

For example, `Environment.js` may look like:

```js
// This function sends a GraphQL query to the server
const fetchOperation = function(operation, variables, cacheConfig) {
  const bodyValues = {
    variables,
    operationName: operation.name,
  }
  const useStoredOperations = process.env.NODE_ENV === "production"
  if (useStoredOperations) {
    // In production, use the stored operation
    bodyValues.operationId = OperationStoreClient.getOperationId(operation.name)
  } else {
    // In development, use the query text
    bodyValues.query = operation.text
  }
  return fetch('http://localhost:3000/graphql', {
    method: 'POST',
    opts: {
      credentials: 'include',
    },
    headers: {
      'Accept': 'application/json',
      'Content-Type': 'application/json'
    },
    body: JSON.stringify(bodyValues),
  })
}

// `fetchQuery` uses `fetchOperation`, but returns a Promise of JSON
const fetchQuery = (operation, variables, cacheConfig, uploadables) => {
  return fetchOperation(operation, variables, cacheConfig).then(response => {
    return response.json()
  })
}

// Subscriptions uses the same `fetchOperation` function for initial subscription requests
const subscriptionHandler = createRelaySubscriptionHandler({pusher: pusherClient, fetchOperation: fetchOperation})
// Combine them into a `Network`
const network = Network.create(fetchQuery, subscriptionHandler)
```

Since `OperationStoreClient` is in the `fetchOperation` function, it will apply to all GraphQL operations.
