---
layout: guide
doc_stub: false
search: true
enterprise: true
section: GraphQL Enterprise - Changesets
title: Releasing Changesets
desc: Associating changes to version numbers
index: 3
---

To be available to clients, Changesets added to the schema with `use GraphQL::Enterprise::Changeset::Release changeset_dir: "..."`:

```ruby
class MyAppSchema < GraphQL::Schema
  # Add this before root types so that newly-added types are also added to the schema
  use GraphQL::Enterprise::Changeset::Release, changeset_dir: "app/graphql/changesets"

  query(...)
  mutation(...)
  subscription(...)
end
```

This attaches each Changeset defined in `app/graphql/changesets/*.rb` to the schema. (It assumes Rails conventions, where an underscored file like `app/graphql/changesets/add_some_feature.rb` contains a class like `Changesets::AddSomeFeature`.)

{% callout warning %}

Add `GraphQL::Enterprise::Changeset::Release` _before_ hooking up your root `query(...)`, `mutation(...)`, and `subscription(...)` types. Otherwise, the schema may not find links to types in new schema versions.

{% endcallout %}

Alternatively, Changesets can be explicitly attached using `changesets: [...]`, for example:

```ruby
class MyAppSchema < GraphQL::Schema
  use GraphQL::Enterprise::Changeset::Release, changesets: [
    Changesets::DeprecateRecipeFlag,
    Changesets::RemoveRecipeFlag,
  ]
  # ...
end
```

Only changesets in the directory (or in the array) will be shown to clients. The `release ...` configuration in the changeset will be compared to `context[:changeset_version]` to determine if the changeset applies to the current request.

## Inspecting Releases

To preview releases, you can create schema dumps by passing `context: { changeset_version: ... }` to {{ "Schema.to_definition" | api_doc }}.

For example, to see how the schema looks with `API-Version: 2021-06-01`:

```ruby
schema_sdl = MyAppSchema.to_definition(context: { changeset_version: "2021-06-01"})
# The GraphQL schema definition for the schema at version "2021-06-01":
puts schema_sdl
```

To make sure schema versions don't change unexpectedly, use the techniques described in the {% internal_link "Schema structure guide", "/testing/schema_structure" %}.

### Introspection Methods

You can also inspect a schema's changesets programmatically. `GraphQL::Enterprise` adds a `Schema.changesets` method which returns a `Set` of changeset classes:

```ruby
MySchema.changesets
# #<Set: {AddNewFeature, RemoveOldFeature}>
```

Additionally, each changeset has a `.changes` method describing its modifications:

```ruby
AddNewFeature.changes
# [
#   #<GraphQL::Enterprise::Changeset::Change: ...>,
#   #<GraphQL::Enterprise::Changeset::Change: ...>,
#   #<GraphQL::Enterprise::Changeset::Change: ...>,
#   ...
# ]
```

Each `Change` object responds to:

- `.member`, the part of the schema that was modified
- `.type`, the kind of modification (`:addition` when something new is added, `:removal` when a member is removed or replaced with a new definition)
