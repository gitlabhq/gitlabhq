---
layout: guide
search: true
section: Dataloader
title: Testing
desc: Tips for testing Dataloader implementation
index: 4
---

There are a few techniques for testing your {{ "GraphQL::Dataloader" | api_doc }} setup.

## Integration Tests

One important feature of `Dataloader` is how it manages database access while GraphQL runs queries. You can test that by listening for database queries while running queries, for example, with ActiveRecord:


```ruby
def test_active_record_queries_are_batched_and_cached
  # set up a listener function
  database_queries = 0
  callback = lambda {|_name, _started, _finished, _unique_id, _payload| database_queries += 1 }

  query_str = <<-GRAPHQL
  {
    a1: author(id: 1) { name }
    a2: author(id: 2) { name }
    b1: book(id: 1) { author { name } }
    b2: book(id: 2) { author { name } }
  }
  GRAPHQL

  # Run the query with the listener
  ActiveSupport::Notifications.subscribed(callback, "sql.active_record") do
    MySchema.execute(query_str)
  end

  # One query for authors, one query for books
  assert_equal 2, database_queries
end
```

You could also make specific assertions on the queries that are run (see the [`sql.active_record` docs](https://edgeguides.rubyonrails.org/active_support_instrumentation.html#active-record)). For other frameworks and databases, check your ORM or library for instrumentation options.

## Testing Dataloader Sources

You can also test `Dataloader` behavior outside of GraphQL using {{ "GraphQL::Dataloader.with_dataloading" | api_doc }}. For example, let's if you have a `Sources::ActiveRecord` source defined like so:

```ruby

module Sources
  class User < GraphQL::Dataloader::Source
    def fetch(ids)
      records = User.where(id: ids)
      # return a list with `nil` for any ID that wasn't found, so the shape matches
      ids.map { |id| records.find { |r| r.id == id.to_i } }
    end
  end
end
```

You can test it like so:

```ruby
def test_it_fetches_objects_by_id
  user_1, user_2, user_3 = 3.times.map { User.create! }

  database_queries = 0
  callback = lambda {|_name, _started, _finished, _unique_id, _payload| database_queries += 1 }

  ActiveSupport::Notifications.subscribed(callback, "sql.active_record") do
    GraphQL::Dataloader.with_dataloading do |dataloader|
      req1 = dataloader.with(Sources::ActiveRecord).request(user_1.id)
      req2 = dataloader.with(Sources::ActiveRecord).request(user_2.id)
      req3 = dataloader.with(Sources::ActiveRecord).request(user_3.id)
      req4 = dataloader.with(Sources::ActiveRecord).request(-1)

      # Validate source's matching up of records
      expect(req1.load).to eq(user_1)
      expect(req2.load).to eq(user_2)
      expect(req3.load).to eq(user_3)
      expect(req4.load).to be_nil
    end
  end

  assert_equal 1, database_queries, "All users were looked up at once"
end
```
