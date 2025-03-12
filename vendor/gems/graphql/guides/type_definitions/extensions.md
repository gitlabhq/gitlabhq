---
layout: guide
doc_stub: false
search: true
section: Type Definitions
title: Extending the GraphQL-Ruby Type Definition System
desc: Adding metadata and custom helpers to the DSL
index: 8
redirect_from:
  - /schema/extending_the_dsl/
---

While integrating GraphQL into your app, you can customize the definition DSL. For example, you might:

- Assign "area of responsibility" to different types and fields
- DRY up shared logic between types and fields
- Attach metadata for use during authorization

This guide describes various options for extending the class-based definition API. Keep in mind that these approaches may change as the API matures. If you're having trouble, consider opening an issue on GitHub to get help.

**Note**: This document describes best practice with GraphQL-Ruby 1.10+. For customizing schemas on older versions, use GitHub to browse older versions of this page.

## Customization Overview

In general, the schema definition process goes like this:

- The application defines lots of classes for the GraphQL types
- Starting from root types (`query`, `mutation`, and `subscription`) and any defined `orphan_types`, the schema discovers all types, fields, arguments, enum values, and directives in the schema
- Non-type objects (fields, arguments, enum values) are initialized when they're attached to the classes or instances they belong to.

## Customizing type definitions

In your custom classes, you can add class-level instance variables that hold configuration. For example:

```ruby
class Types::BaseObject < GraphQL::Schema::Object
  # Call this method in an Object class to get or set the permission level:
  def self.required_permission(permission_level = nil)
    if permission_level.nil?
      # return the configured value
      @required_permission
    else
      @required_permission = permission_level
    end
  end
end

# Then, in concrete classes
class Dossier < BaseObject
  # The Dossier object type will have `.metadata[:required_permission] # => :admin`
  required_permission :admin
end

# Now, the type responds to that method:
Dossier.required_permission
# => :admin
```

Now, any runtime code which calls `type.required_permission` will get the configured value.

### Customizing fields

Fields are generated in a different way. Instead of using classes, they are generated with instances of `GraphQL::Schema::Field` (or a subclass). In short, the definition process works like this:

```ruby
# This is what happens under the hood, roughly:
# In an object class:
field :name, String, null: false
# ...
# Leads to:
field_config = GraphQL::Schema::Field.new(name: :name, type: String, null: false)
```

So, you can customize this process by:

- creating a custom class which extends `GraphQL::Schema::Field`
- overriding `#initialize` on that class (instance methods)
- registering that class as the `field_class` on Objects and Interfaces which should use the customized field.

For example, you can create a custom class which accepts a new parameter to `initialize`:

```ruby
class Types::BaseField < GraphQL::Schema::Field
  # Override #initialize to take a new argument:
  def initialize(*args, required_permission: nil, **kwargs, &block)
    @required_permission = required_permission
    # Pass on the default args:
    super(*args, **kwargs, &block)
  end

  attr_reader :required_permission
end
```

Then, pass the field class as `field_class(...)` wherever it should be used:

```ruby
class Types::BaseObject < GraphQL::Schema::Object
  # Use this class for defining fields
  field_class BaseField
end

# And....
class Types::BaseInterface < GraphQL::Schema::Interface
  field_class BaseField
end

class Mutations::BaseMutation < GraphQL::Schema::RelayClassicMutation
  field_class BaseField
end
```

Now, `BaseField.new(*args, &block)` will be used to create `GraphQL::Schema::Field`s on those types. At runtime `field.required_permission` will return the configured value.

### Customizing Connections

Connections may be customized in a similar way to Fields.

- Create a new class extending 'GraphQL::Types::Relay::BaseConnection'
- Assign it to your object/interface type with `connection_type_class(MyCustomConnection)`

For example, you can create a custom connection:

```ruby
class Types::MyCustomConnection < GraphQL::Types::Relay::BaseConnection
  # BaseConnection has these nullable configurations
  # and the nodes field by default, but you can change
  # these options if you want
  edges_nullable(true)
  edge_nullable(true)
  node_nullable(true)
  has_nodes_field(true)

  field :total_count, Integer, null: false

  def total_count
    object.items.size
  end
end
```

Then, pass the field class as `connection_type_class(...)` wherever it should be used:

```ruby
module Types
  class Types::BaseObject < GraphQL::Schema::Object
    # Use this class for defining connections
    connection_type_class MyCustomConnection
  end
end
```

Now, all type classes that extend `BaseObject` will have a connection_type with the additional field `totalCount`.

### Customizing Edges

Edges may be customized in a similar way to Connections.

- Create a new class extending 'GraphQL::Types::Relay::BaseEdge'
- Assign it to your object/interface type with `edge_type_class(MyCustomEdge)`

### Customizing Arguments

Arguments may be customized in a similar way to Fields.

- Create a new class extending `GraphQL::Schema::Argument`
- Use `argument_class(MyArgClass)` to assign it to your base field class, base resolver class, and base mutation class

Then, in your custom argument class, you can use `#initialize(name, type, desc = nil, **kwargs)` to take input from the DSL.

### Customizing Enum Values

Enum values may be customized in a similar way to Fields.

- Create a new class extending `GraphQL::Schema::EnumValue`
- Assign it to your base `Enum` class with `enum_value_class(MyEnumValueClass)`

Then, in your custom enum class, you can use `#initialize(name, desc = nil, **kwargs)` to take input from the DSL.
