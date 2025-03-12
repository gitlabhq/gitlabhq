---
layout: guide
doc_stub: false
search: true
title: Object Identification
section: Schema
desc: Working with unique global IDs
index: 8
---

GraphQL-Ruby ships with some helpers to implement [Relay-style object identification](https://relay.dev/graphql/objectidentification.htm).

## Schema methods

See {% internal_link "the Schema definition guide", "/schema/definition#object-identification" %} for required top-level hooks.

## Node interface

One requirement for Relay's object management is implementing the `"Node"` interface.

To implement the node interface, add {{ "GraphQL::Types::Relay::Node" | api_doc }} to your definition:

```ruby
class Types::PostType < GraphQL::Schema::Object
  # Implement the "Node" interface for Relay
  implements GraphQL::Types::Relay::Node
  # ...
end
```

To tell GraphQL how to resolve members of the `Node` interface, you must also define `Schema.resolve_type`:

```ruby
class MySchema < GraphQL::Schema
  # You'll also need to define `resolve_type` for
  # telling the schema what type Relay `Node` objects are
  def self.resolve_type(type, obj, ctx)
    case obj
    when Post
      Types::PostType
    when Comment
      Types::CommentType
    else
      raise("Unexpected object: #{obj}")
    end
  end
end
```

## UUID fields

Nodes must have a field named `"id"` which returns a globally unique ID.

To add a UUID field named `"id"`, implement the {{ "GraphQL::Types::Relay::Node" | api_doc }} interface::

```ruby
class Types::PostType < GraphQL::Schema::Object
  implements GraphQL::Types::Relay::Node
end
```

This field will call the previously-defined `id_from_object` class method.

## `node` field (find-by-UUID)

You should also provide a root-level `node` field so that Relay can refetch objects from your schema. You can attach it like this:

```ruby
class Types::QueryType < GraphQL::Schema::Object
  # Used by Relay to lookup objects by UUID:
  # Add `node(id: ID!)
  include GraphQL::Types::Relay::HasNodeField
  # ...
end
```

## `nodes` field

You can also provide a root-level `nodes` field so that Relay can refetch objects by IDs:

```ruby
class Types::QueryType < GraphQL::Schema::Object
  # Fetches a list of objects given a list of IDs
  # Add `nodes(ids: [ID!]!)`
  include GraphQL::Types::Relay::HasNodesField
  # ...
end
```
