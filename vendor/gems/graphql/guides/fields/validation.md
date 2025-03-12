---
layout: guide
doc_stub: false
search: true
section: Fields
title: Validation
desc: Rails-like validations for arguments
index: 3
---

Arguments can be validated at runtime using built-in or custom validators.

Validations are configured in `argument(...)` calls on fields or input objects:

```ruby
argument :home_phone, String,
  description: "A US phone number",
  validates: { format: { with: /\d{3}-\d{3}-\d{4}/ } }
```

or, `validates required: { ... }` inside a `field ... do ... end` block:

```ruby
field :comments, [Comment],
  description: "Find comments by author ID or author name" do
  argument :author_id, ID, required: false
  argument :author_name, String, required: false
  # Either `authorId` or `authorName` must be provided by the client, but not both:
  validates required: { one_of: [:author_id, :author_name] }
end
```

Validations can be provided with a keyword (`validates: { ... }`) or with a method inside the configuration block (`validates ...`).

## Built-In Validations

See each validator's API docs for details:

- `length: { maximum: ..., minimum: ..., is: ..., within: ... }` {{ "Schema::Validator::LengthValidator" | api_doc }}
- `format: { with: /.../, without: /.../ }` {{ "Schema::Validator::FormatValidator" | api_doc }}
- `numericality: { greater_than:, greater_than_or_equal_to:, less_than:, less_than_or_equal_to:, other_than:, odd:, even: }` {{ "Schema::Validator::NumericalityValidator" | api_doc }}
- `inclusion: { in: [...] }` {{ "Schema::Validator::InclusionValidator" | api_doc }}
- `exclusion: { in: [...] }` {{ "Schema::Validator::ExclusionValidator" | api_doc }}
- `required: { one_of: [...] }` {{ "Schema::Validator::RequiredValidator" | api_doc }}
- `allow_blank: true|false` {{  "Schema::Validator::AllowBlankValidator" | api_doc }}
- `allow_null: true|false` {{  "Schema::Validator::AllowNullValidator" | api_doc }}
- `all: { ... }` {{  "Schema::Validator::AllValidator" | api_doc }}

Some of the validators accept customizable messages for certain validation failures; see the API docs for examples.

`allow_blank:` and `allow_null:` may affect other validations, for example:

```ruby
validates: { format: { with: /\A\d{4}\Z/ }, allow_blank: true }
```

Will permit any String containing four digits, or the empty string (`""`) if Rails is loaded. (GraphQL-Ruby checks for `.blank?`, which is usually defined by Rails.)

Alternatively, they can be used alone, for example:

```ruby
argument :id, ID, required: false, validates: { allow_null: true }
```

Will reject any query that passes `id: null`.

## Custom Validators

You can write custom validators, too. A validator is a class that extends `GraphQL::Schema::Validator`. It should implement:

- `def initialize(..., **default_options)` to accept any validator-specific options and pass along the defaults to `super(**default_options)`
- `def validate(object, context, value)` which is called at runtime to validate `value`. It may return a String error message or an Array of Strings. GraphQL-Ruby will add those messages to the top-level `"errors"` array along with runtime context information.

Then, custom validators can be attached either:

- directly, passed to `validates`, like `validates: { MyCustomValidator => { some: :options }`
- by keyword, if the keyword is registered with `GraphQL::Schema::Validator.install(:custom, MyCustomValidator)`. (That would support `validates: { custom: { some: :options }})`.)

Validators are initialized when the schema is constructed (at application boot), and `validate(...)` is called while executing the query. There's one `Validator` instance for each configuration on each field, argument, or input object. (`Validator` instances aren't shared.)
