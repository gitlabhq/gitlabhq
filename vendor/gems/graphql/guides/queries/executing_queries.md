---
layout: guide
doc_stub: false
search: true
section: Queries
title: Executing Queries
desc: Evaluate GraphQL queries with your schema
index: 0
---


You can execute queries with your {{ "GraphQL::Schema" | api_doc }} and get a Ruby Hash as a result. For example, to execute a query from a string:

```ruby
query_string = "{ ... }"
MySchema.execute(query_string)
# {
#   "data" => { ... }
# }
```

Or, you can execute multiple queries at once:

```ruby
MySchema.multiplex([
  {query: query_string_1},
  {query: query_string_2},
  {query: query_string_3},
])
# [
#   { "data" => { ... } },
#   { "data" => { ... } },
#   { "data" => { ... } },
# ]
```

There are also several options you can use:

- `variables:` provides values for `$`-named [query variables](https://graphql.org/learn/queries/#variables)
- `context:` accepts application-specific data to pass to `resolve` functions
- `root_value:` will be provided to root-level `resolve` functions as `obj`
- `operation_name:` picks a [named operation](https://graphql.org/learn/queries/#operation-name) from the incoming string to execute
- `document:` accepts an already-parsed query (instead of a string), see {{ "GraphQL.parse" | api_doc }}
- `validate:` may be `false` to skip static validation for this query
- `max_depth:` and `max_complexity:` may override schema-level values

Some of these options are described in more detail below, see {{ "GraphQL::Query#initialize" | api_doc }} for more information.

## Variables

GraphQL provides [query variables](https://graphql.org/learn/queries/#variables) as a way to parameterize query strings. If your query string contains variables, you can provide values in a hash of `{ String => value }` pairs. The keys should _not_ contain `"$"`.

For example, to provide variables to a query:

```ruby
query_string = "
  query getPost($postId: ID!) {
    post(id: $postId) {
      title
    }
  }"

variables = { "postId" => "1" }

MySchema.execute(query_string, variables: variables)
```

If the variable is a {{ "GraphQL::InputObjectType" | api_doc }}, you can provide a nested hash, for example:

```ruby
query_string = "
mutation createPost($postParams: PostInput!, $createdById: ID!){
  createPost(params: $postParams, createdById: $createdById) {
    id
    title
    createdBy { name }
  }
}
"

variables = {
  "postParams" => {
    "title" => "...",
    "body" => "..."
  },
  "createdById" => "5",
}

MySchema.execute(query_string, variables: variables)
```

## Context

You can provide application-specific values to GraphQL as `context:`. This is available in many places:

- `resolve` functions
- `Schema#resolve_type` hook
- ID generation & fetching

Common uses for `context:` include the current user or auth token. To provide a `context:` value, pass a hash to `Schema#execute`:

```ruby
context = {
  current_user: session[:current_user],
  current_organization: session[:current_organization],
}

MySchema.execute(query_string, context: context)
```

Then, you can access those values during execution:

```ruby
field :post, Post do
  argument :id, ID
end

def post(id:)
  context[:current_user] # => #<User id=123 ... >
  # ...
end
```

Note that `context` is _not_ the hash that you passed it. It's an instance of {{ "GraphQL::Query::Context" | api_doc }}, but it delegates `#[]`, `#[]=`, and a few other methods to the hash you provide.

### Scoped Context

`context` is shared by the whole query. Anything you add to `context` will be accessible by any other field in the query (although GraphQL-Ruby's order of execution can vary).

However, "scoped context" can be used to assign values into `context` that are only available in the current field and the _children_ of the current field. For example, in this query:

```graphql
{
  posts {
    comments {
      author {
        isOriginalPoster
      }
    }
  }
}
```

You could use "scoped context" to implement `isOriginalPoster`, based on the parent `comments` field.

{% callout warning %}

Using scoped context may result in a violation of [the GraphQL specification](https://spec.graphql.org/draft/#sel-EABDLDFAACHAo3V) and
break normalized client stores, which assume that a given object always
has the same values for its fields.

See ["Referencing ancestors breaks normalized stores"](https://benjie.dev/graphql/ancestors#breaks-normalized-stores)
for details about this pitfall and alternative approaches which avoid it.

{% endcallout %}

In `def comments`, add `:current_post` to scoped context using `context.scoped_set!`:

```ruby
class Types::Post < Types::BaseObject
  # ...
  def comments
    context.scoped_set!(:current_post, object)
    object.comments
  end
end
```

Then, inside `User` (assuming `author` resolves to `Types::User`), you can check `context[:current_post]`:

```ruby
class Types::User < Types::BaseObject
  # ...
  def is_original_poster
    current_post = context[:current_post]
    current_post && current_post.author == object
  end
end
```

`context[:current_post]` will be present if an "upstream" field assigned it with `scoped_set!`.

`context.scoped_merge!({ ... })` is also available for setting multiple keys at once.

**Note**: With batched data loading (eg, GraphQL-Batch), scoped context might not work because of GraphQL-Ruby's control flow jumps from one field to the next. In that case, use `scoped_ctx = context.scoped` to grab a scoped context reference _before_ calling a loader, then used `scoped_ctx.set!` or `scoped_ctx.merge!` to modify scoped context inside the promise body. For example:

```ruby
# For use with GraphQL-Batch promises:
scoped_ctx = context.scoped
SomethingLoader.load(:something).then do |thing|
  scoped_ctx.set!(:thing_name, thing.name)
end
```

## Root Value

You can provide a root `object` value with `root_value:`. For example, to base the query off of the current organization:

```ruby
current_org = session[:current_organization]
MySchema.execute(query_string, root_value: current_org)
```

That value will be provided to root-level fields, such as mutation fields. For example:

```ruby
class Types::MutationType < GraphQL::Schema::Object
  field :create_post, Post

  def create_post(**args)
    object # => #<Organization id=456 ...>
    # ...
  end
end
```

{{ "GraphQL::Schema::Mutation" | api_doc }} fields will also receive `root_value:` as `obj` (assuming they're attached directly to your `MutationType`).
