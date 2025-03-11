---
layout: guide
doc_stub: false
search: true
section: Mutations
title: Mutation Root
desc: The Mutation object is the entry point for mutation operations.
index: 0
---

GraphQL mutations all begin with the `mutation` keyword:

```graphql
mutation($accountNumber: ID!, $newBalance: Int!) {
# ^^^^ here
  setAccountBalance(accountNumber: $accountNumber, newBalance: $newBalance) {
    # ...
  }
}
```

Operations that begin with `mutation` get special treatment by the GraphQL runtime: root fields are guaranteed
to be executed sequentially. This way, the effect of a series of mutations is predictable.

Mutations are executed by a specific GraphQL object, `Mutation`. This object is defined like any other GraphQL object:

```ruby
class Types::Mutation < Types::BaseObject
  # ...
end
```

Then, it must be attached to your schema with the `mutation(...)` configuration:

```ruby
class Schema < GraphQL::Schema
  # ...
  mutation(Types::Mutation)
end
```

Now, whenever an incoming request uses the `mutation` keyword, it will go to `Mutation`.

See {% internal_link "Mutation Classes", "/mutations/mutation_classes" %} for some helpers to define mutation fields.
