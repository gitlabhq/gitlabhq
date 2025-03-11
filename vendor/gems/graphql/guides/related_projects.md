---
layout: guide
doc_stub: false
search: true
title: Related Projects
section: Other
desc: Code, blog posts and presentations about GraphQL Ruby
---

Want to add something? Please open a pull request [on GitHub](https://github.com/rmosolgo/graphql-ruby)!

## Code

- `graphql-ruby` + Rails demo ([src](https://github.com/rmosolgo/graphql-ruby-demo) / [heroku](https://graphql-ruby-demo.herokuapp.com))
- `graphql-ruby` + Sinatra demo ([src](https://github.com/robinjmurphy/ruby-graphql-server-example) / [heroku](https://ruby-graphql-server-example.herokuapp.com/))
- [`graphql-batch`](https://github.com/shopify/graphql-batch), a batched query execution strategy
- [`graphql-cache`](https://github.com/stackshareio/graphql-cache), a resolver-level caching solution
- [`graphql-devise`](https://github.com/graphql-devise/graphql_devise), a gql interface to handle authentication with Devise
- [`graphql-docs`](https://github.com/gjtorikian/graphql-docs), a tool to automatically generate static HTML documentation from your GraphQL implementation
- [`graphql-metrics`](https://github.com/Shopify/graphql-metrics), a plugin to extract fine-grain metrics of GraphQL queries received by your server
- [`graphql-stitching`](https://github.com/gmac/graphql-stitching-ruby), tools to combine multiple local and remote schemas into a single graph that queries as one
- [`graphql-groups`](https://github.com/hschne/graphql-groups), a DSL to define group- and aggregation queries with graphql-ruby
- Rails Helpers:
  - [`graphql-activerecord`](https://github.com/goco-inc/graphql-activerecord)
  - [`graphql-rails-resolve`](https://github.com/colepatrickturner/graphql-rails-resolver)
  - [`graphql-query-resolver`](https://github.com/nettofarah/graphql-query-resolver), a graphql-ruby add-on to minimize N+1 queries.
  - [`graphql-rails_logger`](https://github.com/jetruby/graphql-rails_logger), a logger which allows you to inspect GraphQL queries in a more readable format.
  - [`apollo_upload_server-ruby`](https://github.com/jetruby/apollo_upload_server-ruby), a middleware which allows you to upload files with GraphQL and multipart/form-data using [`apollo-upload-client`](https://github.com/jaydenseric/apollo-upload-client) library on front-end.
  - [`graphql-sources`](https://github.com/ksylvest/graphql-sources) a collection of common GraphQL [sources](https://graphql-ruby.org/dataloader/sources.html) to simplify using `ActiveRecord`, `ActiveStorage`, `Rails.cache`, and more.
  - [`graphql-filters`](https://github.com/moku-io/graphql-filters), a DSL to define fully typed filters for list fields.
- [`search_object_graphql`](https://github.com/rstankov/SearchObjectGraphQL), a DSL for defining search resolvers for GraphQL.
- [`action_policy-graphql`](https://github.com/palkan/action_policy-graphql), an integration for using [`action_policy`](https://github.com/palkan/action_policy) as an authorization framework for GraphQL applications.
- [`graphql_rails`](https://github.com/samesystem/graphql_rails), Rails way GraphQL build tool
- [`graphql-rails-generators`](https://github.com/ajsharp/graphql-rails-generators), Generate graphql-ruby mutations, types and input types from your ActiveRecord models.
- [`graphql-ruby-fragment_cache`](https://github.com/DmitryTsepelev/graphql-ruby-fragment_cache), a tool for caching response fragments.
- [`graphql-ruby-persisted_queries`](https://github.com/DmitryTsepelev/graphql-ruby-persisted_queries), the implementation of [Apollo persisted queries](https://github.com/apollographql/apollo-link-persisted-queries).
- [`rubocop-graphql`](https://github.com/DmitryTsepelev/rubocop-graphql), [rubocop](https://github.com/rubocop-hq/rubocop) extension for enforcing best practices.
- [`apollo-federation-ruby`](https://github.com/Gusto/apollo-federation-ruby), a Ruby implementation of the Apollo Federation [subgraph spec](https://www.apollographql.com/docs/federation/subgraph-spec/).

## Blog Posts

-  Building a blog in GraphQL and Relay on Rails [Introduction](https://medium.com/@gauravtiwari/graphql-and-relay-on-rails-getting-started-955a49d251de), [Part 1]( https://medium.com/@gauravtiwari/graphql-and-relay-on-rails-creating-types-and-schema-b3f9b232ccfc), [Part 2](https://medium.com/@gauravtiwari/graphql-and-relay-on-rails-first-relay-powered-react-component-cb3f9ee95eca)
- https://medium.com/@khor/relay-facebook-on-rails-8b4af2057152
- https://blog.jacobwgillespie.com/from-rest-to-graphql-b4e95e94c26b#.4cjtklrwt
- https://jonsimpson.ca/parallel-graphql-resolvers-with-futures/
- Active Storage meets GraphQL: [Direct uploads](https://evilmartians.com/chronicles/active-storage-meets-graphql-direct-uploads) and [Exposing attachment URLs](https://evilmartians.com/chronicles/active-storage-meets-graphql-pt-2-exposing-attachment-urls)
- [Exposing permissions in GraphQL APIs with Action Policy](https://evilmartians.com/chronicles/exposing-permissions-in-graphql-apis-with-action-policy)
- [Reporting non-nullable violations in graphql-ruby properly](https://evilmartians.com/chronicles/reporting-non-nullable-violations-in-graphql-ruby-properly)
- [How to GraphQL with Ruby, Rails, Active Record, and no N+1](https://evilmartians.com/chronicles/how-to-graphql-with-ruby-rails-active-record-and-no-n-plus-one)

## Screencasts

- [GraphQL Basics in Rails 5](https://rubyplus.com/episodes/271-GraphQL-Basics-in-Rails-5)

## Presentations
- [Rescuing Legacy Codebases with GraphQL](https://speakerdeck.com/nettofarah/rescuing-legacy-codebases-with-graphql-1) by [@nettofarah](https://twitter.com/nettofarah)

## Tutorials
- [How To GraphQL](https://www.howtographql.com/graphql-ruby/0-introduction/) by [@rstankov](https://github.com/rstankov)

- [GraphQL Ruby CRUD Tutorial](https://www.blook.pub/books/graphql-rails-tutorial) by [@kohheepeace](https://twitter.com/kohheepeace)

- Rails/GraphQL + React/Apollo Tutorial ([Part 1](https://evilmartians.com/chronicles/graphql-on-rails-1-from-zero-to-the-first-query), [Part 2](https://evilmartians.com/chronicles/graphql-on-rails-2-updating-the-data), [Part 3](https://evilmartians.com/chronicles/graphql-on-rails-3-on-the-way-to-perfection)) by [@evilmartians](https://twitter.com/evilmartians)
