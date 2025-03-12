---
layout: guide
doc_stub: false
search: true
section: Schema
title: Definition
desc: Defining your schema
index: 1
---


A GraphQL system is called a _schema_. The schema contains all the types and fields in the system. The schema executes queries and publishes an {% internal_link "introspection system","/schema/introspection" %}.

Your GraphQL schema is a class that extends {{ "GraphQL::Schema" | api_doc }}, for example:

```ruby
class MyAppSchema < GraphQL::Schema
  max_complexity 400
  query Types::Query
  use GraphQL::Dataloader

  # Define hooks as class methods:
  def self.resolve_type(type, obj, ctx)
    # ...
  end

  def self.object_from_id(node_id, ctx)
    # ...
  end

  def self.id_from_object(object, type, ctx)
    # ...
  end
end
```

There are lots of schema configuration methods.

For defining GraphQL types, see the guides for those types: {% internal_link "object types", "/type_definitions/objects" %}, {% internal_link "interface types", "/type_definitions/interfaces" %}, {% internal_link "union types", "/type_definitions/unions" %},  {% internal_link "input object types", "/type_definitions/input_objects" %}, {% internal_link "enum types", "/type_definitions/enums" %}, and {% internal_link "scalar types", "/type_definitions/scalars" %}.

## Types in the Schema

