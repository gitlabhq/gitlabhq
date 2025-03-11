---
layout: guide
doc_stub: false
search: true
section: Type Definitions
title: Interfaces
desc: Interfaces are lists of fields which objects may implement
index: 4
redirect_from:
  - /types/abstract_types/
---

Interfaces are lists of fields which may be implemented by object types.

An interface has fields, but it's never actually instantiated. Instead, objects may _implement_ interfaces, which makes them a _member_ of that interface. Also, fields may _return_ interface types. When this happens, the returned object may be any member of that interface.

For example, let's say a `Customer` (interface) may be either an `Individual` (object) or a `Company` (object). Here's the structure in the [GraphQL Schema Definition Language](https://graphql.org/learn/schema/#type-language) (SDL):

```graphql
interface Customer {
  name: String!
  outstandingBalance: Int!
}

type Company implements Customer {
  employees: [Individual!]!
  name: String!
  outstandingBalance: Int!
}

type Individual implements Customer {
  company: Company
  name: String!
  outstandingBalance: Int!
}
```

Notice that the `Customer` interface requires two fields, `name: String!` and `outstandingBalance: Int!`. Both `Company` and `Individual` implement those fields, so they can implement `Customer`. Their implementation of `Customer` is made explicit by `implements Customer` in their definition.

When querying, you can get the fields on an interface:

```graphql
{
  customers(first: 5) {
    name
    outstandingBalance
  }
}
```

Whether the objects are `Company` or `Individual`, it doesn't matter -- you still get their `name` and `outstandingBalance`. If you want some object-specific fields, you can query them with an _inline fragment_, for example:

```graphql
{
  customers(first: 5) {
    name
    ... on Individual {
      company { name }
    }
  }
}
```

This means, "if the customer is an `Individual`, also get the customer's company name".

Interfaces are a good choice whenever a set of objects are used interchangeably, and they have several significant fields in common. When they don't have fields in common, use a {% internal_link "Union", "/type_definitions/unions" %} instead.

## Defining Interface Types

Interfaces are Ruby modules which include {{ "GraphQL::Schema::Interface" | api_doc }}. First, make a base module:

```ruby
module Types::BaseInterface
  include GraphQL::Schema::Interface
end
```

Then, include that into each interface:

```ruby
module Types::RetailItem
  include Types::BaseInterface
  comment "TODO comment in the RetailItem interface"
  description "Something that can be bought"
  field :price, Types::Price, "How much this item costs", null: false

  def price
    # Optional: provide a special implementation of `price` here
  end


  # Optional, see below
  definition_methods do
    # Optional: if this method is defined, it overrides `Schema.resolve_type`
    def resolve_type(object, context)
      # ...
    end
  end
end
```

Interface classes are never instantiated. At runtime, only their `.resolve_type` methods are called (if they're defined).

### Implementing Interfaces

To define object types that implement this interface use the `implements` method:

```ruby
class Types::Car < Types::BaseObject
  implements Types::RetailItem

  # ... additional fields
end

class Types::Purse < Types::BaseObject
  implements Types::RetailItem

  # ... additional fields
end
```

Those object types will _inherit_ field definitions from those interfaces.

If you add an object type which implements an interface, but that object type doesn't appear in your schema as a field return type, a union member, or a root type, then you need to add that object to the interfaces's `orphan_types`.

### Implementing Fields

Interfaces may provide field implementations along with the signatures. For example:

```ruby
field :price, Types::Price, "How much this item costs", null: false

# Implement this field to return a `::Price` object
def price
  ::Price.from_cents(@object.price_in_cents)
end
```

This method will be called by objects who implement the interface. To override this implementation,
object classes can override the `#price` method.

Read more in the {% internal_link "Fields guide", "/fields/introduction" %}.

### Definition Methods

You can use `definition_methods do ... end` to add helper methods to interface modules. By adding methods to `definition_methods`:

- Those methods will be available as class methods in the interface itself
- These class methods will _also_ be added to interfaces that `include` this interface.

This way, class methods are inherited when interfaces `include` other interfaces. (`definition_methods` is like `ActiveSupport::Concern`'s `class_methods` in this regard, but it has a different name to avoid naming conflicts).

For example, you can add definition helpers to your base interface, then use them in concrete interfaces later:

```ruby
# First, add a helper method to `BaseInterface`'s definition methods
module Types::BaseInterface
  include GraphQL::Schema::Interface

  definition_methods do
    # Use this to add a price field + default implementation
    def price_field
      field(:price, ::Types::Price, null: false)
      define_method(:price) do
        ::Price.from_cents(@object.price_in_cents)
      end
    end
  end
end

# Then call it later
module Types::ForSale
  include Types::BaseInterface
  # This calls `price_field` from definition methods
  price_field
end
```

The type definition DSL uses this mechanism, too, so you can override those methods here also.

Note: Under the hood, `definition_methods` causes a module to be `extend`ed by the interface. Any calls to `extend` or `implement` may override methods from `definition_methods`.

### Resolve Type

When a field's return type is an interface, GraphQL has to figure out what _specific_ object type to use for the return value. In the example above, each `customer` must be categorized as an `Individual` or `Company`. You can do this by:

- Providing a top-level `Schema.resolve_type` method; _OR_
- Providing an interface-level `.resolve_type` method in `definition_methods`.

This method will be called whenever an object must be disambiguated. For example:

```ruby
module Types::RetailItem
  include Types::BaseInterface
  definition_methods do
    # Determine what object type to use for `object`
    def resolve_type(object, context)
      if object.is_a?(::Car) || object.is_a?(::Truck)
        Types::Car
      elsif object.is_a?(::Purse)
        Types::Purse
      else
        raise "Unexpected RetailItem: #{object.inspect}"
      end
    end
  end
end
```

You can also optionally return a "resolved" object in addition the resolved type by returning an array:

```ruby
module Types::Claim
  include Types::BaseInterface
  definition_methods do
    def resolve_type(object, context)
      type = case object.value
      when Success
        Types::Approved
      when Error
        Types::Rejected
      else
        raise "Unexpected Claim: #{object.inspect}"
      end

      [type, object.value]
    end
  end
end
```

The returned array must be a tuple of `[Type, object]`.
This is useful for interface or union types which are backed by a domain object which should be unwrapped before resolving the next field.

## Orphan Types

If you add an object type which implements an interface, but that object type doesn't properly appear in your schema, then you need to add that object to the interfaces's `orphan_types`, for example:

```ruby
module Types::RetailItem
  include Types::BaseInterface
  # ...
  orphan_types Types::Car
end
```

Alternatively you can add the object types to the schema's `orphan_types`:

```ruby
class MySchema < GraphQL::Schema
  orphan_types Types::Car
end
```

This is required because a schema finds it types by traversing its fields, starting with `query`, `mutation` and `subscription`. If an object is _never_ the return type of a field, but only connected via an interface, then it must be explicitly connected to the schema via `orphan_types`. For example, given this schema:

```graphql
type Query {
  node(id: ID!): Node
}

interface Node {
  id: ID!
}

type Comment implements Node {
  id: ID!
}
```

`Comment` must be added via `orphan_types` since it's never used as the return type of a field. (Only `Node` and `ID` are used as return types.)
