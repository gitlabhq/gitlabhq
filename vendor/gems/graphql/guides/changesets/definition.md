---
layout: guide
doc_stub: false
search: true
enterprise: true
section: GraphQL Enterprise - Changesets
title: Defining Changesets
desc: Creating a set of modifications to release in an API version
index: 2
---

After {% internal_link "installing Changeset integrations", "/changesets/installation" %} in your schema, you can create Changesets which modify parts of the schema. Changesets extend `GraphQL::Enterprise::Changeset` and include a `release` string. Once a Changeset class is defined, it can be referenced with `added_in: ...` or `removed_in: ...` configurations in the schema.

__Note:__ Before GraphQL-Enterprise 1.3.0, Changesets were configured with `modifies ...` blocks. These blocks are still supported and you can find the documentation for that API [on GitHub](https://github.com/rmosolgo/graphql-ruby/blob/v2.0.22/guides/changesets/definition.md).


## Changeset Classes

This Changeset will be available to any client whose `context[:changeset_version]` is on or after `2020-12-01`:

```ruby
# app/graphql/changesets/deprecate_recipe_flag.rb
class Changesets::DeprecateRecipeTags < GraphQL::Enterprise::Changeset
  release "2020-12-01"
end
```

Additionally, Changesets must be {% internal_link "released", "/changesets/releases" %} for their changes to be published.

## Publishing with `added_in:`

New things can be published in a changeset by adding `added_in: SomeChangeset` to their configuration. For example, to add a new argument to a field:

```ruby
field :search_recipes, [Types::Recipe] do
  argument :query, String
  argument :tags, [Types::RecipeTag], required: false, added_in: Changesets::AddRecipeTags
end
```

You can also provide a _replacement_ implementation by using `added_in:`. When a new definition has the same name as an existing definition, it implicitly replaces the previous definition in new versions of the API. For example:

```ruby
field :rating, Integer, "A 1-5 score for this recipe" # This definition will be superseded by the following one
field :rating, Float, "A 1.0-5.0 score for this recipe", added_in: Changesets::FloatingPointRatings
```

Here, a new implementation for `rating` will be used when clients requests an API version that includes `Changesets::FloatingPointRatings`. (If the client requests a version _before_ that changeset, then the preceding implementation would be used instead.)

## Removing with `removed_in:`

A `removed_in:` configuration removes something in the named changeset. For example, these enum values are replaced with more clearly-named ones:

```ruby
class Types::RecipeTag < Types::BaseEnum
  # These are replaced by *_HEAT below:
  value :SPICY, removed_in: Changesets::ClarifyHeatTags
  value :MEDIUM, removed_in: Changesets::ClarifyHeatTags
  value :MILD, removed_in: Changesets::ClarifyHeatTags
  # These new tags are more clear:
  value :SPICY_HEAT, added_in: Changesets::ClarifyHeatTags
  value :MEDIUM_HEAT, added_in: Changesets::ClarifyHeatTags
  value :MILD_HEAT, added_in: Changesets::ClarifyHeatTags
end
```

If something has been defined several times, a `removed_in:` configuration removes _all_ definitions:

```ruby
class Mutations::SubmitRecipeRating < Mutations::BaseMutation
  # This is replaced in future API versions by the following argument
  argument :rating, Integer
  # This replaces the previous, but in another future version,
  # it is removed completely (and so is the previous one)
  argument :rating, Float, added_in: Changesets::FloatingPointRatings, removed_in: Changesets::RemoveRatingsCompletely
end
```

## Examples

See below for the different kind of modifications you can make in a changeset:

- [Fields](#fields): adding, modifying, and removing fields
- [Arguments](#arguments): adding, modifying, and removing arguments
- [Enum values](#enum-values): adding, modifying, and removing arguments
- [Unions](#unions): adding or removing object types from a union
- [Interfaces](#interfaces): adding or removing interface implementations from object types
- [Types](#types): changing one type definition for another
- [Runtime](#runtime): choosing a behavior at runtime based on the current request and changeset

### Fields

To add or redefine a field, use `field(..., added_in: ...)`, including all configuration values for the new implementation (see {{ "GraphQL::Schema::Field#initialize" | api_doc }}). The definition given here will override the previous definition (if there was one) whenever this Changeset applies.

```ruby
class Types::Recipe < Types::BaseObject
  # This new field is available when `context[:changeset_version]`
  # is on or after the release date of `AddRecipeTags`
  field :tags, [Types::RecipeTag], added_in: Changeset::AddRecipeTags
end
```

To remove a field, add a `removed_in: ...` configuration to the last definition of the field:

```ruby
class Types::Recipe < Types::BaseObject
  # Even after migrating to floating point values,
  # the "rating" feature never took off,
  # so we removed it entirely eventually.
  field :rating, Integer
  field :rating, Float, added_in: Changeset::FloatingPointRatings,
    removed_in: Changeset::RemoveRatings
end
```

When a field is removed, queries that request that field will be invalid, unless the client has requested a previous API version where the field is still available.

### Arguments

You can add, redefine, or remove arguments that belong to fields, input objects, or resolvers. Use `added_in: ...` to provide a new (or updated) definition for an argument, for example:

```ruby
class Types::RecipesFilter < Types::BaseInputObject
  argument :rating, Integer
  # This new definition is available when
  # the client's `context[:changeset_version]` includes `FloatingPointRatings`
  argument :rating, Float, added_in: Changesets::FloatingPointRatings
end
```

To remove an argument entirely, add a `removed_in: ...` configuration to the last definition. It will remove _all_ implementations for that argument. For example:

```ruby
class Mutations::SubmitRating < Mutations::BaseMutation
  # Remove this because it's irrelevant:
  argument :phone_number, String, removed_in: Changesets::StopCollectingPersonalInformation
end
```

When arguments are removed, the schema will reject any queries which use them unless the client has requested a previous API version where the argument is still allowed.

### Enum Values

With Changesets, you can add, redefine, or remove enum values. To add a new value (or provide a new implementation for a value), include `added_in:` in the `value(...)` configuration:

```ruby
class Types::RecipeTag < Types::BaseEnum
  # This enum will accept and return `KETO` only when the client's API version
  # includes `AddKetoDietSupport`'s release date.
  value :KETO, added_in: Changesets::AddKetoDietSupport
end
```

Values can be removed with `removed_in:`, for example:

```ruby
class Types::RecipeTag < Types::BaseEnum
  # Old API versions will serve this value;
  # new versions won't accept it or return it.
  value :GRAPEFRUIT_DIET, removed_in: Changesets::RemoveLegacyDiets
end
```

When enum values are removed, they won't be accepted as input and they won't be allowed as return values from fields unless the client has requested a previous API version where those values are still allowed.

### Unions

You can add to or remove from a union's possible types. To release a new union member, include `added_in:` in the `possible_types` configuration:

```ruby
class Types::Cookable < Types::BaseUnion
 possible_types Types::Recipe, Types::Ingredient
 # Add this to the union when clients opt in to our new feature:
 possible_types Types::Cuisine, added_in: Changeset::ReleaseCuisines
```

To remove a member from a union, move it to a `possible_types` call with `removed_in: ...`:

```ruby
# Stop including this in the union in new API versions:
possible_types Types::Chef, removed_in: Changeset::LessChefHype
```

When a possible type is removed, it will not be associated with the union type in introspection queries or schema dumps.

### Interfaces

You can add to or remove from an object type's interface definitions. To add one or more interface implementations, use `implements(..., added_in:)`. This will add the interface and its fields to the object whenever this Changeset is active, for example:

```ruby
class Types::Recipe < Types::BaseObject
  # Add this new implementation in new API versions only:
  implements Types::RssSubject, added_in: Changesets::AddRssSupport
end
```


To remove one or more more interface implementations, add `removed_in:` to the `implements ...` configuration, for example:

```ruby
  implements Types::RssSubject,
    added_in: Changesets::AddRssSupport,
    # Sadly, nobody seems to want to use this,
    # so we removed it all:
    removed_in: Changesets::RemoveRssSupport
```

When an interface implementation is removed, then the interface will not be associated with the object in introspection queries or schema dumps. Also, any fields inherited from the interface will be hidden from clients. (If the object defines the field itself, it will still be visible.)

### Types

Using Changesets, it's possible to define a new type using the same name as an old type. (Only one type per name is allowed for each query, but different queries can use different types for the same name.)

First, to define two types with the same name, make two different type definitions. One of them will have to use `graphql_name(...)` to specify the conflicting type name. For example, to migrate an enum type to an object type, define two types:

```ruby
# app/graphql/types/legacy_recipe_flag.rb

# In the old version of the schema, "recipe tags" were limited to defined set of values.
# This enum was renamed from `Types::RecipeTag`, then `graphql_name("RecipeTag")`
# was added for GraphQL.
class Types::LegacyRecipeTag < Types::BaseEnum
  graphql_name "RecipeTag"
  # ...
end
```

```ruby
# app/graphql/types/recipe_flag.rb

# But in the new schema, each tag is a full-fledged object with fields of its own
class Types::RecipeTag < Types::BaseObject
  field :name, String, null: false
  field :is_vegetarian, Boolean, null: false
  # ...
end
```

Then, add or update fields or arguments to use the _new_ type instead of the old one. For example:

```diff
  class Types::Recipe < Types::BaseObject

# Change this definition to point at the newly-renamed _legacy_ type
# (It's the same type definition, but the Ruby class has a new name)
-   field :tags, [Types::RecipeTag]
+   field :tags, [Types::LegacyRecipeTag]

# And add a new field for the new type:
+   field :tags, [Types::RecipeTag], added_in: Changesets::MigrateRecipeTagToObject
  end
```

With that Changeset, `Recipe.tags` will return an object type instead of an enum type. Clients requesting older versions will still receive enum values from that field.

The resolver will probably need an update, too, for example:

```ruby
class Types::Recipe < Types::BaseObject
  # Here's the original definition which returns enum values:
  field :tags, [Types::LegacyRecipeTag], null: false
  # Here's the new definition which replaces the previous one on new API versions:
  field :tags, [Types::RecipeTag], null: false, added_in: Changesets::MigrateRecipeTagToObject

  def flags
    all_flag_objects = object.flag_objects
    if Changesets::MigrateRecipeTagToObject.active?(context)
      # Here's the new behavior, returning full objects:
      all_flag_objects
    else
      # Convert this to enum values, for legacy behavior:
      all_flag_objects.map { |f| f.name.upcase }
    end
  end
end
```

That way, legacy clients will continue to receive enum values while new clients will receive objects.

## Runtime

While a query is running, you can check if a changeset applies by using its `.active?(context)` method. For example:

```ruby
class Types::Recipe
  field :flag, Types::RecipeFlag, null: true

  def flag
    # Check if this changeset applies to the current request:
    if Changesets::DeprecateRecipeFlag.active?(context)
      Stats.count(:deprecated_recipe_flag, context[:viewer])
    end
    # ...
  end
end
```

Besides observability, you can use a runtime check when a resolver needs to pick a different behavior depending on the API version.

After defining a changeset, add it to the schema to {% internal_link "release it", "/changesets/releases" %}.
