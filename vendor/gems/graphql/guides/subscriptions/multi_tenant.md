---
layout: guide
doc_stub: false
search: true
section: Subscriptions
title: Multi-Tenant
desc: Switching tenants in GraphQL Subscription execution
index: 8
---

In a multi-tenant system, data from many different accounts is stored on the same server. (An account might be an organization, a customer, a namespace, a domain, etc -- these are all _tenants_.) Gems like [Apartment](https://github.com/influitive/apartment) assist with this arrangement, but it can also be implemented in the application. Here are a few considerations for this architecture when using GraphQL subscriptions.

## Add Tenant to `context`

All the approaches below will use `context[:tenant]` to identify the tenant during GraphQL execution, so make sure to assign it before executing a query:

```ruby
context = {
  viewer: current_user,
  tenant: current_user.tenant,
  # ...
}

MySchema.execute(query_str, context: context, ...)
```

## Tenant-based `subscription_scope`

When subscriptions are delivered, {% internal_link "`subscription_scope`",  "subscriptions/subscription_classes#scope" %} is one element used to route data to the right subscriber. In short, it's the _implicit_ identifier for the receiver. In a multi-tenant architecture, `subscription_scope` should reference the context key that names the tenant, for example:

```ruby
class BudgetWasApproved < GraphQL::Schema::Subscription
  subscription_scope :tenant # This would work with `context[:tenant] => "acme-corp"`
  # ...
end

# Include the scope when `.trigger`ing:
BudgetSchema.subscriptions.trigger(:budget_was_approved, {}, { ... }, scope: "acme-corp")
```


Alternatively, `subscription_scope` might name something that _belongs_ to the tenant:

```ruby
class BudgetWasApproved < GraphQL::Schema::Subscription
  subscription_scope :project_id # This would work with `context[:project_id] = 1234`
end

# Include the scope when `.trigger`ing:
BudgetSchema.subscriptions.trigger(:budget_was_approved, {}, { ... }, scope: 1234)
```

As long as `project_id` is unique among _all_ tenants, that would work fine too. But _some_ scope is required so that subscriptions can be disambiguated between tenants.

## Choosing a tenant for execution

There are a few places where subscriptions might need to load data:

- When building the payload for the subscription (fetching data to prepare the result)
- `ActionCableSubscriptions`: when deserializing the JSON string broadcasted by `ActionCable`
- `PusherSubscriptions` and `AblySubscriptions`: when deserializing query context

Each of these operations will need to select the right tenant in order to load data properly.

For __building the payload__, use a {% internal_link "Trace module", "queries/tracing" %}:

```ruby
module TenantSelectionTrace
  def execute_multiplex(multiplex:) # this is the top-level, umbrella event
    context = data[:multiplex].queries.first.context # This assumes that all queries in a multiplex have the same tenant
    MultiTenancy.select_tenant(context[:tenant]) do
      # ^^ your multi-tenancy implementation here
      super # Call through to the rest of execution
    end
  end
end

# ...
class MySchema < GraphQL::Schema
  trace_with(TenantSelectionTrace)
end
```

The tracer above will use `context[:tenant]` to select a tenant for the duration of execution for _all_ queries, mutations, and subscriptions.

For __deserializing ActionCable messages__, provide a `serializer:` object that implements `.dump(obj)` and `.load(string, context)`:

```ruby
class MultiTenantSerializer
  def self.dump(obj)
    GraphQL::Subscriptions::Serialize.dump(obj)
  end

  def self.load(string, context)
    MultiTenancy.select_tenant(context[:tenant]) do
      GraphQL::Subscriptions::Serialize.load(string)
    end
  end
end

# ...
class MySchema < GraphQL::Schema
  # ...
  use GraphQL::Subscriptions::ActionCableSubscriptions, serializer: MultiTenantSerializer
end
```

The implementation above will use the built-in serialization algorithms, but it will do so _in the context of_ the selected tenant.

For __loading query context in Pusher and Ably__, add tenant selection to your `load_context` method, if required:

```ruby
class CustomSubscriptions < GraphQL::Pro::PusherSubscriptions # or `GraphQL::Pro::AblySubscriptions`
  def dump_context(ctx)
    JSON.dump(ctx.to_h)
  end

  def load_context(ctx_string)
    ctx_data = JSON.parse(ctx_string)
    MultiTenancy.select_tenant(ctx_data["tenant"]) do
      # Build a symbol-keyed hash, loading objects from the database if necessary
      # to use a `context: ...`
    end
  end
end
```

With that approach, the selected tenant will be active when building the context hash, in case any objects need to be loaded from the database.
