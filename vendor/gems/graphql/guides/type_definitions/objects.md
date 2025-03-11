---
layout: guide
doc_stub: false
search: true
section: Type Definitions
title: Objects
desc: Objects expose data and link to other objects
index: 0
---

GraphQL object types are the bread and butter of GraphQL APIs. Each object has _fields_ which expose data and may be queried by name. For example, we can query a `User` like this:

```ruby
user {
  handle
  email
}
```

And get back values like this:

```ruby
{
  "user" => {
    "handle" => "rmosolgo",
    "email" => nil,
  }
}
```

Generally speaking, GraphQL object types correspond to models in your application, like `User`, `Product`, or `Comment`.  Sometimes, object types are described using the [GraphQL Schema Definition Language](https://graphql.org/learn/schema/#type-language) (SDL):

```ruby
type User {
  email: String
  handle: String!
  friends: [User!]!
}
```

This means that `User` objects have three fields:

- `email`, which may return a `String` _or_ `nil`.
- `handle`, which returns a `String` but _never_ `nil` (`!` means the field never returns `nil`)
- `friends`, which returns a list of other `User`s (`[...]` means the field returns a list of values; `User!` means the list contains `User` objects, and never contains `nil`.)

The same object can be defined using Ruby:

```ruby
class Types::User < GraphQL::Schema::Object
  field :email, String
  field :handle, String, null: false
  field :friends, [User], null: false
end
```

The rest of this guide will describe how to define GraphQL object types in Ruby. To learn more about GraphQL object types in general, see the [GraphQL docs](https://graphql.org/learn/schema/#object-types-and-fields).

## Object classes

Classes extending {{ "GraphQL::Schema::Object" | api_doc }} describe [Object types](https://graphql.org/learn/schema/#object-types-and-fields) and customize their behavior.

Object fields can be created with the `field(...)` class method, [described in detail below](#fields)

Field and argument names should be underscored as a convention. They will be converted to camelCase in the underlying GraphQL type and be camelCase in the schema itself.

```ruby
# first, somewhere, a base class:
class Types::BaseObject < GraphQL::Schema::Object
end

# then...
class Types::TodoList < Types::BaseObject
  comment "Comment of the TodoList type"
  description "A list of items which may be completed"

  field :name, String, "The unique name of this list", null: false
  field :is_completed, String, "Completed status depending on all tasks being done.", null: false
  # Related Object:
  field :owner, Types::User, "The creator of this list", null: false
  # List field:
  field :viewers, [Types::User], "Users who can see this list", null: false
  # Connection:
  field :items, Types::TodoItem.connection_type, "Tasks on this list", null: false do
    argument :status, TodoStatus, "Restrict items to this status", required: false
  end
end
```

## Fields

Object fields expose data about that object or connect the object to other objects. You can add fields to your object types with the `field(...)` class method.

See the {% internal_link "Fields guide", "/fields/introduction" %} for details about object fields.

## Implementing interfaces

If an object implements any interfaces, they can be added with `implements`, for example:

```ruby
# This object implements some interfaces:
implements GraphQL::Types::Relay::Node
implements Types::UserAssignableType
```

When an object `implements` interfaces, it:

- inherits the GraphQL field definitions from that object
- includes that module into the object definition

Read more about interfaces in the {% internal_link "Interfaces guide", "/type_definitions/interfaces" %}
