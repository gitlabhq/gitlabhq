---
layout: guide
doc_stub: false
search: true
section: JavaScript Client
title: urql Subscriptions
desc: GraphQL subscriptions with GraphQL-Ruby and urql
index: 4
---

GraphQL-Ruby currently supports using `urql` with the {% internal_link "ActionCable", "/subscriptions/action_cable_implementation" %} and {% internal_link "Pusher implementation", "/subscriptions/pusher_implementation" %}.

## Pusher

```js
import SubscriptionExchange from "graphql-ruby-client/subscriptions/SubscriptionExchange"
import Pusher from "pusher"
import { Client, defaultExchanges, subscriptionExchange } from 'urql'

const pusherClient = new Pusher("your-app-key", { cluster: "us2" })
const forwardToPusher = SubscriptionExchange.create({ pusher: pusherClient })

const client = new Client({
  url: '/graphql',
  exchanges: [
    ...defaultExchanges,
    subscriptionExchange({
      forwardSubscription: forwardToPusher
    }),
  ],
});
```

## ActionCable

```js
import { createConsumer } from "@rails/actioncable";
import SubscriptionExchange from "graphql-ruby-client/subscriptions/SubscriptionExchange"

const actionCable = createConsumer('ws://127.0.0.1:3000/cable');
const forwardToActionCable = SubscriptionExchange.create({ consumer: actionCable })

const client = new Client({
  url: '/graphql',
  exchanges: [
    ...defaultExchanges,
    subscriptionExchange({
      forwardSubscription: forwardToActionCable
    }),
  ],
});
```

Want to use `urql` with another subscription backend? Please {% open_an_issue "Using urql with ..." %}.
