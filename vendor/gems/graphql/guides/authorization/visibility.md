---
layout: guide
search: true
section: Authorization
title: Visibility
desc: Programmatically hide parts of the GraphQL schema from some users.
index: 1
redirect_from:
- /schema/limiting_visibility
---

With GraphQL-Ruby, it's possible to _hide_ parts of your schema from some users. This isn't exactly part of the GraphQL spec, but it's roughly within the bounds of the spec.

Here are some reasons you might want to hide parts of your schema:

- You don't want non-admin users to know about administration functions of the schema.
- You're developing a new feature and want to make a gradual release to only a few users first.

## Hiding Parts of the Schema

To start limiting visibility of your schema, add the plugin:

```ruby
class MySchema < GraphQL::Schema
  # ...
  use GraphQL::Schema::Visibility # see below for options
end
```

Then, you can customize the visibility of parts of your schema by reimplementing various `visible?` methods:

- Type classes have a `.visible?(context)` class method
- Fields and arguments have a `#visible?(context)` instance method
- Enum values have `#visible?(context)` instance method
- Mutation classes have a `.visible?(context)` class method

These methods are called with the query context, based on the hash you pass as `context:`. If the method returns false, then that member of the schema will be treated as though it doesn't exist for the entirety of the query. That is:

- In introspection, the member will _not_ be included in the result
- In normal queries, if a query references that member, it will return a validation error, since that member doesn't exist

## Visibility Profiles

You can use named profiles to cache your schema's visibility modes. For example:

```ruby
use GraphQL::Schema::Visibility, profiles: {
  # mode_name => example_context_hash
  public: { public: true },
  beta: { public: true, beta: true },
  internal_admin: { internal_admin: true }
}
```

Then, you can run queries with `context[:visibility_profile]` equal to one of the pre-defined profiles. When you do, GraphQL-Ruby will create a cached set of types for named profile. `.visible?` will only be called with the context hash passed to `profiles: ...`.

The profile contexts passed to `profiles` will have `visibility_profile: ...` added to them, then they're frozen by GraphQL-Ruby.

### Preloading profiles

By default, GraphQL-Ruby will preload all named visibility profiles when `Rails.env.production?` is present and true. You can manually set this option by passing `use ... preload: true` (or `false`). Enable preloading in production to reduce latency of the first request to each visibility profile. Disable preloading in development to speed up application boot.

### Dynamic profiles

When you provide named visibility profiles, `context[:visibility_profile]` is required for query execution. You can also permit dynamic visibility for queries which _don't_ have that key set by passing `use ..., dynamic: true`. You could use this to support backwards compatibility or when visibility calculations are too complex to predefine.

When no named profiles are defined, all queries use dynamic visibility.

## Object Visibility

Let's say you're working on a new feature which should remain secret for a while. You can implement `.visible?` in a type:

```ruby
class Types::SecretFeature < Types::BaseObject
  def self.visible?(context)
    # only show it to users with the secret_feature enabled
    super && context[:viewer].feature_enabled?(:secret_feature)
  end
end
```

(Always call `super` to inherit the default behavior.)

Now, the following bits of GraphQL will return validation errors:

- Fields that return `SecretFeature`, eg `query { findSecretFeature { ... } }`
- Fragments on `SecretFeature`, eg `Fragment SF on SecretFeature`

And in introspection:

- `__schema { types { ... } }` will not include `SecretFeature`
- `__type(name: "SecretFeature")` will return `nil`
- Any interfaces or unions which normally include `SecretFeature` will _not_ include it
- Any fields that return `SecretFeature` will be excluded from introspection

## Field Visibility

```ruby
class Types::BaseField < GraphQL::Schema::Field
  # Pass `field ..., require_admin: true` to hide this field from non-admin users
  def initialize(*args, require_admin: false, **kwargs, &block)
    @require_admin = require_admin
    super(*args, **kwargs, &block)
  end

  def visible?(ctx)
    # if `require_admin:` was given, then require the current user to be an admin
    super && (@require_admin ? ctx[:viewer]&.admin? : true)
  end
end
```

For this to work, the base field class must be {% internal_link "configured with other GraphQL types", "/type_definitions/extensions.html#customizing-fields" %}.

## Argument Visibility

```ruby
class Types::BaseArgument < GraphQL::Schema::Argument
  # If `require_logged_in: true` is given, then this argument will be hidden from logged-out viewers
  def initialize(*args, require_logged_in: false, **kwargs, &block)
    @require_logged_in = require_logged_in
    super(*args, **kwargs, &block)
  end

  def visible?(ctx)
    super && (@require_logged_in ? ctx[:viewer].present? : true)
  end
end
```

For this to work, the base argument class must be {% internal_link "configured with other GraphQL types", "/type_definitions/extensions.html#customizing-arguments" %}.

## Opting Out

By default, GraphQL-Ruby always runs visibility checks. You can opt out of this by adding to your schema class:

```ruby
class MySchema < GraphQL::Schema
  # ...
  # Opt out of GraphQL-Ruby's visibility feature:
  use GraphQL::Schema::AlwaysVisible
end
```

For big schemas, this can be a worthwhile speed-up.

## Migration Notes

{{ "GraphQL::Schema::Visibility" | api_doc }} is a _new_ implementation of visibility in GraphQL-Ruby. It has some slight differences from the previous implementation ({{ "GraphQL::Schema::Warden" | api_doc }}):

- `Visibility` speeds up Rails app boot because it doesn't require all types to be loaded during boot and only loads types as they are used by queries.
- `Visibility` supports predefined, reusable visibility profiles which speeds up queries using complicated `visible?` checks.
- `Visibility` hides types differently in a few edge cases:
  - Previously, `Warden` hide interface and union types which had no possible types. `Visibility` doesn't check possible types (in order to support performance improvements), so those types must return `false` for `visible?` in the same cases where all possible types were hidden. Otherwise, that interface or union type will be visible but have no possible types.
  - Some other thing, see TODO
- When `Visibility` is used, several (Ruby-level) Schema introspection methods don't work because the caches they draw on haven't been calculated (`Schema.references_to`, `Schema.union_memberships`). If you're using these, please get in touch so that we can find a way forward.

### Migration Mode

You can use `use GraphQL::Schema::Visibility, ... migration_errors: true` to enable migration mode. In this mode, GraphQL-Ruby will make visibility checks with _both_ `Visibility` and `Warden` and compare the result, raising a descriptive error when the two systems return different results. As you migrate to `Visibility`, enable this mode in test to find any unexpected discrepancies.

Sometimes, there's a discrepancy that is hard to resolve but doesn't make any _real_ difference in application behavior. To address these cases, you can use these flags in `context`:

- `context[:visibility_migration_running] = true` is set in the main query context.
- `context[:visibility_migration_warden_running] = true` is set in the _duplicate_ context which is passed to a `Warden` instance.
- If you set `context[:skip_migration_error] = true`, then no migration error will be raised for that query.

You can use these flags to conditionally handle edge cases that should be ignored in testing.