- {{ "Schema.query" | api_doc }}, {{ "Schema.mutation" | api_doc }}, and {{ "Schema.subscription" | api_doc}} declare the [entry-point types](https://graphql.org/learn/schema/#the-query-and-mutation-types) of the schema.
- {{ "Schema.orphan_types" | api_doc }} declares object types which implement {% internal_link "Interfaces", "/type_definitions/interfaces" %} but aren't used as field return types in the schema. For more about this specific scenario, see {% internal_link "Orphan Types", "/type_definitions/interfaces#orphan-types" %}

### Lazy-loading types

In development, GraphQL-Ruby can defer loading your type definitions until they're needed. This requires some configuration to opt in:

- Add `use GraphQL::Schema::Visibility` to your schema. ({{ "GraphQL::Schema::Visibility" | api_doc }} supports lazy loading and will be the default in a future GraphQL-Ruby version. See {% internal_link "Migration Notes", "/authorization/visibility#migration-notes" %} if you have an existing visibility implementation.)
- Move your entry-point type definitions into a block, for example:

  ```diff
  - query Types::Query
  + query { Types::Query }
  ```

- Optionally, move field types into blocks, too:

  ```diff
  - field :posts, [Types::Post] # Loads `types/post.rb` immediately
  + field :posts do
  +   type([Types::Post]) # Loads `types/post.rb` when this field is used in a query
  + end
  ```

To enforce these patterns, you can enable two Rubocop rules that ship with GraphQL-Ruby:

- `GraphQL/RootTypesInBlock` will make sure that `query`, `mutation`, and `subscription` are all defined in a block.
- `GraphQL/FieldTypeInBlock` will make sure that non-built-in field return types are defined in blocks.

## Object Identification

Some GraphQL features use unique IDs to load objects:

- the `node(id:)` field looks up objects by ID (See {% internal_link "Object Identification", "/schema/object_identification" %} for more about Relay-style object identification.)
- any arguments with `loads:` configurations look up objects by ID
- the {% internal_link "ObjectCache", "/object_cache/overview" %} uses IDs in its caching scheme

To use these features, you must provide some methods for generating UUIDs and fetching objects with them:

{{ "Schema.object_from_id" | api_doc }} is called by GraphQL-Ruby to load objects directly from the database. It's usually used by the `node(id: ID!): Node` field (see {{ "GraphQL::Types::Relay::Node" | api_doc }}), Argument {% internal_link "loads:", "/mutations/mutation_classes#auto-loading-arguments" %}, or the {% internal_link "ObjectCache", "/object_cache/overview" %}. It receives a unique ID and must return the object for that ID, or `nil` if the object isn't found (or if it should be hidden from the current user).

{{ "Schema.id_from_object" | api_doc }} is used to implement `Node.id`. It should return a unique ID for the given object. This ID will later be sent to `object_from_id` to refetch the object.

Additionally, {{ "Schema.resolve_type" | api_doc }} is called by GraphQL-Ruby to get the runtime Object type for fields that return return {% internal_link "interface", "/type_definitions/interfaces" %} or {% internal_link "union", "/type_definitions/unions" %} types.

## Error Handling

- {{ "Schema.type_error" | api_doc }} handles type errors at runtime, read more in the {% internal_link "Type errors guide", "/errors/type_errors" %}.
- {{ "Schema.rescue_from" | api_doc }} defines error handlers for application errors. See the {% internal_link "error handling guide", "/errors/error_handling" %} for more.
- {{ "Schema.parse_error" | api_doc }} and {{ "Schema.query_stack_error" | api_doc }} provide hooks for reporting errors to your bug tracker.

## Default Limits

- {{ "Schema.max_depth" | api_doc }} and {{ "Schema.max_complexity" | api_doc }} apply some limits to incoming queries. See {% internal_link "Complexity and Depth", "/queries/complexity_and_depth" %} for more.
- {{ "Schema.default_max_page_size" | api_doc }} applies limits to {% internal_link "connection fields", "/pagination/overview" %}.
- {{ "Schema.validate_timeout" | api_doc }}, {{ "Schema.validate_max_errors" | api_doc }} and {{ "Schema.max_query_string_tokens" | api_doc }} all apply limits to query execution. See {% internal_link "Timeout", "/queries/timeout" %} for more.

## Introspection

- {{ "Schema.extra_types" | api_doc }} declares types which should be printed in the SDL and returned in introspection queries, but aren't otherwise used in the schema.
- {{ "Schema.introspection" | api_doc }} can attach a {% internal_link "custom introspection system", "/schema/introspection" %} to the schema.

## Authorization

- {{ "Schema.unauthorized_object" | api_doc }} and {{ "Schema.unauthorized_field" | api_doc }} are called when {% internal_link "authorization hooks", "/authorization/authorization" %} return `false` during query execution.

## Execution Configuration

- {{ "Schema.trace_with" | api_doc }} attaches tracer modules. See {% internal_link "Tracing", "/queries/tracing" %} for more.
- {{ "Schema.query_analyzer" | api_doc }} and {{ "Schema.multiplex_analyzer" }} accept processors for ahead-of-time query analysis, see {% internal_link "Analysis", "/queries/ast_analysis" %} for more.
- {{ "Schema.default_logger" | api_doc }} configures a logger for runtime. See {% internal_link "Logging", "/queries/logging" %}.
- {{ "Schema.context_class" | api_doc }} and {{ "Schema.query_class" | api_doc }} attach custom subclasses to your schema to use during execution.
- {{ "Schema.lazy_resolve" | api_doc }} registers classes with {% internal_link "lazy execution", "/schema/lazy_execution" %}.

## Plugins

- {{ "Schema.use" | api_doc }} adds plugins to your schema. For example, {{ "GraphQL::Dataloader" | api_doc }} and {{ "GraphQL::Schema::Visibility" | api_doc }} are installed this way.

## Production Considerations

- __Parser caching__: if your application parses GraphQL _files_ (queries or schema definition), it may benefit from enabling {{ "GraphQL::Parser::Cache" | api_doc }}.
- __Eager loading the library__: by default, GraphQL-Ruby autoloads its constants as-needed. In production, they should be eager loaded instead, using `GraphQL.eager_load!`.

  - Rails: enabled automatically. (ActiveSupport calls `.eager_load!`.)
  - Sinatra: add `configure(:production) { GraphQL.eager_load! }` to your application file.
  - Hanami: add `environment(:production) { GraphQL.eager_load! }` to your application file.
  - Other frameworks: call `GraphQL.eager_load!` when your application is booting in production mode.

  See {{"GraphQL::Autoload#eager_load!" | api_doc }} for more details.
