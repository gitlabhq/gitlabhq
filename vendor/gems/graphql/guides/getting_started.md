---
layout: guide
doc_stub: false
search: true
title: Getting Started
section: Other
desc: Start here!
---

## Installation

You can install `graphql` from RubyGems by adding to your application's `Gemfile`:

```ruby
# Gemfile
gem "graphql"
```

Then, running `bundle install`:

```sh
$ bundle install
```

## Getting Started

On Rails, you can get started with a few [GraphQL generators](https://rmosolgo.github.io/graphql-ruby/schema/generators#graphqlinstall):

```sh
# Add graphql-ruby boilerplate and mount graphiql in development
$ rails g graphql:install
# You may need to run bundle install again, as by default graphiql-rails is added on installation.
$ bundle install
# Make your first object type
$ rails g graphql:object Post title:String rating:Int comments:[Comment]
```

Or, you can build a GraphQL server by hand:

- Define some types
- Connect them to a schema
- Execute queries with your schema

### Declare types

Types describe objects in your application and form the basis for [GraphQL's type system](https://graphql.org/learn/schema/#type-system).

```ruby
# app/graphql/types/post_type.rb
module Types
  class PostType < Types::BaseObject
    description "A blog post"
    field :id, ID, null: false
    field :title, String, null: false
    # fields should be queried in camel-case (this will be `truncatedPreview`)
    field :truncated_preview, String, null: false
    # Fields can return lists of other objects:
    field :comments, [Types::CommentType],
      # And fields can have their own descriptions:
      description: "This post's comments, or null if this post has comments disabled."
  end
end

# app/graphql/types/comment_type.rb
module Types
  class CommentType < Types::BaseObject
    field :id, ID, null: false
    field :post, PostType, null: false
  end
end
```

### Build a Schema

Before building a schema, you have to define an [entry point to your system, the "query root"](https://graphql.org/learn/schema/#the-query-and-mutation-types):

```ruby
class QueryType < GraphQL::Schema::Object
  description "The query root of this schema"

  field :post, resolver: Resolvers::PostResolver
end
```

Define how this field is resolved by creating a resolver class:

```ruby
# app/graphql/resolvers/post_resolver.rb
module Resolvers
  class PostResolver < BaseResolver
    type Types::PostType, null: false
    argument :id, ID

    def resolve(id:)
      ::Post.find(id)
    end
  end
end
```

Then, build a schema with `QueryType` as the query entry point:

```ruby
class Schema < GraphQL::Schema
  query Types::QueryType
end
```

This schema is ready to serve GraphQL queries! {% internal_link "Browse the guides","/guides" %} to learn about other GraphQL Ruby features.

### Execute queries

You can execute queries from a query string:

```ruby
query_string = "
{
  post(id: 1) {
    id
    title
    truncatedPreview
  }
}"
result_hash = Schema.execute(query_string)
# {
#   "data" => {
#     "post" => {
#        "id" => 1,
#        "title" => "GraphQL is nice"
#        "truncatedPreview" => "GraphQL is..."
#     }
#   }
# }
```

See {% internal_link "Executing Queries","/queries/executing_queries" %} for more information about running queries on your schema.

## Use with Relay

If you're building a backend for [Relay](https://facebook.github.io/relay/), you'll need:

- A JSON dump of the schema, which you can get by sending [`GraphQL::Introspection::INTROSPECTION_QUERY`](https://github.com/rmosolgo/graphql-ruby/blob/master/lib/graphql/introspection/introspection_query.rb)
- Relay-specific helpers for GraphQL, see the {% internal_link "Connection guide", "/pagination/connection_concepts" %}, {% internal_link "Mutation guide", "mutations/mutation_classes" %}, and {% internal_link "Object Identification guide", "/schema/object_identification" %}.

## Use with Apollo Client

[Apollo Client](https://www.apollographql.com/) is a full featured, simple to use GraphQL client with convenient integrations for popular view layers. You don't need to do anything special to connect Apollo Client to a `graphql-ruby` server.

## Use with GraphQL.js Client

[GraphQL.js Client](https://github.com/f/graphql.js) is a tiny client that is platform- and framework-agnostic. It works well with `graphql-ruby` servers, since GraphQL requests are simple query strings transported over HTTP.
