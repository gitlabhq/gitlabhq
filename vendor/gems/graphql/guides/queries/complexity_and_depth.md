---
title: Complexity & Depth
layout: guide
doc_stub: false
search: true
section: Queries
desc: Limiting query depth and field selections
index: 4
---

GraphQL-Ruby ships with some validations based on {% internal_link "query analysis", "/queries/ast_analysis" %}. You can customize them as-needed, too.

## Prevent deeply-nested queries

You can also reject queries based on the depth of their nesting. You can define `max_depth` at schema-level or query-level:

```ruby
# Schema-level:
class MySchema < GraphQL::Schema
  # ...
  max_depth 15
end

# Query-level, which overrides the schema-level setting:
MySchema.execute(query_string, max_depth: 20)
```

By default, **introspection fields are counted**. The default introspection query requires at least `max_depth 13`. You can also configure your schema not to count introspection fields with `max_depth ..., count_introspection_fields: false`.

You can use `nil` to disable the validation:

```ruby
# This query won't be validated:
MySchema.execute(query_string, max_depth: nil)
```

To get a feeling for depth of queries in your system, you can extend {{ "GraphQL::Analysis::QueryDepth" | api_doc }}. Hook it up to log out values from each query:

```ruby
class LogQueryDepth < GraphQL::Analysis::QueryDepth
  def result
    query_depth = super
    message = "[GraphQL Query Depth] #{query_depth} || staff?  #{query.context[:current_user].staff?}"
    Rails.logger.info(message)
  end
end

class MySchema < GraphQL::Schema
  query_analyzer(LogQueryDepth)
end
```

## Prevent complex queries

Fields have a "complexity" value which can be configured in their definition. It can be a constant (numeric) value, or a proc. If no `complexity` is defined for a field, it will default to a value of `1`. It can be defined as a keyword _or_ inside the configuration block. For example:

```ruby
# Constant complexity:
field :top_score, Integer, null: false, complexity: 10

# Dynamic complexity:
field :top_scorers, [PlayerType], null: false do
  argument :limit, Integer, limit: false, default_value: 5
  complexity ->(ctx, args, child_complexity) {
    if ctx[:current_user].staff?
      # no limit for staff users
      0
    else
      # `child_complexity` is the value for selections
      # which were made on the items of this list.
      #
      # We don't know how many items will be fetched because
      # we haven't run the query yet, but we can estimate by
      # using the `limit` argument which we defined above.
      args[:limit] * child_complexity
    end
  }
end
```

Then, define your `max_complexity` at the schema-level:

```ruby
class MySchema < GraphQL::Schema
  # ...
  max_complexity 100
end
```

Or, at the query-level, which overrides the schema-level setting:

```ruby
MySchema.execute(query_string, max_complexity: 100)
```

Using `nil` will disable the validation:

```ruby
# 😧 Anything goes!
MySchema.execute(query_string, max_complexity: nil)
```

To get a feeling for complexity of queries in your system, you can extend {{ "GraphQL::Analysis::QueryComplexity" | api_doc }}. Hook it up to log out values from each query:

```ruby
class LogQueryComplexityAnalyzer < GraphQL::Analysis::QueryComplexity
  # Override this method to _do something_ with the calculated complexity value
  def result
    complexity = super
    message = "[GraphQL Query Complexity] #{complexity} | staff? #{query.context[:current_user].staff?}"
    Rails.logger.info(message)
  end
end

class MySchema < GraphQL::Schema
  query_analyzer(LogQueryComplexityAnalyzer)
end
```

By default, **introspection fields are counted**. You can also configure your schema not to count introspection fields with `max_complexity ..., count_introspection_fields: false`.

#### Connection fields

By default, GraphQL-Ruby calculates a complexity value for connection fields by:

- adding `1` for `pageInfo` and each of its subselections
- adding `1` for `count`, `totalCount`, or `total`
- adding `1` for the connection field itself
- multiplying the complexity of other fields by the largest possible page size, which is the greater of `first:` or `last:`, or if neither of those are given it will go through each of `default_page_size`, the schema's `default_page_size`, `max_page_size`, and then the schema's `default_max_page_size`.

    (If no default page size or max page size can be determined, then the analysis crashes with an internal error -- set `default_page_size` or `default_max_page_size` in your schema to prevent this.)

For example, this query has complexity `26`:

