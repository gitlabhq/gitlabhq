---
layout: guide
doc_stub: false
search: true
section: GraphQL Pro - OperationStore
title: Server Management
desc: Tips for administering persisted queries with OperationStore
index: 5
pro: true
---

After {% internal_link "getting started","/operation_store/getting_started" %}, here some things to keep in mind.

## Rejecting Arbitrary Queries

With persisted queries, you can stop accepting arbitrary GraphQL input. This way, malicious users can't run large or inappropriate queries on your server.

In short, you can ignore arbitrary GraphQL by _skipping_ the first argument of `MySchema.execute`:

```ruby
# app/controllers/graphql.rb

# Don't pass a query string; ignore `params[:query]`
MySchema.execute(
  context: context,
  variables: params[:variables],
  operation_name: params[:operationName],
)
```

However, take these points into consideration:

- Are any previous clients using arbitrary GraphQL? (For example, old versions of native apps or old web pages may still be sending GraphQL.)
- Should some users still be allowed to send custom strings? (For example, do staff members use GraphiQL to develop new features or debug issues?)

If those apply to you, you can apply some logic to `query_string`:

```ruby
# Allow arbitrary GraphQL:
# - from staff users
# - in development
query_string = if current_user.staff? || Rails.env.development?
  params[:query]
else
  nil
end

MySchema.execute(
  query_string, # maybe nil, that's OK.
  context: context,
  variables: params[:variables],
  operation_name: params[:operationName],
)
```

## Archiving and Deleting Data

Clients can only _add_ to the database, but as an administrator, you can also archive or delete entries from the database. (Make sure you {% internal_link "authorize access to the Dashboard","/pro/dashboard" %}.) This is a dangerous operation: by archiving or deleting something, any clients who depend on that data will crash.

Some reasons to archive or delete from the database are:

- Data was pushed in error; the data is not used
- The queries are invalid or unsafe; it's better to remove them than to keep them

If this is true, you can use "Archive" or "Delete" buttons to remove things from production.

When an operation is archived, it's no longer available to clients, but it's still in the database. It can be unarchived later, so this is lower-risk than full deletion.

## Integration with Your Application

It's on the road map to add a Ruby API to `OperationStore` so that you can integrate it with your application. For example, you might:

- Create clients that correspond to users in your system
- Show client secrets via the Dashboard so that users can save them
- Render your own administration dashboards with `OperationStore` data

If this interests you, please {% open_an_issue "OperationStore Ruby API" %} or email `support@graphql.pro`.
