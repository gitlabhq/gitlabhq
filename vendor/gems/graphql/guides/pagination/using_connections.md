---
layout: guide
doc_stub: false
search: true
section: Pagination
title: Using Connections
desc: Pagination with GraphQL-Ruby's built-in connections
index: 2
---

GraphQL-Ruby ships with a few implementations of the {% internal_link "connection pattern", "pagination/connection_concepts" %} that you can use out of the box. They support Ruby Arrays, Mongoid, Sequel, and ActiveRecord.

Additionally, connections allow you to limit the number of items returned with [`max_page_size`](#max-page-size) and set the default number of items returned with [`default_page_size`](#default-page-size).

## Make Connection Fields

Use `.connection_type` to generate a connection type for paginating over objects of a given type:

```ruby
field :items, Types::ItemType.connection_type, null: false
```

The generated return type will be called `ItemConnection`. Since it ends in `*Connection`, the `field(...)` will automatically be configured with `connection: true`. If the connection type's name doesn't end in `Connection`, you have to add that configuration yourself:

```ruby
# here's a custom type whose name doesn't end in "Connection", so `connection: true` is required:
field :items, Types::ItemConnectionPage, null: false, connection: true
```

The field will be given some arguments by default: `first`, `last`, `after`, and `before`.

### Opting out of default connection handling

To opt out of GraphQL-Ruby's default connection handling, add `connection: false` to the field definition:

```diff
- field :items, Types::ItemType.connection_type, null: false
+ field :items, Types::ItemType.connection_type, null: false, connection: false
```

Then, add any arguments you want (`first`, `last`, `after`, `before`) and make sure that your resolver returns an object that can fulfill the fields of the configured return type.

## Return Collections

With connection fields, you can return collection objects from fields or resolvers:

```ruby
def items
  object.items # => eg, returns an ActiveRecord Relation
end
```

The collection object (Array, Mongoid relation, Sequel dataset, ActiveRecord relation) will be automatically paginated with the provided arguments. Cursors will be generated based on the offset of nodes in the collection.

## Make Custom Connections

If you want to paginate something that _isn't_ supported out-of-the-box, you can implement your own pagination wrapper and hook it up to GraphQL-Ruby. Read more in {% internal_link "Custom Connections", "/pagination/custom_connections" %}.

## Special Cases

Sometimes, you have _one collection_ that needs special handling, unlike other instances of its class. For cases like this, you can manually apply the connection wrapper in the resolver. For example:

```ruby
def items
  # Get the ActiveRecord relation to paginate
  relation = object.items
  # Apply a custom wrapper
  Connections::ItemsConnection.new(relation)
end
```

This way, you can handle this _particular_ `relation` with custom code.

## Max Page Size

You can apply `max_page_size` to limit the number of items returned and queried from the database, regardless of what the client requests.

- __For the whole schema__, you can add it to your schema definition:

```ruby
class MyAppSchema < GraphQL::Schema
  default_max_page_size 50
end
```

  At runtime, that value will be applied to _every_ connection, unless an override is provided as described below.

- __For a given field__, add it to the field definition with a keyword:

```ruby
field :items, Item.connection_type, null: false,
  max_page_size: 25
```

- __Dynamically__, you can add `max_page_size:` when you apply custom connection wrappers:

```ruby
def items
  relation = object.items
  Connections::ItemsConnection.new(relation, max_page_size: 10)
end
```

To _remove_ a `max_page_size` setting, you can pass `nil`. That will allow unbounded collections to be returned to clients.

## Default Page Size

You can apply `default_page_size` to limit the number of items returned and queried from the database when no `first` or `last` is provided.

- __For the whole schema__, you can add it to your schema definition:

```ruby
class MyAppSchema < GraphQL::Schema
  default_page_size 50
end
```

  At runtime, that value will be applied to _every_ connection, unless an override is provided as described below.

- __For a given field__, add it to the field definition with a keyword:

```ruby
field :items, Item.connection_type, null: false,
  default_page_size: 25
```

- __Dynamically__, you can add `default_page_size:` when you apply custom connection wrappers:

```ruby
def items
  relation = object.items
  Connections::ItemsConnection.new(relation, default_page_size: 10)
end
```

If `max_page_size` is set and `default_page_size` is higher than it, the `default_page_size` will be clamped down to match `max_page_size`. If both `default_page_size` and `max_page_size` are set to `nil`, unbounded collections will be returned.
