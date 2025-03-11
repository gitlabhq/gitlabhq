---
title: Timeout
layout: guide
doc_stub: false
search: true
section: Queries
desc: Cutting off GraphQL execution
index: 5
---

You can apply a timeout to query execution with the `GraphQL::Schema::Timeout` plugin. For example:

```ruby
class MySchema < GraphQL::Schema
  use GraphQL::Schema::Timeout, max_seconds: 2
end
```

After `max_seconds`, no new fields will be resolved. Instead, errors will be added to the `errors` key for fields that weren't resolved.

__Note__ that this _does not interrupt_ field execution (doing so is [buggy](https://www.mikeperham.com/2015/05/08/timeout-rubys-most-dangerous-api/)). If you're making external calls (eg, HTTP requests or database queries), make sure to use a library-specific timeout for that operation (eg, [Redis timeout](https://github.com/redis/redis-rb#timeouts), [Net::HTTP](https://ruby-doc.org/stdlib-2.4.1/libdoc/net/http/rdoc/Net/HTTP.html)'s `ssl_timeout`, `open_timeout`, and `read_timeout`).

## Custom Error Handling

To log the error, provide a subclass of `GraphQL::Schema::Timeout` with an overridden `handle_timeout` method:

```ruby
class MyTimeout < GraphQL::Schema::Timeout
  def handle_timeout(error, query)
    Rails.logger.warn("GraphQL Timeout: #{error.message}: #{query.query_string}")
  end
end

class MySchema < GraphQL::Schema
  use MyTimeout, max_seconds: 2
end
```

## Customizing the Timeout Window

To dynamically pick a timeout duration (or bypass it), override {{ "GraphQL::Schema::Timeout#max_seconds" | api_doc }} in your subclass. To bypass the timeout altogether, `max_seconds` can return `false`.

For example:

```ruby
class MyTimeout < GraphQL::Schema::Timeout
  # Allow 10s for an incoming mutation, but don't apply any timeout for an admin user.
  def max_seconds(query)
    if query.context[:current_user]&.admin?
      false
    elsif query.mutation?
      10
    else
      super
    end
  end
end

# ...

class MySchema < GraphQL::Schema
  use MyTimeout, max_seconds: 5
end
```

## Validation and Analysis

Queries can originate from a user, and may be crafted in a manner to take a long time to validate against the schema.

It is possible to limit how many seconds the static validation rules and analysers are allowed to run before returning a validation timeout error. The default is no timeout.

For example:

```ruby
class MySchema < GraphQL::Schema
  # Applies to static validation and query analysis
  validate_timeout 10
end
```

**Note:** This configuration uses Ruby's built-in `Timeout` API, which can interrupt IO calls mid-flight, resulting in [very weird bugs](https://www.mikeperham.com/2015/05/08/timeout-rubys-most-dangerous-api/). None of GraphQL-Ruby's validators make IO calls but if you want to use this configuration and you have custom static validators that make IO calls, open an issue to discuss implementing this in an IO-safe way.
