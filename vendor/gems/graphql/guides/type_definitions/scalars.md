---
layout: guide
doc_stub: false
search: true
section: Type Definitions
title: Scalars
desc: Scalars are "simple" data types like integers and strings
index: 1
---

Scalars are "leaf" values in GraphQL. There are several built-in scalars, and you can define custom scalars, too. ({% internal_link "Enums", "/type_definitions/enums" %} are also leaf values.) The built-in scalars are:

- `String`, like a JSON or Ruby string
- `Int`, like a JSON or Ruby integer
- `Float`, like a JSON or Ruby floating point decimal
- `Boolean`, like a JSON or Ruby boolean (`true` or `false`)
- `ID`, which a specialized `String` for representing unique object identifiers
- `ISO8601DateTime`, an ISO 8601-encoded datetime
- `ISO8601Date`, an ISO 8601-encoded date
- `ISO8601Duration`, an ISO 8601-encoded duration. ⚠ This requires `ActiveSupport::Duration` to be loaded and will raise {{ "GraphQL::Error" | api_doc }} if it's `.coerce_*` methods are called when it is not defined.
- `JSON`, ⚠ This returns arbitrary JSON (Ruby hashes, arrays, strings, integers, floats, booleans and nils). Take care: by using this type, you completely lose all GraphQL type safety. Consider building object types for your data instead.
- `BigInt`, a numeric value which may exceed the size of a 32-bit integer

Fields can return built-in scalars by referencing them by name:

```ruby
# String field:
field :name, String,
# Integer field:
field :top_score, Int, null: false
# or:
field :top_score, Integer, null: false
# Float field
field :avg_points_per_game, Float, null: false
# Boolean field
field :is_top_ranked, Boolean, null: false
# ID field
field :id, ID, null: false
# ISO8601DateTime field
field :created_at, GraphQL::Types::ISO8601DateTime, null: false
# ISO8601Date field
field :birthday, GraphQL::Types::ISO8601Date, null: false
# ISO8601Duration field
field :age, GraphQL::Types::ISO8601Duration, null: false
# JSON field ⚠
field :parameters, GraphQL::Types::JSON, null: false
# BigInt field
field :sales, GraphQL::Types::BigInt, null: false
```

Custom scalars (see below) can also be used by name:

```ruby
# `homepage: Url`
field :homepage, Types::Url
```

In the [Schema Definition Language](https://graphql.org/learn/schema/#type-language) (SDL), scalars are simply named:

```ruby
scalar DateTime
```

## Custom Scalars

You can implement your own scalars by extending {{ "GraphQL::Schema::Scalar" | api_doc }}. For example:

```ruby
# app/graphql/types/base_scalar.rb
# Make a base class:
class Types::BaseScalar < GraphQL::Schema::Scalar
end

# app/graphql/types/url.rb
class Types::Url < Types::BaseScalar
  comment "TODO comment of the scalar"
  description "A valid URL, transported as a string"

  def self.coerce_input(input_value, context)
    # Parse the incoming object into a `URI`
    url = URI.parse(input_value)
    if url.is_a?(URI::HTTP) || url.is_a?(URI::HTTPS)
      # It's valid, return the URI object
      url
    else
      raise GraphQL::CoercionError, "#{input_value.inspect} is not a valid URL"
    end
  end

  def self.coerce_result(ruby_value, context)
    # It's transported as a string, so stringify it
    ruby_value.to_s
  end
end
```

Your class must define two class methods:

- `self.coerce_input` takes a GraphQL input and converts it into a Ruby value
- `self.coerce_result` takes the return value of a field and prepares it for the GraphQL response JSON

When incoming data is incorrect, the method may raise {{ "GraphQL::CoercionError" | api_doc }}, which will be returned to the client in the `"errors"` key.

Scalar classes are never initialized; only their `.coerce_*` methods are called at runtime.
