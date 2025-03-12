---
layout: guide
doc_stub: false
search: true
section: Errors
title: Error Handling
desc: Rescuing application errors from field resolvers
index: 3
---

You can configure your schema to rescue application errors during field resolution. Errors during batch loading will also be rescued.

Thanks to [`@exAspArk`](https://github.com/exaspark) for the [`graphql-errors`](https://github.com/exAspArk/graphql-errors) gem which inspired this behavior and [`@thiago-sydow`](https://github.com/thiago-sydow) who [suggested](https://github.com/rmosolgo/graphql-ruby/issues/2139#issuecomment-524913594) an implementation like this.

## Add error handlers

Handlers are added with `rescue_from` configurations in the schema:

```ruby
class MySchema < GraphQL::Schema
  # ...

  rescue_from(ActiveRecord::RecordNotFound) do |err, obj, args, ctx, field|
    # Raise a graphql-friendly error with a custom message
    raise GraphQL::ExecutionError, "#{field.type.unwrap.graphql_name} not found"
  end

  rescue_from(SearchIndex::UnavailableError) do |err, obj, args, ctx, field|
    # Log the error
    Bugsnag.notify(err)
    # replace it with nil
    nil
  end
end
```

The handler is called with several arguments:

- __`err`__ is the error that was raised during field execution, then rescued
- __`obj`__ is the object which was having a field resolved against it
- __`args`__ is the Hash of arguments passed to the resolver
- __`ctx`__ is the query context
- __`field`__ is the {{ "GraphQL::Schema::Field" | api_doc }} instance for the field where the error was rescued

Inside the handler, you can:

- Raise a GraphQL-friendly {{ "GraphQL::ExecutionError" | api_doc }} to return to the user
- Re-raise the given `err` to crash the query and halt execution. (The error will propagate to your application, eg, the controller.)
- Report some metrics from the error, if applicable
- Return a new value to be used for the error case (if not raising another error)
