---
layout: guide
doc_stub: false
search: true
section: Fields
title: Introduction
desc: Implement fields and resolvers with the Ruby DSL
index: 0
---


Object fields expose data about that object or connect the object to other objects. You can add fields to your object types with the `field(...)` class method, for example:

```ruby
field :name, String, "The unique name of this list", null: false
```

{% internal_link "Objects", "/type_definitions/objects" %} and {% internal_link "Interfaces", "/type_definitions/interfaces" %} have fields.

The different elements of field definition are addressed below:

- [Names](#field-names) identify the field in GraphQL
- [Return types](#field-return-type) say what kind of data this field returns
- [Documentation](#field-documentation) includes description, comments and deprecation notes
- [Resolution behavior](#field-resolution) hooks up Ruby code to the GraphQL field
- [Arguments](#field-arguments) allow fields to take input when they're queried
- [Extra field metadata](#extra-field-metadata) for low-level access to the GraphQL-Ruby runtime
- [Add default values for field parameters](#field-parameter-default-values)

## Field Names

A field's name is provided as the first argument or as the `name:` option:

```ruby
field :team_captain, ...
# or:
field ..., name: :team_captain
```

Under the hood, GraphQL-Ruby **camelizes** field names, so `field :team_captain, ...` would be `{ teamCaptain }` in GraphQL. You can disable this behavior by adding `camelize: false` to your field definition or to the [default field options](#field-parameter-default-values).

The field's name is also used as the basis of [field resolution](#field-resolution).

## Field Return Type

The second argument to `field(...)` is the return type. This can be:

- A built-in GraphQL type (`Integer`, `Float`, `String`, `ID`, or `Boolean`)
- A GraphQL type from your application
- An _array_ of any of the above, which denotes a {% internal_link "list type", "/type_definitions/lists" %}.

{% internal_link "Nullability", "/type_definitions/non_nulls" %} is expressed with the `null:` keyword:

- `null: true` (default) means that the field _may_ return `nil`
- `null: false` means the field is non-nullable; it may not return `nil`. If the implementation returns `nil`, GraphQL-Ruby will return an error to the client.

Additionally, list types maybe nullable by adding `[..., null: true]` to the definition.

Here are some examples:

```ruby
field :name, String # `String`, may return a `String` or `nil`
field :id, ID, null: false # `ID!`, always returns an `ID`, never `nil`
field :teammates, [Types::User], null: false # `[User!]!`, always returns a list containing `User`s
field :scores, [Integer, null: true] # `[Int]`, may return a list or `nil`, the list may contain a mix of `Integer`s and `nil`s
```

## Field Documentation

Fields may be documented with a __description__, __comment__ and may be __deprecated__.

__Descriptions__ can be added with the `field(...)` method as a positional argument, a keyword argument, or inside the block:

```ruby
# 3rd positional argument
field :name, String, "The name of this thing", null: false

# `description:` keyword
field :name, String, null: false,
  description: "The name of this thing"

# inside the block
field :name, String, null: false do
  description "The name of this thing"
end
```

__Comments__ can be added with the `field(...)` method as a keyword argument, or inside the block:
```ruby
# `comment:` keyword
field :name, String, null: false, comment: "Rename to full name"

# inside the block
field :name, String, null: false do
  comment "Rename to full name"
end
```

Generates field name with comment above "Rename to full name" above.

```graphql
type Foo {
    # Rename to full name
    name: String!
}
```

__Deprecated__ fields can be marked by adding a `deprecation_reason:` keyword argument:

```ruby
field :email, String,
  deprecation_reason: "Users may have multiple emails, use `User.emails` instead."
```

Fields with a `deprecation_reason:` will appear as "deprecated" in GraphiQL.

## Field Resolution

In general, fields return Ruby values corresponding to their GraphQL return types. For example, a field with the return type `String` should return a Ruby string, and a field with the return type `[User!]!` should return a Ruby array with zero or more `User` objects in it.

By default, fields return values by:

- Trying to call a method on the underlying object; _OR_
- If the underlying object is a `Hash`, lookup a key in that hash.
- An optional `:fallback_value` can be supplied that will be used if the above fail.

The method name or hash key corresponds to the field name, so in this example:

```ruby
field :top_score, Integer, null: false
```

The default behavior is to look for a `#top_score` method, or lookup a `Hash` key, `:top_score` (symbol) or `"top_score"` (string).

You can override the method name with the `method:` keyword, or override the hash key(s) with the `hash_key:` or `dig:` keyword, for example:

```ruby
# Use the `#best_score` method to resolve this field
field :top_score, Integer, null: false,
  method: :best_score

# Lookup `hash["allPlayers"]` to resolve this field
field :players, [User], null: false,
  hash_key: "allPlayers"

# Use the `#dig` method on the hash with `:nested` and `:movies` keys
field :movies, [Movie], null: false,
  dig: [:nested, :movies]
```

To pass-through the underlying object without calling a method on it, you can use `method: :itself`:

```ruby
field :player, User, null: false,
  method: :itself
```

This is equivalent to:

```ruby
field :player, User, null: false

def player
  object
end
```

If you don't want to delegate to the underlying object, you can define a method for each field:

```ruby
# Use the custom method below to resolve this field
field :total_games_played, Integer, null: false

def total_games_played
  object.games.count
end
```

Inside the method, you can access some helper methods:

- `object` is the underlying application object (formerly `obj` to resolve functions)
- `context` is the query context (passed as `context:` when executing queries, formerly `ctx` to resolve functions)

Additionally, when you define arguments (see below), they're passed to the method definition, for example:

```ruby
# Call the custom method with incoming arguments
field :current_winning_streak, Integer, null: false do
  argument :include_ties, Boolean, required: false, default_value: false
end

def current_winning_streak(include_ties:)
  # Business logic goes here
end
```

As the examples above show, by default the custom method name must match the field name. If you want to use a different custom method, the `resolver_method` option is available:

```ruby
# Use the custom method with a non-default name below to resolve this field
field :total_games_played, Integer, null: false, resolver_method: :games_played

def games_played
  object.games.count
end
```

`resolver_method` has two main use cases:

1. resolver re-use between multiple fields
2. dealing with method conflicts (specifically if you have fields named `context` or `object`)

Note that `resolver_method` _cannot_ be used in combination with `method` or `hash_key`.

## Field Arguments

_Arguments_ allow fields to take input to their resolution. For example:

- A `search()` field may take a `term:` argument, which is the query to use for searching, eg `search(term: "GraphQL")`
- A `user()` field may take an `id:` argument, which specifies which user to find, eg `user(id: 1)`
- An `attachments()` field may take a `type:` argument, which filters the result by file type, eg `attachments(type: PHOTO)`

Read more in the {% internal_link "Arguments guide", "/fields/arguments" %}

## Extra Field Metadata

Inside a field method, you can access some low-level objects from the GraphQL-Ruby runtime. Be warned, these APIs are subject to change, so check the changelog when updating.

A few `extras` are available:

- `ast_node`
- `graphql_name` (the field's name)
- `owner` (the type that this field belongs to)
- `lookahead` (see {% internal_link "Lookahead", "/queries/lookahead" %})
- `execution_errors`, whose `#add(err_or_msg)` method should be used for adding errors
- `argument_details` (Interpreter only), an instance of {{ "GraphQL::Execution::Interpreter::Arguments" | api_doc }} with argument metadata
- `parent` (the previous `object` in the query)
- Custom extras, see below

To inject them into your field method, first, add the `extras:` option to the field definition:

```ruby
field :my_field, String, null: false, extras: [:ast_node]
```

Then add `ast_node:` keyword to the method signature:

```ruby
def my_field(ast_node:)
  # ...
end
```

At runtime, the requested runtime object will be passed to the field.

__Custom extras__ are also possible. Any method on your field class can be passed to `extras: [...]`, and the value will be injected into the method. For example, `extras: [:owner]` will inject the object type who owns the field. Any new methods on your custom field class may be used, too.

## Field Parameter Default Values

The field method requires you to pass `null:` keyword argument to determine whether the field is nullable or not. For another field you may want to override `camelize`, which is `true` by default. You can override this behavior by adding a custom field with overwritten `camelize` option, which is `true` by default.

```ruby
class CustomField < GraphQL::Schema::Field
  # Add `null: false` and `camelize: false` which provide default values
  # in case the caller doesn't pass anything for those arguments.
  # **kwargs is a catch-all that will get everything else
  def initialize(*args, null: false, camelize: false, **kwargs, &block)
    # Then, call super _without_ any args, where Ruby will take
    # _all_ the args originally passed to this method and pass it to the super method.
    super
  end
end
```

To use `CustomField` in your Objects and Interfaces, you'll need to register it as a `field_class` on those classes. See  [Customizing Fields](https://graphql-ruby.org/type_definitions/extensions#customizing-fields) for more information on how to do so.
