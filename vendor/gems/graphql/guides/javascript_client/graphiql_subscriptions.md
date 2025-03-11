---
layout: guide
doc_stub: false
search: true
section: JavaScript Client
title: GraphiQL Subscriptions
desc: Testing GraphQL subscriptions in the GraphiQL IDE
index: 5
---

After setting up your server, you can integrate subscriptions into [GraphiQL](https://github.com/graphql/graphiql/tree/main/packages/graphiql#readme), the in-browser GraphQL IDE.

## Adding GraphiQL to your app

To get started, make a page for rendering GraphiQL, for example:

```html
<!-- views/graphiqls/show.html -->
<div id="root" style="height: 100vh;"></div>
```

Then, install GraphiQL (eg, `yarn add graphiql`) and add JavaScript code to import GraphiQL and render it on your page:

```js
import { GraphiQL } from 'graphiql'
import React from 'react'
import { createRoot } from 'react-dom/client'
import 'graphiql/graphiql.css'
import { createGraphiQLFetcher } from '@graphiql/toolkit'

const fetcher = createGraphiQLFetcher({ url: '/graphql' })
const root = createRoot(document.getElementById('root'))
root.render(<GraphiQL fetcher={fetcher}/>)
```

After that, you should be able to load the page in your app and see the GraphiQL editor.

## Ably

To integrate {% internal_link "Ably subscriptions", "subscriptions/ably_implementation" %}, use `createAblyFetcher`,  for example:

```js
import Ably from "ably"
import createAblyFetcher from 'graphql-ruby-client/subscriptions/createAblyFetcher'

// Initialize a client
// the key must have "subscribe" and "presence" permissions
const ably = new Ably.Realtime({ key: "your.application.key" })

// Initialize a new fetcher and pass it to GraphiQL below
var fetcher = createAblyFetcher({ ably: ably, url: "/graphql" })
const root = createRoot(document.getElementById('root'))
root.render(<GraphiQL fetcher={fetcher} />)
```

Under the hood, it will use `window.fetch` to send GraphQL operations to the server, then listen for `X-Subscription-ID` headers in responses. To customize its HTTP requests, you can pass a `fetchOptions:` object or a custom `fetch:` function to `createAblyFetcher({ ... })`.

## Pusher

To integrate {% internal_link "Pusher subscriptions", "subscriptions/pusher_implementation" %}, use `createPusherFetcher`,  for example:

```js
import Pusher from "pusher-js"
import createPusherFetcher from 'graphql-ruby-client/subscriptions/createPusherFetcher'

// Initialize a client
const pusher = new Pusher("your-app-key", { cluster: "your-cluster" })

// Initialize a new fetcher and pass it to GraphiQL below
var fetcher = createPusherFetcher({ pusher: pusher, url: "/graphql" })
const root = createRoot(document.getElementById('root'))
root.render(<GraphiQL fetcher={fetcher} />)
```

Under the hood, it will use `window.fetch` to send GraphQL operations to the server, then listen for `X-Subscription-ID` headers in responses. To customize its HTTP requests, you can pass a `fetchOptions:` object or a custom `fetch:` function to `createPusherFetcher({ ... })`.

## ActionCable

To integrate {% internal_link "ActionCable subscriptions", "subscriptions/action_cable_implementation" %}, use `createActionCableFetcher`,  for example:

```js
import { createConsumer } from "@rails/actioncable"
import createActionCableFetcher from 'graphql-ruby-client/subscriptions/createActionCableFetcher';

// Initialize a client
const actionCable = createConsumer()

// Initialize a new fetcher and pass it to GraphiQL below
var fetcher = createActionCableFetcher({ consumer: actionCable, url: "/graphql" })
const root = createRoot(document.getElementById('root'))
root.render(<GraphiQL fetcher={fetcher} />)
```

Under the hood, it will split traffic: it will send `subscription { ... }` operations via ActionCable and send queries and mutations via HTTP `POST` using `window.fetch`. To customize its HTTP requests, you can pass a `fetchOptions:` object or a custom `fetch:` function to `createActionCableFetcher({ ... })`.