```graphql
query {
  author {              # +1
    name                # +1
    books(first: 10) {  # +1
      nodes {           # +10 (+1, multiplied by `first:` above)
        title           # +10 (ditto)
      }
      pageInfo {        # +1
        endCursor       # +1
      }
      totalCount        # +1
    }
  }
}
```

To customize this behavior, implement `def calculate_complexity(query:, nodes:, child_complexity:)` in your base field class, handling the case where `self.connection?` is `true`:

```ruby
class Types::BaseField < GraphQL::Schema::Field
  def calculate_complexity(query:, nodes:, child_complexity:)
    if connection?
      # Custom connection calculation goes here
    else
      super
    end
  end
end
```

## How complexity scoring works

GraphQL Ruby's complexity scoring algorithm is biased towards selection fairness. While highly accurate, its results are not always intuitive. Here's an example query performed on the [Shopify Admin API](https://shopify.dev/docs/api/admin-graphql):

```graphql
query {
  node(id: "123") { # interface Node
    id
    ...on HasMetafields { # interface HasMetafields
      metafield(key: "a") {
        value
      }
      metafields(first: 10) {
        nodes {
          value
        }
      }
    }
    ...on Product { # implements HasMetafields
      title
      metafield(key: "a") {
        definition {
          description
        }
      }
    }
    ...on PriceList {
      name
      catalog {
        id
      }
    }
  }
}
```

First, GraphQL Ruby allows field definitions to specify a `complexity` attribute that provides a complexity score (or a proc that computes a score) for each field. Let's say that this schema defines a system where:

- Leaf fields cost `0`
- Composite fields cost `1`
- Connection fields cost `children * input size`

Given these parameters, we get an itemized scoring distribution of:

```graphql
query {
  node(id: "123") { # 1, composite
    id # 0, leaf
    ...on HasMetafields {
      metafield(key: "a") { # 1, composite
        value # 0, leaf
      }
      metafields(first: 10) { # 1 * 10, connection
        nodes { # 1, composite
          value # 0, leaf
        }
      }
    }
    ...on Product {
      title # 0, leaf
      metafield(key: "a") { # 1, composite
        definition { # 1, composite
          description # 0, leaf
        }
      }
    }
    ...on PriceList {
      name # 0, leaf
      catalog { # 1, composite
        id # 0, leaf
      }
    }
  }
}
```

However, we cannot naively tally these itemized scores without over-costing the query. Consider:

- The `node` scope makes many _possible_ selections on an abstract type, so we need the maximum among concrete possibilities for a fair representation.
- A `node.metafield` selection path is duplicated across the `HasMetafields` and `Product` selection scopes. This path will only resolve once, so should also only cost once.

To reconcile these possibilities, the [complexity algorithm](https://github.com/rmosolgo/graphql-ruby/blob/master/lib/graphql/analysis/ast/query_complexity.rb) breaks the selection down into a tree of types mapped to possible selections, across which lexical selections can be coalesced and deduplicated (pseudocode):

```ruby
{
  Schema::Query => {
    "node" => {
      Schema::Node => {
        "id" => nil,
      },
      Schema::HasMetafields => {
        "metafield" => {
          Schema::Metafield => {
            "value" => nil,
          },
        },
        "metafields" => {
          Schema::Metafield => {
            "nodes" => { ... },
          },
        },
      },
      Schema::Product => {
        "title" => nil,
        "metafield" => {
          Schema::Metafield => {
            "definition" => { ... },
          },
        },
      },
      Schema::PriceList => {
        "name" => nil,
        "catalog" => {
          Schema::Catalog => {
            "id" => nil,
          },
        },
      },
    },
  },
}
```

This aggregation provides a new perspective on the scoring where _possible typed selections_ have costs rather than individual fields. In this normalized view, `Product` acquires the `HasMetafields` interface costs, and ignores a duplicated path. Ultimately the maximum of possible typed costs is used, making this query cost `12`:

```graphql
query {
  node(id: "123") { # max(11, 12, 1) = 12
    id
    ...on HasMetafields { # 1 + 10 = 11
      metafield(key: "a") { # 1
        value
      }
      metafields(first: 10) { # 10
        nodes {
          value
        }
      }
    }
    ...on Product { # 1 + 11 from HasMetafields = 12
      title
      metafield(key: "a") { # duplicated in HasMetafields
        definition { # 1
          description
        }
      }
    }
    ...on PriceList { # 1 = 1
      name
      catalog { # 1
        id
      }
    }
  }
}
```
