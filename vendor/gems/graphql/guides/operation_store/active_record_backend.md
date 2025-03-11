---
layout: guide
doc_stub: false
search: true
section: GraphQL Pro - OperationStore
title: ActiveRecord Backend
desc: Storing persisted queries with ActiveRecord
index: 2
pro: true
---

GraphQL-Pro's `OperationStore` can use ActiveRecord to store persisted queries. After setting up the database, it will read and write using those tables as needed.

## Database Setup

To use ActiveRecord, `GraphQL::Pro::OperationStore` requires some database tables.

### Rails Generator

With Rails, you can generate the required migration then run it:

```bash
$ rails generate graphql:operation_store:create
$ rails db:migrate
```

(You'll have to run that migration on any staging or production servers, too.)

Now, `OperationStore` has what it needs to save queries using ActiveRecord!

### Manual Setup

You can also create the required migration by manually by generating an empty migration:

```bash
$ rails generate migration SetupOperationStore
```

Then open the migration file and add:

```ruby
# ...
# implement the change method with:
def change
  create_table :graphql_clients, primary_key: :id do |t|
    t.column :name, :string, null: false
    t.column :secret, :string, null: false
    t.timestamps
  end
  add_index :graphql_clients, :name, unique: true
  add_index :graphql_clients, :secret, unique: true

  create_table :graphql_operations, primary_key: :id do |t|
    t.column :digest, :string, null: false
    t.column :body, :text, null: false
    t.column :name, :string, null: false
    t.timestamps
  end
  add_index :graphql_operations, :digest, unique: true

  create_table :graphql_client_operations, primary_key: :id do |t|
    t.references :graphql_client, null: false
    t.references :graphql_operation, null: false
    t.column :alias, :string, null: false
    t.column :last_used_at, :datetime
    t.column :is_archived, :boolean, default: false
    t.timestamps
  end
  add_index :graphql_client_operations, [:graphql_client_id, :alias], unique: true, name: "graphql_client_operations_pairs"
  add_index :graphql_client_operations, :is_archived

  create_table :graphql_index_entries, primary_key: :id do |t|
    t.column :name, :string, null: false
  end
  add_index :graphql_index_entries, :name, unique: true

  create_table :graphql_index_references, primary_key: :id do |t|
    t.references :graphql_index_entry, null: false
    t.references :graphql_operation, null: false
  end
  add_index :graphql_index_references, [:graphql_index_entry_id, :graphql_operation_id], unique: true, name: "graphql_index_reference_pairs"
end
```

Then run the migration:

```
$ bundle exec rake db:migrate
```

(You'll have to run that migration on any staging or production servers, too.)

Now, `OperationStore` has what it needs to save queries using ActiveRecord!

## Database Update

GraphQL-Pro 1.15.0 introduced new features for the OperationStore. To enable them, add some columns to your database:

```ruby
add_column :graphql_client_operations, :is_archived, :boolean, default: false
add_column :graphql_client_operations, :last_used_at, :datetime
```

## Updating `last_used_at`

By default, GraphQL-Pro updates `last_used_at` values in a background thread every 5 seconds. You can customize this by passing a number of seconds to `update_last_used_at_every:` when installing the OperationStore:

```ruby
use GraphQL::Pro::OperationStore, update_last_used_at_every: 1 # seconds
```

To update that column inline each time an operation is accessed, pass `0`.

**Note:** It is recommended to set this to `0` in test environments, to avoid delayed updates in another thread that can cause intermittent test hangs and failures. For example:

```ruby
# Update immediately in Test, wait 5 seconds in other environments:
use GraphQL::Pro::OperationStore, update_last_used_at_every: Rails.env.test? ? 0 : 5
```
