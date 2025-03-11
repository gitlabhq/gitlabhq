---
layout: guide
doc_stub: false
search: true
section: Schema
title: Dynamic types and fields
desc: Using different schema members for each request
index: 8
---

You can use different versions of your GraphQL schema for each operation. To do this, add `use GraphQL::Schema::Visibility` and implement `visible?(context)` on the parts of your schema that will be conditionally accessible. Additionally, many schema elements have definition methods which are called at runtime by GraphQL-Ruby. You can re-implement those to return any valid schema objects.


GraphQL-Ruby caches schema elements for the duration of the operation, but if you're making external service calls to implement the methods below, consider adding a cache layer to improve the client experience and reduce load on your backend.

At runtime, ensure that only one object is visible per name (type name, field name, etc.). (If `.visible?(context)` returns `false`, then that part of the schema will be hidden for the current operation.)

When using dynamic schema members, be sure to include the relevant `context: ...` when [generating schema definition files](#schema-dumps).

## Different fields

You can customize which field definitions are used for each operation.

### Using `#visible?(context)`

To serve different fields to different clients, implement `def visible?(context)` in your {% internal_link "base field class", "/type_definitions/extensions#customizing-fields" %}:

```ruby
class Types::BaseField < GraphQL::Schema::Field
  def initialize(*args, for_staff: false, **kwargs, &block)
    super(*args, **kwargs, &block)
    @for_staff = for_staff
  end

  def visible?(context)
    super && case @for_staff
    when true
      !!context[:current_user]&.staff?
    when false
      !context[:current_user]&.staff?
    else
      true
    end
  end
end
```

Then, you can configure fields with `for_staff: true|false`:

```ruby
field :comments, Types::Comment.connection_type, null: false,
  description: "Comments on this blog post",
  resolver_method: :moderated_comments,
  for_staff: false

field :comments, Types::Comment.connection_type, null: false,
  description: "Comments on this blog post, including unmoderated comments",
  resolver_method: :all_comments,
  for_staff: true
```

With that configuration, `post { comments { ... } }` will use `def moderated_comments` when `context[:current_user]` is `nil` or is not `.staff?`, but when `context[:current_user].staff?` is `true`, it will use `def all_comments` instead.

### Using `.fields(context)` and `.get_field(name, context)`

To customize the set of fields used at runtime, you can implement `def self.fields(context)` in your type classes. It should return a Hash of `{ String => GraphQL::Schema::Field }`.

Along with this, you should implement `.get_field(name, context)` to return a field for `name`, if it should exist. For example:

```ruby
class Types::User < Types::BaseObject
  def self.fields(context)
    all_fields = super
    if !context[:current_user]&.staff?
      all_fields.delete("isSpammy") # this is staff-only
    end
    all_fields
  end

  def self.get_field(name, context)
    field = super
    if field.graphql_name == "isSpammy" && !context[:current_user]&.staff?
      nil # don't show this field to non-staff
    else
      field
    end
  end
end
```

### Hidden Return Types

Besides field visibility described above, if an field's return type is hidden (that is, it implements `self.visible?(context)` to return `false`), then the field will be hidden too.

## Different arguments

As with fields, you can use different sets of argument definitions for different GraphQL operations.

### Using `#visible?(context)`

To serve different arguments to different clients, implement `def visible?(context)` in your {% internal_link "base argument class", "/type_definitions/extensions#customizing-arguments" %}:

```ruby
class Types::BaseArgument < GraphQL::Schema::Argument
  def initialize(*args, for_staff: false, **kwargs, &block)
    super(*args, **kwargs, &block)
    @for_staff = for_staff
  end

  def visible?(context)
    super && case @for_staff
    when true
      !!context[:current_user]&.staff?
    when false
      !context[:current_user]&.staff?
    else
      true
    end
  end
end
```

Then, you can configure arguments with `for_staff: true|false`:

```ruby
field :user, Types::User, null: true, description: "Look up a user" do
  # Require a UUID-style ID from non-staff clients:
  argument :id, ID, required: true, for_staff: false
  # Support database primary key lookups for staff clients:
  argument :id, ID, required: false, for_staff: true
  argument :database_id, Int, required: false, for_staff: true
end

def user(id: nil, database_id: nil)
  # ...
end
```

That way, any staff client will have the option of `id` or `databaseId` while non-staff clients must use `id`.

### Using `def arguments(context)` and `def get_argument(name, context)`

Also, you can implement `def arguments(context)` on your base field class to return a Hash of `{ String => GraphQL::Schema::Argument }` and `def get_argument(name, context)` to return a {{ "GraphQL::Schema::Argument" | api_doc }} or `nil`. . If you take this approach, you might want some custom field classes for any types or resolvers that use these methods. That way, you don't have to reimplement the method for _all_ the fields in the schema.

### Hidden Input Types

Besides argument visibility described above, if an argument's input type is hidden (that is, it implements `self.visible?(context)` to return `false`), then the argument will be hidden too.

## Different enum values

### Using `#visible?(context)`

You can implement `def visible?(context)` in your {% internal_link "base enum value class", "/type_definitions/extensions#customizing-enum-values" %} to hide some enum values from some clients. For example:

```ruby
class BaseEnumValue < GraphQL::Schema::EnumValue
  def initialize(*args, for_staff: false, **kwargs, &block)
    super(*args, **kwargs, &block)
    @for_staff = for_staff
  end

  def visible?(context)
    super && case @for_staff
    when true
      !!context[:current_user]&.staff?
    when false
      !context[:current_user]&.staff?
    else
      true
    end
  end
end
```

With this base class, you can configure some enum values to be _just_ for staff or non-staff viewers:

```ruby
class AccountStatus < Types::BaseEnum
  value "ACTIVE"
  value "INACTIVE"
  # Use this for sensitive account statuses when the viewer is public:
  value "OTHER", for_staff: false
  # Staff-only sensitive account statuses:
  value "BANNED", for_staff: true
  value "PAYMENT_FAILED", for_staff: true
  value "PENDING_VERIFICATION", for_staff: true
end
```

### Using `.enum_values(context)`

Alternatively, you can implement `def self.enum_values(context)` in your enum types to return an Array of {{ "GraphQL::Schema::EnumValue" | api_doc }}s. For example, to return a dynamic set of enum values:

```ruby
class ProjectStatus < Types::BaseEnum
  def self.enum_values(context = {})
    # Fetch the values from the database
    status_names = context[:tenant].project_statuses.pluck("name")

    # Then build an Array of Enum values
    status_names.map do |name|
      # Be sure to include `owner: self`, the back-reference from the EnumValue to its parent Enum
      GraphQL::Schema::EnumValue.new(name, owner: self)
    end
  end
end
```

## Different types

You can also use different types for each query. A few behaviors depend on the methods defined above:

- If a type is not used as a return type, an argument type, or as a member of a union or implementer of an interface, it will be hidden
- If an interface or union has members, it will be hidden
- If a field's return type is hidden, the field will be hidden
- If an argument's input type is hidden, the argument will be hidden

As you can imagine, these different hiding behaviors influence one another and they can cause some real head-scratchers when used simultaneously.

### Using `.visible?(context)`

Type classes can implement `def self.visible?(context)` to hide themselves at runtime:

```ruby
class Types::BanReason < Types::BaseEnum
  # Hide any arguments or fields that use this enum
  # unless the current user is staff
  def self.visible?(context)
    super && !!context[:current_user]&.staff?
  end

  # ...
end
```

### Different definitions for the same type

You can provide different implementations of the same type by:

- Implementing `def self.visible?(context)` to return `true` and `false` in complementary contexts. (They should never both be `.visible? => true`).
- Hooking the types up to the schema with different field or argument definitions, as described above

For example, to migrate your `Money` scalar to a `Money` object type:

```ruby
# Previously, we used a simple string to describe money:
class Types::LegacyMoney < Types::BaseScalar
  # This graphql name will conflict with `Types::Money`,
  # so we have to be careful not to use them at the same time.
  # (GraphQL-Ruby will raise an error if it finds two definitions with the same name at runtime.)
  graphql_name "Money"
  describe "A string describing an amount of money."

  # Use this type definition if the current request
  # explicitly opted in to the legacy money representation:
  def self.visible?(context)
    !!context[:requests_legacy_money]
  end
end

# But we want to improve the client experience with a dedicated object type:
class Types::Money < Types::BaseObject
  field :amount, Integer, null: false
  field :currency, Types::Currency, null: false

  # Use this new definition if the client
  # didn't explicitly ask for the legacy definition:
  def self.visible?(context)
    !context[:requests_legacy_money]
  end
end
```

Then, hook the definitions up to the schema using field definitions:

```ruby
class Types::BaseField < GraphQL::Schema::Field
  def initialize(*args, legacy_money: false, **kwargs, &block)
    super(*args, **kwargs, &block)
    @legacy_money = legacy_money
  end

  def visible?(context)
    super && (@legacy_money ? !!context[:requests_legacy_money] : !context[:requests_legacy_money])
  end
end

class Types::Invoice < Types::BaseObject
  # Add one definition for each possible return type
  # (one definition will be hidden at runtime)
  field :amount, Types::LegacyMoney, null: false, legacy_money: true
  field :amount, Types::Money, null: false, legacy_money: false
end
```

Input types (like input objects, scalars, and enums) work the same way with argument definitions.

## Schema Dumps

To dump a certain _version_ of the schema, provide the applicable `context: ...` to {{ "Schema.to_definition" | api_doc }}. For example:

```ruby
# Legacy money schema:
MySchema.to_definition(context: { requests_legacy_money: true })
```

or

```ruby
# Staff-only schema:
MySchema.to_definition(context: { current_user: OpenStruct.new(staff?: true) })
```

That way, the given `context` will be passed to `visible?(context)` calls and other relevant methods.
