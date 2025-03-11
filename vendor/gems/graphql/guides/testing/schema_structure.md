---
layout: guide
doc_stub: false
search: true
section: Testing
title: Schema Structure
desc: Make sure that your schema changes are backwards-compatible
index: 1
---

Structural changes to a GraphQL schema come in two categories:

- __Breaking__ changes may cause previously-valid queries to become invalid. For example, if you remove the `title` field, anyone who tries to query that field will get a validation error instead of response data.
- __Non-breaking__ changes _add_ options to a schema without breaking previously-valid queries.

Making a _breaking_ change can be bad news for your API clients, since their applications may break. But, sometimes they're required. _Non-breaking_ changes don't affect existing queries, since they just _add_ new parts to the schema.

Here are few tips for managing schema structure changes.

## Maintain a `.graphql` schema dump

Make structure changes part of the normal code review process by adding a `schema.graphql` artifact to your project. This way, any changes to schema structure will show up clearly in a pull request as a diff to that file.

You can read about this approach in ["Tracking Schema Changes with GraphQL-Ruby"](https://rmosolgo.github.io/ruby/graphql/2017/03/16/tracking-schema-changes-with-graphql-ruby) or the built-in {{ "GraphQL::RakeTask" | api_doc }} for generating schema dumps.

## Automatically check for breaking changes

You can use [GraphQL::SchemaComparator](https://github.com/xuorig/graphql-schema_comparator) to check for breaking changes during development or CI. If you maintain a dump of queries that typically run against your server, you may also utilize `GraphQL::StaticValidation` to validate these queries directly. A Rake task such as the one below can be used to identify changes that are incompatible with existing queries.

```ruby
namespace :graphql do
  namespace :queries do
    desc 'Validates GraphQL queries against the current schema'
    task validate: [:environment] do
      queries_file = 'test/fixtures/files/queries.json'
      queries = Oj.load(File.read(queries_file))

      Validate.run_validate(queries, MySchema)
    end

    module Validate
      def self.run_validate(queries, schema)
        puts '⏳  Validating queries...'
        puts "\n"

        results = queries.map { |query| schema.validate(query) }
        errors = results.flatten

        if errors.empty?
          puts '✅  All queries are valid'
        else
          print_errors(errors)
        end
      end

      def self.print_errors(errors)
        puts 'Detected the following errors:'
        puts "\n"

        errors.each do |error|
          path = error.path.join(', ')
          puts "❌  #{path}: #{error.message}"
        end
      end
    end
  end
end
```
