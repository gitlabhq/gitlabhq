---
layout: guide
search: true
section: Dataloader
title: Manual Parallelism
desc: Yield to Dataloader after starting work
index: 7
---

You can coordinate with {{ "GraphQL::Dataloader" | api_doc }} to run tasks in the background. To do this, call `dataloader.yield` inside `Source#fetch` after kicking off your task. For example:

```ruby
def fetch(ids)
  # somehow queue up a background query,
  # see examples below
  future_result = async_query_for(ids)
  # return control to the dataloader
  dataloader.yield
  # dataloader will come back here
  # after calling other sources,
  # now wait for the value
  future_result.value
end
```

_Alternatively, you can use {% internal_link "AsyncDataloader", "/dataloader/async_dataloader" %} to automatically background I/O inside `Source#fetch` calls._

## Example: Rails load_async

You can use Rails's `load_async` method to load `ActiveRecord::Relation`s in the background. For example:

```ruby
class Sources::AsyncRelationSource < GraphQL::Dataloader::Source
  def fetch(relations)
    relations.each(&:load_async) # start loading them in the background
    dataloader.yield # hand back to GraphQL::Dataloader
    relations.each(&:load) # now, wait for the result, returning the now-loaded relation
  end
end
```

You could call that source from a GraphQL field method:

```ruby
field :direct_reports, [Person]

def direct_reports
  # prepare an ActiveRecord::Relation:
  direct_reports = Person.where(manager: object)
  # pass it off to the source:
  dataloader
    .with(Sources::AsyncRelationSource)
    .load(direct_reports)
end
```

## Example: Rails async calculations

In a Dataloader source, you can run Rails async calculations in the background while other work continues. For example:

```ruby
class Sources::DirectReportsCount < GraphQL::Dataloader::Source
  def fetch(users)
    # Start the queries in the background:
    promises = users.map { |u| u.direct_reports.async_count }
    # Return to GraphQL::Dataloader:
    dataloader.yield
    # Now return the results, waiting if necessary:
    promises.map(&:value)
  end
end
```

Which could be used in a GraphQL field:

```ruby
field :direct_reports_count, Int

def direct_reports_count
  dataloader.with(Sources::DirectReportsCount).load(object)
end
```

## Example: Concurrent::Future

You could use `concurrent-ruby` to put work in a background thread. For example, using `Concurrent::Future`:

```ruby
class Sources::ExternalDataSource < GraphQL::Dataloader::Source
  def fetch(urls)
    # Start some I/O-intensive work:
    futures = urls.map do |url|
      Concurrent::Future.execute {
        # Somehow fetch and parse data:
        get_remote_json(url)
      }
    end
    # Yield back to GraphQL::Dataloader:
    dataloader.yield
    # Dataloader has done what it can,
    # so now return the value, waiting if necessary:
    futures.map(&:value)
  end
end
```
