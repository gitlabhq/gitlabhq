---
layout: guide
search: true
section: Dataloader
title: Dataloader
desc: The Dataloader orchestrates Fibers and Sources
index: 2
---

{{ "GraphQL::Dataloader" | api_doc }} instances are created for each query (or multiplex) and they:

- Cache {% internal_link "Source", "/dataloader/sources" %} instances for the duration of GraphQL execution
- Run pending Fibers to resolve data requirements and continue GraphQL execution

During a query, you can access the dataloader instance with:

- {{ "GraphQL::Query::Context#dataloader" | api_doc }} (`context.dataloader`, anywhere that query context is available)
- {{ "GraphQL::Schema::Object#dataloader" | api_doc }} (`dataloader` inside a resolver method)
- {{ "GraphQL::Schema::Resolver#dataloader" | api_doc }} (`dataloader` inside `def resolve` of a Resolver, Mutation, or Subscription class.)

## Fiber Lifecycle Hooks

Under the hood, `Dataloader` creates Fibers as-needed and uses them to run GraphQL and load data from `Source` classes. You can hook into these Fibers through several lifecycle hooks. To implement these hooks, create a custom subclass and provide new implementation for these methods:

```ruby
class MyDataloader < GraphQL::Dataloader # or GraphQL::Dataloader::AsyncDataloader
  # ...
end
```

Then, use your customized dataloader instead of the built-in one:

```diff
  class MySchema < GraphQL::Schema
-   use GraphQL::Dataloader
+   use MyDataloader
  end
```

- __{{ "GraphQL::Dataloader#get_fiber_variables" | api_doc }}__ is called before creating a Fiber. By default, it returns a hash containing the parent Fiber's variables (from `Thread.current[...]`). You can add to this hash in your own implementation of this method.
- __{{ "GraphQL::Dataloader#set_fiber_variables" | api_doc }}__ is called inside the new Fiber. It's passed the hash returned from `get_fiber_variables`. You can use this method to initialize "global" state inside the new Fiber.
- __{{ "GraphQL::Dataloader#cleanup_fiber" | api_doc }}__ is called just before a Dataloader Fiber exits. You can use this methods to teardown any state that you prepared in `set_fiber_variables`.
