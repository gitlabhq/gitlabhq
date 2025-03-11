---
layout: guide
doc_stub: false
search: true
section: Type Definitions
title: Field Extensions
desc: Programmatically modify field configuration and resolution
index: 10
---

{{ "GraphQL::Schema::FieldExtension" | api_doc }} provides a way to modify user-defined fields in a programmatic way. For example, Relay connections are implemented as a field extension ({{ "GraphQL::Schema::Field::ConnectionExtension" | api_doc }}).

## Making a new extension

Field extensions are subclasses of {{ "GraphQL::Schema::FieldExtension" | api_doc }}:

```ruby
class MyExtension < GraphQL::Schema::FieldExtension
end
```

## Using an extension

Defined extensions can be added to fields using the `extensions: [...]` option or the `extension(...)` method:

```ruby
field :name, String, null: false, extensions: [UpcaseExtension]
# or:
field :description, String, null: false do
  extension(UpcaseExtension)
end
```

See below for how extensions may modify fields.

## Modifying field configuration

When extensions are attached, they are initialized with a `field:` and `options:`. Then, `#apply` is called, when they may extend the field they're attached to. For example:

```ruby
class SearchableExtension < GraphQL::Schema::FieldExtension
  def apply
    # add an argument to this field:
    field.argument(:query, String, required: false, description: "A search query")
  end
end
```

This way, an extension can encapsulate a behavior requiring several configuration options.

## Adding default argument configurations

Extensions may provide _default_ argument configurations which are applied if the field doesn't define the argument for itself. The configuration is passed to {{ "Schema::FieldExtension.default_argument" | api_doc }}. For example, to define a `:query` argument if the field doesn't already have one:

```ruby
class SearchableExtension < GraphQL::Schema::FieldExtension
  # Any field which uses this extension and _doesn't_ define
  # its own `:query` argument will get an argument configured with this:
  default_argument(:query, String, required: false, description: "A search query")
end
```

Additionally, extensions may implement `def after_define` which is called _after_ the field's `do .. . end` block. This is helpful when an extension should provide _default_ configurations without overriding anything in the field definition. (When extensions are added by calling `field.extension(...)` on an already-defined field `def after_define` is called immediately.)

## Modifying field execution

Extensions have two hooks that wrap field resolution. Since GraphQL-Ruby supports deferred execution, these hooks _might not_ be called back-to-back.

First, {{ "GraphQL::Schema::FieldExtension#resolve" | api_doc }} is called. `resolve` should `yield(object, arguments)` to continue execution. If it doesn't `yield`, then the underlying field won't be called. Whatever `#resolve` returns will be used for continuing execution.

After resolution and _after_ syncing lazy values (like `Promise`s from `graphql-batch`), {{ "GraphQL::Schema::FieldExtension#after_resolve" | api_doc }} is called. Whatever that method returns will be used as the field's return value.

See the linked API docs for the parameters of those methods.

### Execution "memo"

One parameter to `after_resolve` deserves special attention: `memo:`. `resolve` _may_ yield a third value. For example:

```ruby
def resolve(object:, arguments:, **rest)
  # yield the current time as `memo`
  yield(object, arguments, Time.now.to_i)
end
```

If a third value is yielded, it will be passed to `after_resolve` as `memo:`, for example:

```ruby
def after_resolve(value:, memo:, **rest)
  puts "Elapsed: #{Time.now.to_i - memo}"
  # Return the original value
  value
end
```

This allows the `resolve` hook to pass data to `after_resolve`.

Instance variables may not be used because, in a given GraphQL query, the same field may be resolved several times concurrently, and that would result in overriding the instance variable in an unpredictable way. (In fact, extensions are frozen to prevent instance variable writes.)

## Extension options

The `extension(...)` method takes an optional second argument, for example:

```ruby
extension(LimitExtension, limit: 20)
```

In this case, `{limit: 20}` will be passed as `options:` to `#initialize` and `options[:limit]` will be `20`.

For example, options can be used for modifying execution:

```ruby
def after_resolve(value:, **rest)
  # Apply the limit from the options, a readable attribute on the class
  value.limit(options[:limit])
end
```

If you use the `extensions: [...]` option, you can pass options using a hash:

```ruby
field :name, String, null: false, extensions: [LimitExtension => { limit: 20 }]
```

## Using `extras`

Extensions can have the same `extras` as fields (see {% internal_link "Extra Field Metadata", "fields/introduction#extra-field-metadata" %}). Add them by calling `extras` in the class definition:

```ruby
class MyExtension < GraphQL::Schema::FieldExtension
  extras [:ast_node, :errors, ...]
end
```

Any configured `extras` will be present in the given `arguments`, but removed before the field is resolved. (However, `extras` from _any_ extension will be present in `arguments` for _all_ extensions.)

## Adding an extension by default

If you want to apply an extension to _all_ your fields, you can do this in your {% internal_link "BaseField", "/type_definitions/extensions.html#customizing-fields" %}'s `def initialize`, for example:

```ruby
class Types::BaseField < GraphQL::Schema::Field
  def initialize(*args, **kwargs, &block)
    super
    # Add this to all fields based on this class:
    extension(MyDefaultExtension)
  end
end
```

You can also _conditionally_ apply extensions in `def initialize` by adding keywords to the method definition, for example:

```ruby
class Types::BaseField < GraphQL::Schema::Field
  # @param custom_extension [Boolean] if false, `MyCustomExtension` won't be added
  # @example skipping `MyCustomExtension`
  #   field :no_extension, String, custom_extension: false
  def initialize(*args, custom_extension: true, **kwargs, &block)
    super(*args, **kwargs, &block)
    # Don't apply this extension if the field is configured with `custom_extension: false`:
    if custom_extension
      extension(MyCustomExtensions)
    end
  end
end
```
