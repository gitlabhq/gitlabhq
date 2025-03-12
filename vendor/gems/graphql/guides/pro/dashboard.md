---
layout: guide
doc_stub: false
search: true
section: GraphQL Pro
title: Dashboard
desc: Installing GraphQL-Pro's Dashboard
index: 4
pro: true
---


[GraphQL-Pro](https://graphql.pro) includes a web dashboard for monitoring {% internal_link "Operation Store", "/operation_store/overview" %} and {% internal_link "subscriptions", "/subscriptions/pusher_implementation" %}.

<!-- TODO image -->

## Installation

To hook up the Dashboard, add it to `routes.rb`

```ruby
# config/routes.rb

# Include GraphQL::Pro's routing extensions:
using GraphQL::Pro::Routes

Rails.application.routes.draw do
  # ...
  # Add the GraphQL::Pro Dashboard
  # TODO: authorize, see below
  mount MySchema.dashboard, at: "/graphql/dashboard"
end
```

With this configuration, it will be available at `/graphql/dashboard`.

The dashboard is a Rack app, so you can mount it in Sinatra or any other Rack app.

#### Lazy-loading the schema

Alternatively, you can set up the dashboard to load the schema during the first request. To do that, initialize `GraphQL::Pro::Routes::Lazy` with a string that gives the fully-qualified name of your schema class, for example:

```ruby
Rails.application.routes.draw do
  # ...
  # Add the GraphQL::Pro Dashboard
  # TODO: authorize, see below
  lazy_routes = GraphQL::Pro::Routes::Lazy.new("MySchema")
  mount lazy_routes.dashboard, at: "/graphql/dashboard"
end
```

With this setup, `MySchema` will be loaded when the dashboard serves its first request. This can speed up your application's boot in development since it doesn't load the whole GraphQL schema when building the routes.

## Authorizing the Dashboard

You should only allow admin users to see `/graphql/dashboard` because it allows viewers to delete stored operations.

### Rails Routing Constraints

Use [Rails routing constraints](https://api.rubyonrails.org/v5.1/classes/ActionDispatch/Routing/Mapper/Scoping.html#method-i-constraints) to restrict access to authorized users, for example:

```ruby
# Check the secure session for a staff flag:
STAFF_ONLY = ->(request) { request.session["staff"] == true }
# Only serve the GraphQL Dashboard to staff users:
constraints(STAFF_ONLY) do
  mount MySchema.dashboard, at: "/graphql/dashboard"
end
```

### Rack Basic Authentication

Insert the `Rack::Auth::Basic` middleware, before the web view. This prompts for a username and password when visiting the dashboard.

```ruby
graphql_dashboard = Rack::Builder.new do
  use(Rack::Auth::Basic) do |username, password|
    username == ENV.fetch("GRAPHQL_USERNAME") && password == ENV.fetch("GRAPHQL_PASSWORD")
  end

  run MySchema.dashboard
end
mount graphql_dashboard, at: "/graphql/dashboard"
```
