---
layout: guide
doc_stub: false
search: true
section: Fields
title: Resolvers
desc: Reusable, extendable resolution logic for complex fields
index: 2
redirect_from:
  - /fields/functions
---

A {{ "GraphQL::Schema::Resolver" | api_doc }} is a container for field signature and resolution logic. It can be attached to a field with the `resolver:` keyword:

```ruby
# Use the resolver class to execute this field
field :pending_orders, resolver: PendingOrders
```

Under the hood, {{ "GraphQL::Schema::Mutation" | api_doc }} is a specialized subclass of `Resolver`.

## First, ask yourself ...

Do you really need a `Resolver`? Putting logic in a Resolver has some downsides:

- Since it's coupled to GraphQL, it's harder to test than a plain ol' Ruby object in your app
- Since the base class comes from GraphQL-Ruby, it's subject to upstream changes which may require updates in your code

Here are a few alternatives to consider:

- Put display logic (sorting, filtering, etc.) into a plain ol' Ruby class in your app, and test that class
- Hook up that object with a method, for example:

```ruby
field :recommended_items, [Types::Item], null: false
def recommended_items
  ItemRecommendation.new(user: context[:viewer]).items
end
```

- If you have lots of arguments to share, use a class method to generate fields, for example:

```ruby
# Generate a field which returns a filtered, sorted list of items
def self.items_field(name, override_options, &block)
  # Prepare options
  default_field_options = { type: [Types::Item], null: false }
  field_options = default_field_options.merge(override_options)
  # Create the field
  field(name, **field_options) do
    argument :order_by, Types::ItemOrder, required: false
    argument :category, Types::ItemCategory, required: false
    # Allow an override block to add more arguments
    instance_eval(&block) if block_given?
  end
end

# Then use the generator to create a field:
items_field(:recommended_items) do |field|
  field.argument :similar_to_product_id, ID, required: false
end
# Implement the field
def recommended_items
  # ...
end
```

As a matter of code organization, that class method could be put in a module and shared between different classes that need it.

- If you need the _same_ logic shared between several objects, consider using a Ruby module and its `self.included` hook, for example:

```ruby
module HasRecommendedItems
  def self.included(child_class)
    # attach the field here
    child_class.field(:recommended_items, [Types::Item], null: false)
  end

  # then implement the field
  def recommended_items
    # ...
  end
end

# Add the field to some objects:
class Types::User < BaseObject
  include HasRecommendedItems # adds the field
end
```

- If the module approach looks good to you, also consider {% internal_link "Interfaces", "/type_definitions/interfaces" %}. They also share behavior between objects (since they're just modules that get included, after all), and they expose that commonality to clients via introspection.

## When do you really need a resolver?

So, if there are other, better options, why does `Resolver` exist? Here are a few specific advantages:

- __Isolation__. A `Resolver` is instantiated for each call to the field, so its instance variables are private to that object. If you need to use instance variables for some reason, this helps. You have a guarantee that those values won't hang around when the work is done.
- __Complex Schema Generation__. `RelayClassicMutation` (which is a `Resolver` subclass) generates input types and return types for each mutation. Using a `Resolver` class makes it easier to implement, share and extend this code generation logic.

## Using `resolver`

Use the base resolver class:

```ruby
module Resolvers
  class RecommendedItems < BaseResolver
    type [Types::Item], null: false
    description "Items this user might like"

    argument :order_by, Types::ItemOrder, required: false
    argument :category, Types::ItemCategory, required: false

    def resolve(order_by: nil, category: nil)
      # call your application logic here:
      recommendations = ItemRecommendation.new(
        viewer: context[:viewer],
        recommended_for: object,
        order_by: order_by,
        category: category,
      )
      # return the list of items
      recommendations.items
    end
  end
end
```

And attach it to your field:

```ruby
class Types::User < Types::BaseObject
  field :recommended_items, resolver: Resolvers::RecommendedItems
end
```

Since the `Resolver` lifecycle is managed by the GraphQL runtime, the best way to test it is to execute GraphQL queries and check the results.

### Nesting resolvers of the same type

You may run into cyclical loading issues when using a resolver within the definition of the type the resolver returns e.g.

```ruby
# app/graphql/types/query_type.rb

module Types
  class QueryType < Types::BaseObject
    field :tasks, resolver: Resolvers::TasksResolver
  end
end

# app/graphql/types/task_type.rb

module Types
  class TaskType < Types::BaseObject
    field :title, String, null: false
    field :tasks, resolver: Resolvers::TasksResolver
  end
end

# app/graphql/resolvers/tasks_resolver.rb

module Resolvers
  class TasksResolver < BaseResolver
    type [Types::TaskType], null: false

    def resolve
      []
    end
  end
end
```

The above can produce the following error: `Failed to build return type for Task.tasks from nil: Unexpected type input:  (NilClass)`.

A simple solution is to express the type as a string in the resolver:

```ruby
module Resolvers
  class TasksResolver < BaseResolver
    type "[Types::TaskType]", null: false

    def resolve
      []
    end
  end
end
```

In doing so, you can defer the loading of the type class until the nested resolver has already been loaded.

# Extensions

In cases when you want your resolvers to add some extensions to the field they resolve, you can use `extension` method, which accepts extension class and options. Multiple extensions can be configured for a single resolver.

```ruby
class GreetingExtension < GraphQL::Schema::FieldExtension
  def resolve(object:, arguments:, **rest)
    name = yield(object, arguments)
    "#{options[:greeting]}, #{name}!"
  end
end

class ResolverWithExtension < BaseResolver
  type String, null: false

  extension GreetingExtension, greeting: "Hi"

  def resolve
    "Robert"
  end
end
```
