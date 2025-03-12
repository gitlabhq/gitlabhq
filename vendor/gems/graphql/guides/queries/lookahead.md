---
layout: guide
doc_stub: false
search: true
section: Queries
title: Lookahead
desc: Detecting child selections during field resolution
index: 11
---

GraphQL-Ruby 1.9+ includes {{ "GraphQL::Execution::Lookahead" | api_doc }} for checking whether child fields are selected. You can use this to optimize database access, for example, selecting only the _needed_ fields from the database.

## Getting a Lookahead

Add `extras: [:lookahead]` to your field configuration to receive an injected lookahead:

```ruby
field :files, [Types::File], null: false, extras: [:lookahead]
```

Then, update your resolver method to accept a `lookahead:` argument:

```ruby
def files(lookahead:)
  # ...
end
```

That argument will be injected by the GraphQL runtime.

## Using a lookahead

Inside your field resolver, you can use the lookahead to check for child fields. For example, you can check for a __specific selection__:

```ruby
def files(lookahead:)
  if lookahead.selects?(:full_path)
    # This is a query like `files { fullPath ... }`
  else
    # This query doesn't have `fullPath`
  end
end
```

Or, you can list __all the selected fields__:

```ruby
def files(lookahead:)
  all_selections = lookahead.selections.map(&:name)
  if all_selections == [:name]
    # Only `files { name }` was selected, use a fast cached value:
    object.file_names.map { |n| { name: n }}
  else
    # Lots of fields were selected, fall back to a more resource-intensive approach
    FileSystemHelper.load_files_for(object)
  end
end
```

Lookaheads are _chainable_, so you can use them to check __nested selections__ too:

```ruby
def files(lookahead:)
  if lookahead.selection(:history).selects?(:author)
    # For example, `files { history { author { ... } } }`
    # We're checking for commit authors, so load those objects appropriately ...
  else
    # Not selecting commit authors ...
  end
end
```

Nested lookaheads return empty objects when there's no selection (not `nil`), so the code above will never have a "no method error on `nil`".

## Lookaheads with connections

If you want to see what selections were made on the items in a connection, you can use nested lookaheads. However, don't forget to check for `edges { node }` _and_ `nodes { ... }`, if you support that shortcut field. For example:

```ruby
field :products, Types::Product.connection_type, null: false, extras: [:lookahead]

def products(lookahead:)
  selects_quantity_available = lookahead.selection(:nodes).selects?(:quantity_available) ||
                               # ^^ check for `products { nodes { quantityAvailable } }`
    lookahead.selection(:edges).selection(:node).selects?(:quantity_available)
    # ^^ check for `products { edges { node { quantityAvailable } } }`

  if selects_quantity_available
    # ...
  else
    # ...
  end
end
```

That way, you can check for specific selections on the nodes in a connection.

## Lookaheads with aliases

If you want to find selection by its [alias](https://spec.graphql.org/June2018/#sec-Field-Alias), you can use `#alias_selection(...)` or check if it exists with `#selects_alias?`. In this case, the lookahead will check if there is a field with the provided alias.


For example, this query can find a bird species by its name:

```graphql
query {
  gull: findBirdSpecies(byName: "Laughing Gull") {
    name
  }

  tanager: findBirdSpecies(byName: "Scarlet Tanager") {
    name
  }
}
```

You can get the lookahead for each selection in a following way:

```ruby
def find_bird_species(by_name:, lookahead:)
  if lookahead.selects_alias?("gull")
    lookahead.alias_selection("gull")
  end
end
```
