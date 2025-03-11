---
title: Response Extensions
layout: guide
doc_stub: false
search: true
section: Queries
desc: Adding "extensions" to the response hash
index: 12
---

During query execution, you can add to the response's `"extensions" => { ... }` Hash. By default, no `"extensions"` key is present in the result, but if you call the method below, it will be present with the given values.

To add to `"extensions"`, call `context.response_extensions[key] = value` during execution. For example:

```ruby
field :to_dos, [ToDo]

def to_dos
  warnings = context.response_extensions["warnings"] ||= []
  warnings << "To-Dos will be disabled on Jan. 31, 2022."
  context[:current_user].deprecated_to_dos
end
```


That would add to the final query response:

```ruby
{
  "data" => { ... },
  "extensions" => {
    "warnings" => ["To-Dos will be disabled on Jan. 31, 2022"],
  },
}
```

Values written to `context.response_extensions` are added to the GraphQL response verbatim.
