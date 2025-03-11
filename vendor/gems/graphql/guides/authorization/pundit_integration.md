---
layout: guide
search: true
section: Authorization
title: Pundit Integration
desc: Hook up GraphQL to Pundit policies
index: 4
pro: true
---

[GraphQL::Pro](https://graphql.pro) includes an integration for powering GraphQL authorization with [Pundit](https://github.com/varvet/pundit) policies.

__Why bother?__ You _could_ put your authorization code in your GraphQL types themselves, but writing a separate authorization layer gives you a few advantages:

- Since the authorization code isn't embedded in GraphQL, you can use the same logic in non-GraphQL (or legacy) parts of the app.
- The authorization logic can be tested in isolation, so your end-to-end GraphQL tests don't have to cover as many possibilities.

## Getting Started

__NOTE__: Requires the latest gems, so make sure your `Gemfile` has:

```ruby
# For PunditIntegration:
gem "graphql-pro", ">=1.7.9"
# For list scoping:
gem "graphql", ">=1.8.7"
```

Then, `bundle install`.

Whenever you run queries, include `:current_user` in the context:

```ruby
context = {
  current_user: current_user,
  # ...
}
MySchema.execute(..., context: context)
```

### Rails Generator

If your schema files follow the same convention as `rails generate graphql:install`, then you can install the Pundit integration with a Rails generator:

```bash
$ rails generate graphql:pundit:install
```

This will insert all the necessary `include ...`s described below. Alternatively, check the docs below to mix in `PunditIntegration`'s modules.

## Authorizing Objects

You can specify Pundit roles that must be satisfied in order for viewers to see objects of a certain type. To get started, include the `ObjectIntegration` in your base object class:

```ruby
# app/graphql/types/base_object.rb
class Types::BaseObject < GraphQL::Schema::Object
  # Add the Pundit integration:
  include GraphQL::Pro::PunditIntegration::ObjectIntegration
  # By default, require staff:
  pundit_role :staff
  # Or, to require no permissions by default:
  # pundit_role nil
end
```

Now, anyone trying to read a GraphQL object will have to pass the `#staff?` check on that object's policy.

Then, each child class can override that parent configuration. For example, allow _all_ viewers to read the `Query` root:

```ruby
class Types::Query < Types::BaseObject
  # Allow anyone to see the query root
  pundit_role nil
end
```

#### Policies and Methods

For each object returned by GraphQL, the integration matches it to a policy and method.

The policy is found using [`Pundit.policy!`](https://www.rubydoc.info/gems/pundit/Pundit%2Epolicy!), which looks up a policy using the object's class name. (This can be customized, see below.)

Then, GraphQL will call a method on the policy to see whether the object is permitted or not. This method is assigned in the object class, for example:

```ruby
class Types::Employee < Types::BaseObject
  # Only show employee objects to their bosses,
  # or when that employee is the current viewer
  pundit_role :employer_or_self
  # ...
end
```

That configuration will call `#employer_or_self?` on the corresponding Pundit policy.

#### Custom Policy Class

By default, the integration uses `Pundit.policy!(current_user, object)` to find a policy. You can specify a policy class using `pundit_policy_class(...)`:

```ruby
class Types::Employee < Types::BaseObject
  pundit_policy_class(Policies::CustomEmployeePolicy)
  # Or, you could use a string:
  # pundit_policy_class("Policies::CustomEmployeePolicy")
end
```

For really custom policy lookup, see [Custom Policy Lookup](#custom-policy-lookup) below.

#### Bypassing Policies

The integration requires that every object with a `pundit_role` has a corresponding policy class. To allow objects to _skip_ authorization, you can pass `nil` as the role:

```ruby
class Types::PublicProfile < Types::BaseObject
  # Anyone can see this
  pundit_role nil
end
```

#### Handling Unauthorized Objects

When any Policy method returns `false`, the unauthorized object is passed to {{ "Schema.unauthorized_object" | api_doc }}, as described in {% internal_link "Handling unauthorized objects", "/authorization/authorization#handling-unauthorized-objects" %}.

## Scopes

The Pundit integration adds [Pundit scopes](https://github.com/varvet/pundit#scopes) to GraphQL-Ruby's {% internal_link "list scoping", "/authorization/scoping" %} feature. Any list or connection will be scoped. If a scope is missing, the query will crash rather than risk leaking unfiltered data.

To scope lists of interface or union type, include the integration in your base union class and base interface module:

```ruby
class BaseUnion < GraphQL::Schema::Union
  include GraphQL::Pro::PunditIntegration::UnionIntegration
end

module BaseInterface
  include GraphQL::Schema::Interface
  include GraphQL::Pro::PunditIntegration::InterfaceIntegration
end
```

#### Bypassing scopes

To allow an unscoped relation to be returned from a field, disable scoping with `scope: false`, for example:

```ruby
# Allow anyone to browse the job postings
field :job_postings, [Types::JobPosting], null: false,
  scope: false
```

## Authorizing Fields

You can also require certain checks on a field-by-field basis. First, include the integration in your base field class:

```ruby
# app/graphql/types/base_field.rb
class Types::BaseField < GraphQL::Schema::Field
  # Add the Pundit integration:
  include GraphQL::Pro::PunditIntegration::FieldIntegration
  # By default, don't require a role at field-level:
  pundit_role nil
end
```

If you haven't already done so, you should also hook up your base field class to your base object and base interface:

```ruby
# app/graphql/types/base_object.rb
class Types::BaseObject < GraphQL::Schema::Object
  field_class Types::BaseField
end
# app/graphql/types/base_interface.rb
module Types::BaseInterface
  # ...
  field_class Types::BaseField
end
# app/graphql/mutations/base_mutation.rb
class Mutations::BaseMutation < GraphQL::Schema::RelayClassicMutation
  field_class Types::BaseField
end
```

Then, you can add `pundit_role:` options to your fields:

```ruby
class Types::JobPosting < Types::BaseObject
  # Allow signed-in users to browse listings
  pundit_role :signed_in

  # But, only allow `JobPostingPolicy#staff?` users to see
  # who has applied
  field :applicants, [Types::User],
    pundit_role: :staff
end
```

It will call the named role (eg, `#staff?`) on the parent object's policy (eg `JobPostingPolicy`).

#### Custom Policy Class

You can override the policy class for a field using `pundit_policy_class:`, for example:

```ruby
class Types::JobPosting < Types::BaseObject
  # Only allow `ApplicantsPolicy#staff?` users to see
  # who has applied
  field :applicants, [Types::User],
    pundit_role: :staff,
    pundit_policy_class: ApplicantsPolicy
    # Or with a string:
    # pundit_policy_class: "ApplicantsPolicy"
end
```

This will initialize an `ApplicantsPolicy` with the parent object (a `Job`) and call `#staff?` on it.

For really custom policy lookup, see [Custom Policy Lookup](#custom-policy-lookup) below.

## Authorizing Arguments

Similar to field-level checks, you can require certain permissions to _use_ certain arguments. To do this, add the integration to your base argument class:

```ruby
class Types::BaseArgument < GraphQL::Schema::Argument
  # Include the integration and default to no permissions required
  include GraphQL::Pro::PunditIntegration::ArgumentIntegration
  pundit_role nil
end
```

Then, make sure your base argument is hooked up to your base field and base input object:

```ruby
class Types::BaseField < GraphQL::Schema::Field
  argument_class Types::BaseArgument
  # PS: see "Authorizing Fields" to make sure your base field is hooked up to objects, interfaces and mutations
end

class Types::BaseInputObject < GraphQL::Schema::InputObject
  argument_class Types::BaseArgument
end

class Mutations::BaseMutation < GraphQL::Schema::RelayClassicMutation
  argument_class Types::BaseArgument
end
```

Now, arguments accept a `pundit_role:` option, for example:

```ruby
class Types::Company < Types::BaseObject
  field :employees, Types::Employee.connection_type do
    # Only admins can filter employees by email:
    argument :email, String, required: false, pundit_role: :admin
  end
end
```

The role will be called on the parent object's policy, for example `CompanyPolicy#admin?` in the case above.

## Authorizing Mutations

There are a few ways to authorize GraphQL mutations with the Pundit integration:

- Add a [mutation-level roles](#mutation-level-roles)
- Run checks on [objects loaded by ID](#authorizing-loaded-objects)

Also, you can configure [unauthorized object handling](#unauthorized-mutations)

#### Setup

Add `MutationIntegration` to your base mutation, for example:

```ruby
class Mutations::BaseMutation < GraphQL::Schema::RelayClassicMutation
  include GraphQL::Pro::PunditIntegration::MutationIntegration

  # Also, to use argument-level authorization:
  argument_class Types::BaseArgument
end
```

Also, you'll probably want a `BaseMutationPayload` where you can set a default role:

```ruby
class Types::BaseMutationPayload < Types::BaseObject
  # If `BaseObject` requires some permissions, override that for mutation results.
  # Assume that anyone who can run a mutation can read their generated result types.
  pundit_role nil
end
```

And hook it up to your base mutation:

```ruby
class Mutations::BaseMutation < GraphQL::Schema::RelayClassicMutation
  object_class Types::BaseMutationPayload
  field_class Types::BaseField
end
```

#### Mutation-level roles

Each mutation can have a class-level `pundit_role` which will be checked before loading objects or resolving, for example:

```ruby
class Mutations::PromoteEmployee < Mutations::BaseMutation
  pundit_role :admin
end
```

In the example above, `PromoteEmployeePolicy#admin?` will be checked before running the mutation.

#### Custom Policy Class

By default, Pundit uses the mutation's class name to look up a policy. You can override this by defining `pundit_policy_class` on your mutation:

```ruby
class Mutations::PromoteEmployee < Mutations::BaseMutation
  pundit_policy_class ::UserPolicy
  pundit_role :admin
end
```

Now, the mutation will check `UserPolicy#admin?` before running.

For really custom policy lookup, see [Custom Policy Lookup](#custom-policy-lookup) below.

#### Authorizing Loaded Objects

Mutations can automatically load and authorize objects by ID using the `loads:` option.

Beyond the normal [object reading permissions](#authorizing-objects), you can add an additional role for the specific mutation input using a `pundit_role:` option:

```ruby
class Mutations::FireEmployee < Mutations::BaseMutation
  argument :employee_id, ID,
    loads: Types::Employee,
    pundit_role: :supervisor,
end
```

In the case above, the mutation will halt unless the `EmployeePolicy#supervisor?` method returns true.

#### Unauthorized Mutations

By default, an authorization failure in a mutation will raise a Ruby exception. You can customize this by implementing `#unauthorized_by_pundit(owner, value)` in your base mutation, for example:

```ruby
class Mutations::BaseMutation < GraphQL::Schema::RelayClassicMutation
  def unauthorized_by_pundit(owner, value)
    # No error, just return nil:
    nil
  end
end
```

The method is called with:

- `owner`: the `GraphQL::Schema::Argument` or mutation class whose role was not satisfied
- `value`: the object which didn't pass for `context[:current_user]`

Since it's a mutation method, you can also access `context` in that method.

Whatever that method returns will be treated as an early return value for the mutation, so for example, you could return {% internal_link "errors as data", "/mutations/mutation_errors" %}:

```ruby
class Mutations::BaseMutation < GraphQL::Schema::RelayClassicMutation
  field :errors, [String]

  def unauthorized_by_pundit(owner, value)
    # Return errors as data:
    { errors: ["Missing required permission: #{owner.pundit_role}, can't access #{value.inspect}"] }
  end
end
```

## Authorizing Resolvers

Resolvers are authorized just like [mutations](#authorizing-mutations), and require similar setup:

```ruby
# app/graphql/resolvers/base_resolver.rb
class Resolvers::BaseResolver < GraphQL::Schema::Resolver
  include GraphQL::Pro::PunditIntegration::ResolverIntegration
  argument_class BaseArgument
  # pundit_role nil # to disable authorization by default
end
```

Beyond that, see [Authorizing Mutations](#authorizing-mutations) above for further details.

## Custom Policy Lookup

By default, the integration uses `Pundit`'s top-level methods to interact with policies:

- `Pundit.policy!(context[:current_user], object)` is called to find a policy instance
- `Pundit.policy_scope!(context[:current_user], items)` is called to filter `items`

### Custom Policy Methods

You can implement a custom lookup by defining the following methods in your schema:

- `pundit_policy_class_for(object, context)` to return a policy class (or raise an error if one isn't found)
- `pundit_role_for(object, context)` to return a role method (Symbol), or `nil` to bypass authorization
- `scope_by_pundit_policy(context, items)` to apply a scope to `items` (or raise an error if one isn't found)

Since different objects have different lifecycles, the hooks are installed slightly different ways:

- Your base argument, field, and mutation classes should have _instance methods_ with those names
- Your base type classes should have _class methods_ with that name

Here's an example of how the custom hooks can be installed:

```ruby
module CustomPolicyLookup
  # Lookup policies in the `SystemAdmin::` namespace for system_admin users
  # @return [Class]
  def pundit_policy_class_for(object, context)
    current_user = context[:current_user]
    if current_user.system_admin?
      SystemAdmin.const_get("#{object.class.name}Policy")
    else
      super
    end
  end

  # Require admin permissions if the object is pending_approval
  def pundit_role_for(object, context)
    if object.pending_approval?
      :admin
    else
      super # fall back to the normally-configured role
    end
  end
end

# Add policy hooks as class methods
class Types::BaseObject < GraphQL::Schema::Object
  extend CustomPolicyLookup
end
class Types::BaseUnion < GraphQL::Schema::Union
  extend CustomPolicyLookup
end
module Types::BaseInterface
  include GraphQL::Schema::Interface
  # Add this as a class method that will be "inherited" by other interfaces:
  definition_methods do
    include CustomPolicyLookup
  end
end

# Add policy hooks as instance methods
class Types::BaseField < GraphQL::Schema::Field
  include CustomPolicyLookup
end
class Types::BaseArgument < GraphQL::Schema::Argument
  include CustomPolicyLookup
end
class Mutations::BaseMutation < GraphQL::Schema::RelayClassicMutation
  include CustomPolicyLookup
end
```

### One Policy Per Class

Another good approach is to have one policy per class. You can implement `policy_class_for(object, context)` to look up a policy _within_ the class, for example:

```ruby
class Mutations::BaseMutation < GraphQL::Schema::RelayClassicMutation
  def policy_class_for(_object, _context)
    # Look up a nested `Policy` constant:
    self.class.const_get(:Policy)
  end
end
```

Then, each mutation can define its policy inline, for example:

```ruby
class Mutations::PromoteEmployee < Mutations::BaseMutation
  # This will be found by `BaseMutation.policy_class`, defined above:
  class Policy
    # ...
  end

  pundit_role :admin
end
```

Now, `Mutations::PromoteEmployee::Policy#admin?` will be checked before running the mutation.

## Custom User Lookup

By default, the Pundit integration looks for the current user in `context[:current_user]`. You can override this by implementing `#pundit_user` on your custom query context class. For example:

```ruby
# app/graphql/query_context.rb
class QueryContext < GraphQL::Query::Context
  def pundit_user
    # Lookup `context[:viewer]` instead:
    self[:viewer]
  end
end
```

Then be sure to hook up your custom class in the schema:

```ruby
class MySchema < GraphQL::Schema
  context_class(QueryContext)
end
```

Then, the Pundit integration will use your `def pundit_user` to get the current user at runtime.
