---
layout: guide
doc_stub: false
search: true
enterprise: true
section: GraphQL Enterprise - Changesets
title: Installing Changesets
desc: Adding Changesets to your schema
index: 1
---

Changesets require some updates to the schema (to define changesets) and some updates to your controller (to receive version headers from clients).

## Schema Setup

To get started with [GraphQL-Enterprise](https://graphql.pro/enterprise) Changesets, you have to add them to your schema. They're added in several places:

- To support versioning arguments, add the `ArgumentIntegration` to your base argument:

    ```ruby
    # app/graphql/types/base_argument.rb
    class Types::BaseArgument < GraphQL::Schema::Argument
      include GraphQL::Enterprise::Changeset::ArgumentIntegration
    end
    ```

    Also, make sure that your `BaseField`, `BaseInputObject`, `BaseResolver`, and `BaseMutation` have `argument_class(Types::BaseArgument)` configured in them.

- To support versioning fields, add the `FieldIntegration` to your base field:

    ```ruby
    # app/graphql/types/base_field.rb
    class Types::BaseField < GraphQL::Schema::Field
      include GraphQL::Enterprise::Changeset::FieldIntegration
      argument_class(Types::BaseArgument)
    end
    ```

    Also, make sure that your `BaseObject`, `BaseInterface`, and `BaseMutation` have `field_class(Types::BaseField)` configured in them.

- To support versioning enum values, add the `EnumValueIntegration` to your base enum value:

    ```ruby
    # app/graphql/types/base_enum_value.rb
    class Types::BaseEnumValue < GraphQL::Schema::EnumValue
      include GraphQL::Enterprise::Changeset::EnumValueIntegration
    end
    ```

    Also, make sure that your `BaseEnum` has `enum_value_class(Types::BaseEnumValue)` configured in it.

- To support versioning union memberships and interface implementations, add the `TypeMembershipIntegration` to your base type membership:

    ```ruby
    # app/graphql/types/base_type_membership.rb
    class Types::BaseTypeMembership < GraphQL::Schema::TypeMembership
      include GraphQL::Enterprise::Changeset::TypeMembershipIntegration
    end
    ```

    Also, make sure that your `BaseUnion` and `BaseInterface` have `type_membership_class(Types::BaseTypeMembership)` configured in it. (`TypeMembership`s are used by GraphQL-Ruby to link object types to the union types they belong to and the interfaces they implement. By using a custom type membership class, you can make objects belong (or _not_ belong) to unions or interfaces, depending on the API version.)

Once those integrations are set up, you're ready to {% internal_link "write a changeset", "/changesets/definition" %} and start {% internal_link "releasing API versions", "/changesets/releases" %}!

## Controller Setup

Additionally, your controller must pass `context[:changeset_version]` when running queries. To provide this, update your controller:

```ruby
class GraphqlController < ApplicationController
  def execute
    context = {
      # ...
      changeset_version: headers["API-Version"], # <- Your header here. Choose something for API clients to pass.
    }
    result = MyAppSchema.execute(..., context: context)
    # ...
  end
end
```

In the example above, `API-Version: ...` will be parsed from the incoming request and used as `context[:changeset_version]`.

If `context[:changeset_version]` is `nil`, then _no_ changesets will apply to that request.

Now that Changesets are installed, read on to {% internal_link "define some changesets", "/changesets/definition" %}.
