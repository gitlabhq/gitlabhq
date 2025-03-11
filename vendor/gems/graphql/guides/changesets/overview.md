---
layout: guide
doc_stub: false
search: true
enterprise: true
section: GraphQL Enterprise - Changesets
title: API Versioning for GraphQL-Ruby
desc: Evolve your schema over time, feature-by-feature
index: 0
---


Out-of-the-box, GraphQL is [versionless by design](https://graphql.org/learn/best-practices/#versioning). GraphQL's openness to extension paves the way for continuously expanding and improving an API. You can _always_ add new fields, new arguments, and new types to implement new features and customize existing behavior.

However, sometimes a business case may call for a different versioning scheme. [GraphQL-Enterprise](https://graphql.pro/enterprise)'s "Changesets" enable schemas to release _any_ change -- even breaking changes -- to clients, depending on what version of the schema they're using. With Changesets, you can redefine existing fields, define new types using old names, add or remove enum values -- anything, really -- while maintaining compatibility for existing clients.

## Why Changesets?

Changesets are a _complementary_ evolution technique to continuous additions. In general, additive changes (new fields, new arguments, new types) are best added right to the existing schema. But if you need to _remove_ something from the schema or redefine existing parts of the schema in non-backwards-compatible ways, Changesets provide a handy way of doing so.

For example, if you add a values to an Enum, you can just add it to the existing schema:

```diff
  class Types::RecipeTag < Types::BaseEnum
    value "LOW_FAT"
    value "LOW_CARB"
+   value "VEGAN"
+   value "KETO"
+   value "GRAPEFRUIT_DIET"
  end
```

However, if you want to change the schema in ways that would _break_ previous queries, you can do that with a Changeset:

```ruby
class Types::RecipeTag < Types::BaseEnum
  # Turns out this makes you sick:
  value "GRAPEFRUIT_DIET", removed_in: Changesets::RemoveLegacyDiets
end
```

Then, only clients requesting API versions _before_  this changeset would be able to use `GRAPEFRUIT_DIET`; clients requesting newer versions could not send it as input and would not receive it in responses.

(Changesets _also_ support additive changes, if you prefer to make them that way.)

## Getting Started

To start using Changesets, read on:

- {% internal_link "Installing Changesets", "/changesets/installation" %}
- {% internal_link "Writing Changesets", "/changesets/definition" %}
- {% internal_link "Releasing Changesets", "/changesets/releases" %}
