---
layout: guide
doc_stub: false
search: true
section: Subscriptions
title: Action Cable Implementation
desc: GraphQL subscriptions over ActionCable
index: 4
---

[ActionCable](https://guides.rubyonrails.org/action_cable_overview.html) is a great platform for delivering GraphQL subscriptions on Rails 5+. It handles message passing (via `broadcast`) and transport (via `transmit` over a websocket).

To get started, see examples in the API docs: {{ "GraphQL::Subscriptions::ActionCableSubscriptions" | api_doc }}.

See client usage for:

- {% internal_link "Apollo Client", "/javascript_client/apollo_subscriptions" %}
- {% internal_link "Relay Modern", "/javascript_client/relay_subscriptions" %}.
- {% internal_link "GraphiQL", "/javascript_client/graphiql_subscriptions" %}
