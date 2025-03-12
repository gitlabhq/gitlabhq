---
layout: guide
doc_stub: false
search: true
section: Testing
title: Helpers
desc: Running GraphQL fields in isolation
index: 3
---

GraphQL-Ruby ships with a test helper method, `run_graphql_field`, that can execute a GraphQL field in isolation. To use it in your test suite, include the module with your schema class:

```ruby
# Mix in `run_graphql_field(...)` to run on `MySchema`
include GraphQL::Testing::Helpers.for(MySchema)
```

Then, you can run fields using {{ "Testing::Helpers#run_graphql_field" | api_doc }}:

```ruby
post = Post.first
graphql_post_title = run_graphql_field("Post.title", post)
assert_equal "100 Great Ideas", graphql_post_title
```

`run_graphql_field` accepts two required arguments:

- Field _path_, in `Type.field` format
- Runtime object: some non-`nil` object to resolve the field on.

Additionally, it accepts some keyword arguments:

- `arguments:`, GraphQL arguments to the field, in Ruby-style (underscore, symbol) or GraphQL-style (camel-case, string)
- `context:`, the GraphQL context to use for this query

`run_graphql_field` performs several GraphQL-related steps:

- Checks `.visible?` on the named Object Type, raising an error if it isn't visible
- Wraps the given runtime object in the GraphQL Object Type
- Checks `.authorized?` on the type, calling {{ "Schema.unauthorized_object" | api_doc }} if authorization fails
- Prepares arguments for field resolution
- Checks `#visible?` on the field, raising an error if the field isn't visible
- Checks `#authorized?` on the field, calling {{ "Schema.unauthorized_field" | api_doc }} if it fails
- Calls any {% internal_link "field extensions", "/type_definitions/field_extensions" %}
- Runs {% internal_link "Dataloader", "/dataloader/overview" %} and/or GraphQL-Batch, as needed

## Resolving fields on the same object

You can use {{ "Testing::Helpers#with_resolution_context" | api_doc }} to use the same type, runtime object, and GraphQL context for multiple field resolutions. For example:

```ruby
# Assuming `include GraphQL::Testing::Helpers.for(MySchema)`
# was used above ...
with_resolution_context(type: "Post", object: example_post, context: { current_user: author }) do |rc|
  assert_equal "100 Great Ideas", rc.run_graphql_field("title")
  assert_equal true, rc.run_graphql_field("viewerIsAuthor")
  assert_equal 5, rc.run_graphql_field("commentsCount")
  # Optionally, pass `arguments:` for the field:
  assert_equal 9, rc.run_graphql_field("commentsCount", arguments: { include_unmoderated: true })
end
```

The method yields a resolution context (`rc`, above) which responds to `run_graphql_field`.
