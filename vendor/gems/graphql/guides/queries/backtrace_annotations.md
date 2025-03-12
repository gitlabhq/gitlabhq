---
title: Backtrace Annotations
layout: guide
doc_stub: false
search: true
section: Queries
desc: Use the GraphQL backtrace for debugging
index: 12
experimental: true
---

`context` objects have a `backtrace` which shows its GraphQL context. You can print the backtrace during query execution:

```ruby
puts context.backtrace
# Loc  | Field                         | Object       | Arguments             | Result
# 3:13 | User.login                    | #<User id=1> | {"message"=>"Boom"}   | #<RuntimeError: This is broken: Boom>
# 2:11 | Query.user                    | nil          | {"login"=>"rmosolgo"} | {}
# 1:9  | query                         | nil          | {"msg"=>"Boom"}       |
```

The backtrace contains some execution data:

- `Loc` is the `line:column` of the field in the query string
- `Field` is the `TypeName.fieldName` of the fields in the backtrace
- `Object` is the `obj` for query resolution (used for resolving the given field), equivalent to `obj.inspect`
- `Arguments` are the GraphQL arguments for field resolution (including any default values and variable values)
- `Result` is the GraphQL-ready result which is being constructed (it may be incomplete if the query is still in-progress)

## Wrapping Errors

You can wrap unhandled errors with a GraphQL error with `GraphQL::Backtrace`.

To enable this feature for a query, add `backtrace: true` to your `context`, for example:

```ruby
# Wrap this query with backtrace annotation
MySchema.execute(query_string, context: { backtrace: true })
```

Or, to _always_ wrap backtraces, add it to your schema definition with `use`, for example:

```ruby
class MySchema < GraphQL::Schema
  # Always wrap backtraces with GraphQL annotation
  use GraphQL::Backtrace
end
```

Now, any unhandled errors will be wrapped by `GraphQL::Backtrace::TracedError`, which prints out the GraphQL backtrace, too. For example:

```
Unhandled error during GraphQL execution:

  This is broken: Boom
    /Users/rmosolgo/code/graphql-ruby/spec/graphql/backtrace_spec.rb:27:in `block (3 levels) in <top (required)>'
    /Users/rmosolgo/code/graphql-ruby/lib/graphql/schema/build_from_definition/resolve_map.rb:57:in `call'
    /Users/rmosolgo/code/graphql-ruby/lib/graphql/schema/build_from_definition.rb:171:in `block in build_object_type'
    /Users/rmosolgo/code/graphql-ruby/lib/graphql/schema/build_from_definition.rb:280:in `block (2 levels) in build_fields'
    /Users/rmosolgo/code/graphql-ruby/lib/graphql/field.rb:228:in `resolve'
    /Users/rmosolgo/code/graphql-ruby/lib/graphql/execution/execute.rb:253:in `call'
    /Users/rmosolgo/code/graphql-ruby/lib/graphql/schema/middleware_chain.rb:45:in `invoke_core'
    /Users/rmosolgo/code/graphql-ruby/lib/graphql/schema/middleware_chain.rb:38:in `invoke'
    /Users/rmosolgo/code/graphql-ruby/lib/graphql/execution/execute.rb:107:in `resolve_field'
    /Users/rmosolgo/code/graphql-ruby/lib/graphql/execution/execute.rb:71:in `block (2 levels) in resolve_selection'
    ... and 65 more lines

Use #cause to access the original exception (including #cause.backtrace).

GraphQL Backtrace:
Loc  | Field                         | Object     | Arguments           | Result
3:13 | Thing.raiseField as boomError | :something | {"message"=>"Boom"} | #<RuntimeError: This is broken: Boom>
2:11 | Query.field1                  | "Root"     | {}                  | {}
1:9  | query                         | "Root"     | {"msg"=>"Boom"}     | {}
```
