---
layout: guide
doc_stub: false
search: true
section: Schema
title: Root Types
desc: Root types are the entry points for queries, mutations and subscriptions.
index: 2
---

GraphQL queries begin from [root types](https://graphql.org/learn/schema/#the-query-and-mutation-types): `query`, `mutation`, and `subscription`.

Attach these to your schema using methods with the same name:

```ruby
class MySchema < GraphQL::Schema
  # required
  query Types::QueryType
  # optional
  mutation Types::MutationType
  subscription Types::SubscriptionType
end
```

The types are `GraphQL::Schema::Object` classes, for example:

```ruby
# app/graphql/types/query_type.rb
class Types::QueryType < GraphQL::Schema::Object
  field :posts, [PostType], 'Returns all blog posts', null: false
end

# Similarly:
class Types::MutationType < GraphQL::Schema::Object
  field :create_post, mutation: Mutations::AddPost
end
# and
class Types::SubscriptionType < GraphQL::Schema::Object
  field :comment_added, subscription: Subscriptions::CommentAdded
end
```

Each type is the entry point for the corresponding GraphQL query:

```ruby
query Posts {
  # `Query.posts`
  posts { ... }
}

mutation AddPost($postAttrs: PostInput!){
  # `Mutation.createPost`
  createPost(attrs: $postAttrs)
}

subscription CommentAdded {
  # `Subscription.commentAdded`
  commentAdded(postId: 1)
}
```
