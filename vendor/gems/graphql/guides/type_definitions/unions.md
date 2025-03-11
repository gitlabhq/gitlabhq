---
layout: guide
doc_stub: false
search: true
section: Type Definitions
title: Unions
desc: Unions are sets of types which may appear in the same place (but don't share fields).
index: 5
---

A union type is a set of object types which may appear in the same spot. Here's a union, expressed in [GraphQL Schema Definition Language](https://graphql.org/learn/schema/#type-language) (SDL):

```ruby
union MediaItem = AudioClip | VideoClip | Image | TextSnippet
```

This might be used on a search field, for example:

```ruby
searchMedia(term: "puppies") {
  ... on AudioClip {
    duration
  }
  ... on VideoClip {
    previewURL
    resolution
  }
  ... on Image {
    thumbnailURL
  }
  ... on TextSnippet {
    teaserText
  }
}
```

Here, the `searchMedia` field returns `[MediaItem!]`, a list where each member is part of the `MediaItem` union. So, for each member, we want to select different fields depending on which kind of object that member is.

{% internal_link "Interfaces", "/type_definitions/interfaces" %} are a similar concept, but in an interface, all types must share some common fields. Unions are a good choice when the object types don't have any significant fields in common.

Since union members share _no_ fields, selections are _always_ made with typed fragments (`... on SomeType`, as seen above).

## Defining Union Types


Unions extend `GraphQL::Schema::Union`. First, make a base class:

```ruby
class Types::BaseUnion < GraphQL::Schema::Union
end
```

Then, extend that one for each union in your schema:

```ruby
class Types::CommentSubject < Types::BaseUnion
  comment "TODO comment on the union"
  description "Objects which may be commented on"
  possible_types Types::Post, Types::Image

  # Optional: if this method is defined, it will override `Schema.resolve_type`
  def self.resolve_type(object, context)
    if object.is_a?(BlogPost)
      Types::Post
    else
      Types::Image
    end
  end
end
```

The `possible_types(*types)` method accepts one or more types which belong to this union.

Union classes are never instantiated; At runtime, only their `.resolve_type` methods may be called (if defined).

For information about `.resolve_type`, see the {% internal_link "Interfaces guide", "/type_definitions/interfaces#resolve-type" %}.
