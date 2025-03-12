---
layout: guide
doc_stub: false
search: true
section: Type Definitions
title: Enums
desc: Enums are sets of discrete values
index: 2
---

Enum types are sets of discrete values. An enum field must return one of the possible values of the enum. In the [GraphQL Schema Definition Language](https://graphql.org/learn/schema/#type-language) (SDL), enums are described like this:

```ruby
enum MediaCategory {
  AUDIO
  IMAGE
  TEXT
  VIDEO
}
```

So, a `MediaCategory` value is one of: `AUDIO`, `IMAGE`, `TEXT`, or `VIDEO`. This is similar to [ActiveRecord enums](https://api.rubyonrails.org/classes/ActiveRecord/Enum.html).

In a GraphQL query, enums are written as identifiers (not strings), for example:

```ruby
search(term: "puppies", mediaType: IMAGE) { ... }
```

(Notice that `IMAGE` doesn't have quotes.)

But, when GraphQL responses or variables are transported using JSON, enum values are expressed as strings, for example:

```ruby
# in a graphql controller:
params["variables"]
# { "mediaType" => "IMAGE" }
```

## Defining Enum Types

In your application, enums extend {{ "GraphQL::Schema::Enum" | api_doc }} and define values with the `value(...)` method:

```ruby
# First, a base class
# app/graphql/types/base_enum.rb
class Types::BaseEnum < GraphQL::Schema::Enum
end

# app/graphql/types/media_category.rb
class Types::MediaCategory < Types::BaseEnum
  value "AUDIO", "An audio file, such as music or spoken word"
  value "IMAGE", "A still image, such as a photo or graphic"
  value "TEXT", "Written words"
  value "VIDEO", "Motion picture, may have audio"
end
```

Each value may have:

- A description (as the second argument or `description:` keyword)
- A comment (as a `comment:` keyword)
- A deprecation reason (as `deprecation_reason:`), marking this value as deprecated
- A corresponding Ruby value (as `value:`), see below

By default, Ruby strings correspond to GraphQL enum values. But, you can provide `value:` options to specify a different mapping. For example, if you use symbols instead of strings, you can say:

```ruby
value "AUDIO", value: :audio
```

Then, GraphQL inputs of `AUDIO` will be converted to `:audio` and Ruby values of `:audio` will be converted to `"AUDIO"` in GraphQL responses.

Enum classes are never instantiated and their methods are never called.

You can get the GraphQL name of the enum value using the method matching its downcased name:

```ruby
Types::MediaCategory.audio # => "AUDIO"
```

You can pass a `value_method:` to override the value of the generated method:

```ruby
value "AUDIO", value: :audio, value_method: :lo_fi_audio

# ...

Types::MediaCategory.lo_fi_audio # => "AUDIO"
```

Also, you can completely skip the method generation by setting `value_method` to `false`

```ruby
value "AUDIO", value: :audio, value_method: false
```
