---
layout: guide
doc_stub: false
search: true
title: Generators
section: Schema
desc: Use Rails generators to install GraphQL and scaffold new types.
index: 3
---

If you're using GraphQL with Ruby on Rails, you can use generators to:

- [setup GraphQL](#graphqlinstall), including [GraphiQL](https://github.com/graphql/graphiql), [GraphQL::Batch](https://github.com/Shopify/graphql-batch), and [Relay](https://facebook.github.io/relay/)
- [scaffold types](#scaffolding-types)
- [scaffold Relay mutations](#scaffolding-mutations)
- [scaffold ActiveRecord create/update/delete mutations](#scaffolding-activerecord-mutations)
- [scaffold GraphQL::Batch loaders](#scaffolding-loaders)

## graphql:install

You can add GraphQL to a Rails app with `graphql:install`:

```
rails generate graphql:install
```

This will:

- Set up a folder structure in `app/graphql/`
- Add schema definition
- Add base type classes
- Add a `Query` type definition
- Add a `Mutation` type definition with a base mutation class
- Add a route and controller for executing queries
- Install [`graphiql-rails`](https://github.com/rmosolgo/graphiql-rails)
- Enable [`ActiveRecord::QueryLogs`](https://api.rubyonrails.org/classes/ActiveRecord/QueryLogs.html) and add GraphQL-related metadata (using {{ "GraphQL::Current" | api_doc }})
After installing you can see your new schema by:

- `bundle install`
- `rails server`
- Open `localhost:3000/graphiql`

### Options

- `--directory=DIRECTORY` will directory where generated files should be saved (default is `app/graphql`)
- `--schema=MySchemaName` will be used for naming the schema (default is `#{app_name}Schema`)
- `--skip-graphiql` will exclude `graphiql-rails` from the setup
- `--skip-mutation-root-type` will not create of the mutation root type
- `--skip-query-logs` will skip the QueryLogs setup
- `--relay` will add [Relay](https://facebook.github.io/relay/)-specific code to your schema
- `--batch` will add [GraphQL::Batch](https://github.com/Shopify/graphql-batch) to your gemfile and include the setup in your schema
- `--playground` will include `graphql_playground-rails` in the setup (mounted at `/playground`)
- `--api` will create smaller stack for API only apps

## Scaffolding Types

Several generators will add GraphQL types to your project. Run them with `-h` to see the options:

- `rails g graphql:object`
- `rails g graphql:input`
- `rails g graphql:interface`
- `rails g graphql:union`
- `rails g graphql:enum`
- `rails g graphql:scalar`

### ActiveRecord columns auto-extraction

The `graphql:object` and `graphql:input` generators can detect the existence of an ActiveRecord class with the same name, and scaffold all database columns as fields/arguments using appropriate GraphQL types and nullability detection

### Options

- `--namespaced-types` will generate each one of the `object`/`input`/`interface`/... types under separate `Types::Objects::*`/`Types::Inputs::*`/`Types::Interfaces::*`/... namespaces and folders

## Scaffolding Mutations

You can prepare a Relay Classic mutation with

```
rails g graphql:mutation #{mutation_name}
```

## Scaffolding ActiveRecord Mutations

You can generate a Relay Classic create, update or delete mutation for a given model with

```
rails g graphql:mutation_create #{model_class_name}
rails g graphql:mutation_update #{model_class_name}
rails g graphql:mutation_delete #{model_class_name}
```

`model_class_name` accepts both `namespace/class_type` and `Namespace::ClassType` formats.
This mutation also accepts the `--namespaced-types` flag, to keep it consistent with the scaffolded Object and Input classes from the type generators

## Scaffolding Loaders

You can prepare a GraphQL::Batch loader with

```
rails g graphql:loader
```
