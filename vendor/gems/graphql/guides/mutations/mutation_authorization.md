---
layout: guide
doc_stub: false
search: true
section: Mutations
title: Mutation authorization
desc: Checking permissions for mutations
index: 3
---

Before running a mutation, you probably want to do a few things:

- Make sure the current user has permission to try this mutation
- Load some objects from the database, using some `ID` inputs
- Check if the user has permission to modify those loaded objects

This guide describes how to accomplish that workflow with GraphQL-Ruby.

## Checking conditions before instantiating the mutation

```ruby
class UpdateUserMutation < BaseMutation
  # ...

  def resolve(update_user_input:, user:)
    # ...
  end

  def self.authorized?(obj, ctx)
    super && ctx[:viewer].present?
  end
end
```

## Checking the user permissions

Before loading any data from the database, you might want to see if the user has a certain permission level. For example, maybe only `.admin?` users can run `Mutation.promoteEmployee`.

This check can be implemented using the `#ready?` method in a mutation:

```ruby
class Mutations::PromoteEmployee < Mutations::BaseMutation
  def ready?(**args)
    # Called with mutation args.
    # Use keyword args such as employee_id: or **args to collect them
    if !context[:current_user].admin?
      raise GraphQL::ExecutionError, "Only admins can run this mutation"
    else
      # Return true to continue the mutation:
      true
    end
  end

  # ...
end
```

Now, when any non-`admin` user tries to run the mutation, it won't run. Instead, they'll get an error in the response.

Additionally, `#ready?` may return `false, { ... }` to return {% internal_link "errors as data", "/mutations/mutation_errors" %}:

```ruby
def ready?
  if !context[:current_user].allowed?
    return false, { errors: ["You don't have permission to do this"]}
  else
    true
  end
end
```

## Loading and authorizing objects

Often, mutations take `ID`s as input and use them to load records from the database. GraphQL-Ruby can load IDs for you when you provide a `loads:` option.

In short, here's an example:


```ruby
class Mutations::PromoteEmployee < Mutations::BaseMutation
  # `employeeId` is an ID, Types::Employee is an _Object_ type
  argument :employee_id, ID, loads: Types::Employee

  # Behind the scenes, `:employee_id` is used to fetch an object from the database,
  # then the object is authorized with `Employee.authorized?`, then
  # if all is well, the object is injected here:
  def resolve(employee:)
    employee.promote!
  end
end
```

It works like this: if you pass a `loads:` option, it will:

- Automatically remove `_id` from the name and pass that name for the `as:` option
- Add a prepare hook to fetch an object with the given `ID` (using {{ "Schema.object_from_id" | api_doc }})
- Check that the fetched object's type matches the `loads:` type (using {{ "Schema.resolve_type" | api_doc }})
- Run the fetched object through its type's `.authorized?` hook (see {% internal_link "Authorization", "/authorization/authorization" %})
- Inject it into `#resolve` using the object-style name (`employee:`)

In this case, if the argument value is provided by `object_from_id` doesn't return a value, the mutation will fail with an error.

Alternatively if your `ID` doesn't specify both class _and_ id, resolvers have a `load_#{argument}` method that can be overridden.

```ruby
argument :employee_id, ID, loads: Types::Employee

def load_employee(id)
  ::Employee.find(id)
end
```

If you don't want this behavior, don't use it. Instead, create arguments with type `ID` and use them your own way, for example:

```ruby
# No special loading behavior:
argument :employee_id, ID
```

## Can _this user_ perform _this action_?

Sometimes you need to authorize a specific user-object(s)-action combination. For example, `.admin?` users can't promote _all_ employees! They can only promote employees which they manage.

You can add this check by implementing a `#authorized?` method, for example:

```ruby
def authorized?(employee:)
  super && context[:current_user].manager_of?(employee)
end
```

When `#authorized?` returns `false` (or something falsey), the mutation will be halted. If it returns `true` (or something truthy), the mutation will continue.

#### Adding errors

To add errors as data (as described in {% internal_link "Mutation errors", "/mutations/mutation_errors" %}), return a value _along with_ `false`, for example:

```ruby
def authorized?(employee:)
  super && if context[:current_user].manager_of?(employee)
    true
  else
    return false, { errors: ["Can't promote an employee you don't manage"] }
  end
end
```

Alternatively, you can add top-level errors by raising `GraphQL::ExecutionError`, for example:

```ruby
def authorized?(employee:)
  super && if context[:current_user].manager_of?(employee)
    true
  else
    raise GraphQL::ExecutionError, "You can only promote your _own_ employees"
  end
end
```

In either case (returning `[false, data]` or raising an error), the mutation will be halted.

## Finally, doing the work

Now that the user has been authorized in general, data has been loaded, and objects have been validated in particular, you can modify the database using `#resolve`:

```ruby
def resolve(employee:)
  if employee.promote
    {
      employee: employee,
      errors: [],
    }
  else
    # See "Mutation Errors" for more:
    {
      errors: employee.errors.full_messages
    }
  end
end
```
