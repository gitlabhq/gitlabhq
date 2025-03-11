---
layout: guide
doc_stub: false
search: true
section: Pagination
title: Custom Connections
desc: Building & using cursor-based connections in GraphQL-Ruby
index: 3
---

GraphQL-Ruby ships with built-in connection support for ActiveRecord, Sequel, Mongoid, and Ruby Arrays. You can read more in the {% internal_link "Using Connections", "/pagination/using_connections" %} guide.

When you want to serve a connection based on your _own_ data object, you can create a custom connection. The implementation will have several components:

- The __application object__ -- the list of items that you want to paginate in GraphQL
- The __connection wrapper__ which wraps the application object and implements methods used by GraphQL
- The __connection type__, a GraphQL object type which implements the connection contract

For this example, we'll imagine that your application communicates with an external search engine, and expresses all search results with a `SearchEngine::Result` class. (There isn't _really_ any class like this; it's an arbitrary example of an application-specific collection of items.)

## Application Object

In Ruby, _everything_ is an object, and that includes _lists of objects_. For example, we think of an Array as a _list_ of objects, but Arrays are also objects in their own right.

Some list objects have very fancy implementations. Think of an `ActiveRecord::Relation`: it gathers up the parts of a SQL query, and at the right moment, it dispatches a call to your database to fetch the objects in the list. An `ActiveRecord::Relation` is also a list object.

Your application probably has other list objects that you want to paginate via GraphQL connections. For example, you might show a user some search results, or a list of files from a fileserver. Those lists are modeled with _list objects_, and those list objects can be wrapped with connection wrappers.

## Connection Wrapper

A connection wrapper is an adapter between a plain-Ruby list object (like an Array, Relation, or something application-specific, like `SearchEngine::Result`) and a GraphQL connection type. The connection wrapper implements methods which the GraphQL connection type requires, and it implements those methods based on the underlying list object.

You can extend {{ "GraphQL::Pagination::Connection" | api_doc }} to get started on a custom connection wrapper, for example:

```ruby
# app/graphql/connections/search_results_connection.rb
class Connections::SearchResultsConnection < GraphQL::Pagination::Connection
  # implementation here ...
end
```

The methods you must implement are:

- `#nodes`, which returns a paginated slice of `@items` based on the given arguments
- `#has_next_page`, which returns `true` if there are items after the ones in `#nodes`
- `#has_previous_page`, which returns `true` if there are items before the ones in `#nodes`
- `#cursor_for(item)`, which returns a String to serve as the cursor for `item`

How to implement these methods (efficiently!) depends on your backend and how you communicate with it. For inspiration, you can see the built-in connections:

- {{ "GraphQL::Pagination::ArrayConnection" | api_doc }}
- {{ "GraphQL::Pagination::ActiveRecordRelationConnection" | api_doc }}
- {{ "GraphQL::Pagination::SequelDatasetConnection" | api_doc }}
- {{ "GraphQL::Pagination::MongoidRelationConnection" | api_doc }}

### Using a Custom Connection

To integrate your custom connection wrapper with GraphQL, you have two options:

- Map the wrapper to a list object at the _schema level_, so that those list objects are _always_ automatically wrapped by your wrapper; OR
- Use the wrapper manually in resolve methods, to override any automatic mapping

The first case is very convenient, and the second case makes it possible to customize connections for specific situations.

To __map the wrapper to a class of objects__, add it to your schema:

```ruby
class MySchema < GraphQL::Schema
  # Hook up a custom wrapper
  connections.add(SearchEngine::Result, Connections::SearchResultsConnection)
end
```

Now, any time a field returns an instance of `SearchEngine::Result`, it will be wrapped with `Connections::SearchResultsConnection`

Alternatively, you can apply a connection wrapper on a case-by-case basis by applying it during the resolver (method or {{ "GraphQL::Schema::Resolver" | api_doc }}):

```ruby
field :search, Types::SearchResult.connection_type, null: false do
  argument :query, String
end

def search(query:)
  search = SearchEngine::Search.new(query: query, viewer: context[:current_user])
  results = search.results
  # Apply the connection wrapper and return it
  Connections::SearchResultsConnection.new(results)
end
```

GraphQL-Ruby will use the provided connection wrapper in that case. You can use this fine-grained approach to handle special cases or implement performance optimizations.

## Connection Type

Connection types are GraphQL object types which comply to the [Relay connection specification](https://relay.dev/graphql/connections.htm). GraphQL-Ruby ships with some tools to help you create those object types:

- {{ "GraphQL::Types::Relay::BaseConnection" | api_doc }} and {{ "GraphQL::Types::Relay::BaseEdge" | api_doc }} are example implementations of the spec. They don't inherit from your application's base object class though, so you might not be able to use them out of the box.
- Type classes respond to `.connection_type` which returns a generated connection type based on that class. By default, it inherits from the provided `GraphQL::Types::Relay::BaseConnection`, but you can override that by setting `connection_type_class(Types::MyBaseConnectionObject)` in your base classes.

For example, you could implement a base connection class:

```ruby
class Types::BaseConnectionObject < Types::BaseObject
  # implement based on `GraphQL::Types::Relay::BaseConnection`, etc
end
```

Then hook it up to your base classes:

```ruby
class Types::BaseObject < GraphQL::Schema::Object
  # ...
  connection_type_class(Types::BaseConnectionObject)
end

class Types::BaseUnion < GraphQL::Schema::Union
  connection_type_class(Types::BaseConnectionObject)
end

module Types::BaseInterface
  include GraphQL::Schema::Interface

  connection_type_class(Types::BaseConnectionObject)
end
```


Then, when defining fields, you could use `.connection_type` to use your connection class hierarchy:

```ruby
field :posts, Types::Post.connection_type, null: false
```

(Those fields get `connection: true` by default, because the generated connection type's name ends in `*Connection`.)
