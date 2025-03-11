---
layout: guide
doc_stub: false
search: true
section: Mutations
title: Mutation errors
desc: Tips for handling and returning errors from mutations
index: 2
---

How can you handle errors inside mutations? Let's explore a couple of options.

## Raising Errors

One way to handle an error is by raising, for example:

```ruby
def resolve(id:, attributes:)
  # Will crash the query if the data is invalid:
  Post.find(id).update!(attributes.to_h)
  # ...
end
```

Or:

```ruby
def resolve(id:, attributes:)
  if post.update(attributes)
    { post: post }
  else
    raise GraphQL::ExecutionError, post.errors.full_messages.join(", ")
  end
end
```

This kind of error handling _does_ express error state (either via `HTTP 500` or by the top-level `"errors"` key), but it doesn't take advantage of GraphQL's type system and can only express one error at a time. It works, but a stronger solution is to treat errors as data.

## Errors as Data

Another way to handle rich error information is to add _error types_ to your schema, for example:

```ruby
class Types::UserError < Types::BaseObject
  description "A user-readable error"

  field :message, String, null: false,
    description: "A description of the error"
  field :path, [String],
    description: "Which input value this error came from"
end
```

Then, add a field to your mutation which uses this error type:

```ruby
class Mutations::UpdatePost < Mutations::BaseMutation
  # ...
  field :errors, [Types::UserError], null: false
end
```

And in the mutation's `resolve` method, be sure to return `errors:` in the hash:

```ruby
def resolve(id:, attributes:)
  post = Post.find(id)
  if post.update(attributes)
    {
      post: post,
      errors: [],
    }
  else
    # Convert Rails model errors into GraphQL-ready error hashes
    user_errors = post.errors.map do |error|
      # This is the GraphQL argument which corresponds to the validation error:
      path = ["attributes", error.attribute.to_s.camelize(:lower)]
      {
        path: path,
        message: error.message,
      }
    end
    {
      post: post,
      errors: user_errors,
    }
  end
end
```

Now that the field returns `errors` in its payload, it supports `errors` as part of the incoming mutations, for example:

```graphql
mutation($postId: ID!, $postAttributes: PostAttributes!) {
  updatePost(id: $postId, attributes: $postAttributes) {
    # This will be present in case of success or failure:
    post {
      title
      comments {
        body
      }
    }
    # In case of failure, there will be errors in this list:
    errors {
      path
      message
    }
  }
}
```

In case of a failure, you might get a response like:

```ruby
{
  "data" => {
    "createPost" => {
      "post" => nil,
      "errors" => [
        { "message" => "Title can't be blank", "path" => ["attributes", "title"] },
        { "message" => "Body can't be blank", "path" => ["attributes", "body"] }
      ]
    }
  }
}
```

Then, client apps can show the error messages to end users, so they might correct the right fields in a form, for example.

## Nullable Mutation Payload Fields

To benefit from "Errors as Data" described above, mutation fields must not have `null: false`. Why?

Well, for _non-null_ fields (which have `null: false`), if they return `nil`, then GraphQL aborts the query and removes those fields from the response altogether.

In mutations, when errors happen, the other fields may return `nil`. So, if those other fields have `null: false`, but they return `nil`, the GraphQL will panic and remove the whole mutation from the response, _including_ the errors!

In order to have the rich error data, even when other fields are `nil`, those fields must have `null: true` (which is the default) so that the type system can be obeyed when errors happen.

Here's an example of a nullable field (good!):

```ruby
class Mutations::UpdatePost < Mutations::BaseMutation
  # Use the default `null: true` to support rich errors:
  field :post, Types::Post
  # ...
end
```
