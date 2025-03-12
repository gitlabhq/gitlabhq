---
layout: guide
doc_stub: false
search: true
section: Schema
title: Parsing GraphQL Schema Definition Language into a Ruby Schema
desc: Defining a schema from a string or .graphql file
index: 7
---

GraphQL-Ruby includes a way to build a runable schema from the GraphQL Schema Definition Language (SDL). {{ "GraphQL::Schema.from_definition" | api_doc }} returns a schema class based on a filename or string containing GraphQL SDL. For example:

```ruby
# From a file:
MySchema = GraphQL::Schema.from_definition("path/to/schema.graphql")
# Or, from a string:
MySchema = GraphQL::Schema.from_definition(<<~GRAPHQL)
  type Query {
    # ...
  }
  # ...
GRAPHQL
```

Definitions from the SDL are converted into Ruby classes, similar to those defined in plain Ruby code.

## Execution

You can provide execution behaviors to a generated schema as `default_resolve:`, which accepts two kinds of values:

- __Implementation Object__: an object that implements several methods used at runtime
- __Implementation Hash__: keys and nested hashes provide procs for execution

### Implementation Object

By providing an object that implements several runtime methods, you can define the execution behaviors of a schema loaded from SDL:

```ruby
class SchemaImplementation
  # see below for methods
end

# Pass the object as `default_resolve:`
MySchema = GraphQL::Schema.from_definition(
  "path/to/schema.graphql",
  default_resolve: SchemaImplementation.new
)
```

The `default_resolve:` object may implement:

- `#call(type, field, obj, args, ctx)` for resolving fields
- `#resolve_type(abstract_type, obj, ctx)` for resolving `obj` as one of `abstract_type`'s possible object types
- `#coerce_input(type, value, ctx)` for coercing scalar input
- `#coerce_result(type, value, ctx)` for coercing scalar return values

### Implementation Hash

Alternatively, you can provide a Hash containing callable behaviors, for example:

```ruby
schema_implementation = {
  # ... see below for hash structure
}

# Pass the hash as `default_resolve:`
MySchema = GraphQL::Schema.from_definition(
  "path/to/schema.graphql",
  default_resolve: schema_implementation
)
```

The hash may contain:

- A key for each object type name, containing a sub-hash of `{ field_name => ->(obj, args, ctx) { ... } }` for resolving object fields
- A key for each scalar type name, containing a sub-hash with keys `"coerce_result"` and `"coerce_input"`, each pointing to a `->(value, ctx) { ... }` for handling scalar values at runtime
- A `"resolve_type"` key pointing to a `->(abstract_type, object, ctx) { ... }` callable, used for resolving `object` to one of `abstract_type`'s possible types

## Plugins

{{ "GraphQL::Schema.from_definition" | api_doc }} accepts a `using:` argument, which may be given as a map of `plugin => args` pairs. For example:

```ruby
MySchema = GraphQL::Schema.from_definition("path/to/schema.graphql", using: {
  GraphQL::Pro::PusherSubscriptions => { redis: $redis },
  GraphQL::Pro::OperationStore => nil, # no options here
})
```

## Directives

Although GraphQL-Ruby doesn't have special handling for directives in the SDL, you can build custom behavior in your own app. If part of the schema had a directive, you can access it using `.ast_node.directives`. For example:

```ruby
schema = GraphQL::Schema.from_definition <<-GRAPHQL
type Query @flagged {
  secret: Boolean @privacy(secret: true)
}
GRAPHQL

pp schema.query.ast_node.directives.map(&:to_query_string)
# => ["@flagged"]
pp schema.get_field("Query", "secret").ast_node.directives.map(&:to_query_string)
# => ["@privacy(secret: true)"]
```

See {{ "GraphQL::Language::Nodes::Directive" | api_doc }} for available methods.
