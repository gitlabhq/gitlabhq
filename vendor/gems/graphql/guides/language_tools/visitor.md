---
layout: guide
doc_stub: false
search: true
section: Language Tools
title: AST Visitor
desc: Analyze and modify parsed GraphQL code
index: 0
---

GraphQL code is usually contained in a string, for example:

```ruby
query_string = "query { user(id: \"1\") { userName } }"
```

You can perform programmatic analysis and modifications to GraphQL code using a three-step process:

- __Parse__ the code into an abstract syntax tree
- __Analyze/Modify__ the code with a visitor
- __Print__ the code back to a string

## Parse

{{ "GraphQL.parse" | api_doc }} turns a string into a GraphQL document:

```ruby
parsed_doc = GraphQL.parse("{ user(id: \"1\") { userName } }")
# => #<GraphQL::Language::Nodes::Document ...>
```

Also, {{ "GraphQL.parse_file" | api_doc }} parses the contents of the named file and includes a `filename` in the parsed document.

#### AST Nodes

The parsed document is a tree of nodes, called an _abstract syntax tree_ (AST). This tree is _immutable_: once a document has been parsed, those Ruby objects can't be changed. Modifications are performed by _copying_ existing nodes, applying changes to the copy, then making a new tree to hold the copied node. Where possible, unmodified nodes are retained in the new tree (it's _persistent_).

The copy-and-modify workflow is supported by a few methods on the AST nodes:

- `.merge(new_attrs)` returns a copy of the node with `new_attrs` applied. This new copy can replace the original node.
- `.add_{child}(new_child_attrs)` makes a new node with `new_child_attrs`, adds it to the array specified by `{child}`, and returns a copy whose `{children}` array contains the newly created node.

For example, to rename a field and add an argument to it, you could:

```ruby
modified_node = field_node
  # Apply a new name
  .merge(name: "newName")
  # Add an argument to this field's arguments
  .add_argument(name: "newArgument", value: "newValue")
```

Above, `field_node` is unmodified, but `modified_node` reflects the new name and new argument.

## Analyze/Modify

To inspect or modify a parsed document, extend {{ "GraphQL::Language::Visitor" | api_doc }} and implement its various hooks. It's an implementation of the [visitor pattern](https://en.wikipedia.org/wiki/Visitor_pattern). In short, each node of the tree will be "visited" by calling a method, and those methods can gather information and perform modifications.

In the visitor, each node class has a hook, for example:

- {{ "GraphQL::Language::Nodes::Field" | api_doc }}s are routed to `#on_field`
- {{ "GraphQL::Language::Nodes::Argument" | api_doc }}s are routed to `#on_argument`

See the {{ "GraphQL::Language::Visitor" | api_doc }} API docs for a full list of methods.

Each method is called with `(node, parent)`, where:

- `node` is the AST node currently visited
- `parent` is the AST node above this node in the tree

The method has a few options for analyzing or modifying the AST:

#### Continue/Halt

To continue visiting, the hook should call `super`. This allows the visit to continue to `node`'s children in the tree, for example:

```ruby
def on_field(_node, _parent)
  # Do nothing, this is the default behavior:
  super
end
```

To _halt_ the visit, a method may skip the call to `super`. For example, if the visitor encountered an error, it might want to return early instead of continuing to visit.

#### Modify a Node

Visitor hooks are expected to return the `(node, parent)` they are called with. If they return a different node, then that node will replace the original `node`. When you call `super(node, parent)`, the `node` is returned. So, to modify a node and continue visiting:

- Make a modified copy of `node`
- Pass the modified copy to `super(new_node, parent)`

For example, to rename an argument:

```ruby
def on_argument(node, parent)
  # make a copy of `node` with a new name
  modified_node = node.merge(name: "renamed")
  # continue visiting with the modified node and parent
  super(modified_node, parent)
end
```

#### Delete a Node

To delete the currently-visited `node`, don't pass `node` to `super(...)`. Instead, pass a magic constant, `DELETE_NODE`, in place of `node`.

For example, to delete a directive:

```ruby
def on_directive(node, parent)
  # Don't pass `node` to `super`,
  # instead, pass `DELETE_NODE`
  super(DELETE_NODE, parent)
end
```

#### Insert a Node

Inserting nodes is similar to modifying nodes. To insert a new child into `node`, call one of its `.add_` helpers. This returns a copied node with a new child added. For example, to add a selection to a field's selection set:

```ruby
def on_field(node, parent)
  node_with_selection = node.add_selection(name: "emailAddress")
  super(node_with_selection, parent)
end
```

This will add `emailAddress` the fields selection on `node`.


(These `.add_*` helpers are wrappers around {{ "GraphQL::Language::Nodes::AbstractNode#merge" | api_doc }}.)

## Print

The easiest way to turn an AST back into a string of GraphQL is {{ "GraphQL::Language::Nodes::AbstractNode#to_query_string" | api_doc }}, for example:

```ruby
parsed_doc.to_query_string
# => '{ user(id: "1") { userName } }'
```

You can also create a subclass of {{ "GraphQL::Language::Printer" | api_doc }} to customize how nodes are printed.
