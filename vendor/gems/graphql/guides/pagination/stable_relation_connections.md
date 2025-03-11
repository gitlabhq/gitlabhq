---
layout: guide
doc_stub: false
search: true
section: Pagination
title: Stable Relation Connections
desc: Advanced pagination for ActiveRecord
index: 4
pro: true
---

`GraphQL::Pro` includes a mechanism for serving _stable_ connections for `ActiveRecord::Relation`s based on column values. If objects are created or destroyed during pagination, the list of items won't be disrupted.

These connection implementations are database-specific so that they can build proper queries with regard to `NULL` handling. (Postgres treats nulls as _larger_ than other values while MySQL and SQLite treat them as _smaller_ than other values.)

## What's the difference?

The default {{ "GraphQL::Pagination::ActiveRecordRelationConnection" | api_doc }} (which turns an `ActiveRecord::Relation` into a GraphQL-ready connection) uses _offset_ as a cursor. This naive approach is sufficient for many cases, but it's subject to a specific set of bugs.

Let's say you're looking at the second page of 10 items (`LIMIT 10 OFFSET 10`). During that time, one of the items on page 1 is deleted. When you navigate to page 3 (`LIMIT 10 OFFSET 20`), you'll actually _miss_ one item. The entire list shifted "up" one position when a previous item was deleted.

To solve this bug, we should use a _value_ to page through items (instead of _offset_). For example, if items are ordered by `id`, use the `id` for pagination:

```sql
LIMIT 10                      -- page 1
WHERE id > :last_id LIMIT 10  -- page 2
```

This way, even when items are added or removed, pagination will continue without interruption.

For more information about this issue, see ["Pagination: You're (Probably) Doing It Wrong"](https://coderwall.com/p/lkcaag/pagination-you-re-probably-doing-it-wrong).

## Installation

You can use a stable connection for _all_ `ActiveRecord::Relation`s by installing it at the schema level:

```ruby
class MyAppSchema < GraphQL::Schema
  # Hook up the stable connection that matches your database
  connections.add(ActiveRecord::Relation, GraphQL::Pro::PostgresStableRelationConnection)
  # Or...
  # connections.add(ActiveRecord::Relation, GraphQL::Pro::MySQLStableRelationConnection)
  # connections.add(ActiveRecord::Relation, GraphQL::Pro::SqliteStableRelationConnection)
end
```

Alternatively, you can apply the stable connection wrapper on a _field-by-field_ basis. For example:

```ruby
field :items, Types::ItemType.connection_type, null: false

def items
  # Build an ActiveRecord::Relation
  relation = Item.all
  # And wrap it with a connection implementation, then return the connection
  GraphQL::Pro::MySQLStableRelationConnection.new(relation)
end
```

That way, you can adopt stable cursors bit-by-bit. (See below for [backwards compatibility](#backwards-compatibility) notes.)

Similarly, if you enable stable connections for the whole schema, you can wrap _specific_ relations with `GraphQL::Pagination::ActiveRecordRelationConnection` when you want to use index-based cursors. (This is handy for relations whose ordering is too complicated for cursor generation.)

## Implementation Notes

Keep these points in mind when using value-based cursors:

- For a given `ActiveRecord::Relation`, only columns of that specific model can be used in pagination. (This is because column names are turned into `WHERE` conditions.)
- The connection may add an additional `primary_key` ordering to ensure that the cursor value is unique. This behavior is inspired by `Relation#reverse_order` which also assumes that `primary_key` is the default sort.
- The connection will add fields to the relation's `SELECT` clause, so that cursors can be reliably constructed from the database results.

## Grouped Relations

When using a grouped `ActiveRecord::Relation`, include a unique ID in your sort to ensure that each row in the result has a unique cursor. For example:

```ruby
# Bad: If two results have the same `max(price)`,
# they will be identical from a pagination perspective:
Products.select("max(price) as price").group("category_id").order("price")

# Good: `category_id` is used to disambiguate any results with the same price:
Products.select("max(price) as price").group("category_id").order("price, category_id")
```

For ungrouped relations, this issue is handled automatically by adding the model's `primary_key` to the order values.

If you provide an unordered, grouped relation, `GraphQL::Pro::RelationConnection::InvalidRelationError` will be raised because an unordered relation _cannot_ be paginated in a stable way.

## Backwards Compatibility

`GraphQL::Pro`'s stable relation connection is backwards-compatible. If it receives an offset-based cursor, it uses that cursor for the next resolution, then returns value-based cursors in the next result.

## ActiveRecord Versions

Stable relation connections support ActiveRecord `>= 4.1.0`.
