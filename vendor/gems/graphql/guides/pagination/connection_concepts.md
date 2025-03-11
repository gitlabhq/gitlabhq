---
layout: guide
doc_stub: false
search: true
section: Pagination
title: Connection Concepts
desc: Introduction to Connections
index: 1
---

__Connections__ are a pagination solution which started with [Relay JS](https://facebook.github.io/relay), but now it's used for almost any GraphQL API.

Connections are composed of a few kinds of objects:

- `Connection` types are generics that expose pagination-related metadata and access to the items
- `Edge` types are also generics. They represent the relationship between the parent and child (eg, a `PostEdge` represents the link from `Blog` to `Post`).
- _nodes_ are actual list items. In a `PostsConnection`, each node is a `Post`.

Connections have some advantages over offset-based pagination:

- First-class support for relationship metadata
- Cursor implementations can support efficient, stable pagination

## Connections, Edges and Nodes

Connection pagination has three core objects: connections, edges, and nodes.

### Nodes

Nodes are items in a list. A `node` is usually an object in your schema. For example, a `node` in a `posts` connection is a `Post`:

```ruby
{
  posts(first: 5) {
    edges {
      node {
        # This is a `Post` object:
        title
        body
        publishedAt
      }
    }
  }
}
```

### Connections

Connections are objects that _represent_ a one-to-many relation. They contain _metadata_ about the list of items and _access to the items_.

Connections are often generated from object types. Their list items, called _nodes_, are members of that object type. Connections can also be generated from union types and interface types.

##### Connection metadata

Connections can tell you about the list in general. For example, if you {% internal_link "add a total count field", "type_definitions/extensions#customizing-connections" %}, they can tell you the count:

```ruby
{
  posts {
    # This is a PostsConnection
    totalCount
  }
}
```

##### Connection items

The list items in a connection are called _nodes_. They can generally be accessed two ways:

- via edges: `posts { edges { node { ... } } }`
- via nodes: `posts { nodes { ... } }`

The differences is that `edges { node { ... } }` has more room for relationship metadata. For example, when listing the members of a team, you might include _when_ someone joined the team as edge metadata:

```ruby
team {
  members(first: 10) {
    edges {
      # when did this person join the team?
      joinedAt
      # information about the person:
      node {
        name
      }
    }
  }
}
```

Alternatively, `nodes` provides easier access to the items, but can't expose relationship metadata:

```ruby
team {
  members(first: 10) {
    nodes {
      # shows the team members' names
      name
    }
  }
}
```

There's no way to show `joinedAt` above without using `edges { ... }`.

### Edges

Edges are _like_ join tables in that they can expose relationship metadata between a parent object and its children.

For example, let's say that someone may be the member of _several_ teams. You would make a join table in the database (eg, `team_memberships`) which connect people to each of the teams they're on. This join table could also include information about _how_ that person is related to the team: when they joined, what role they have, etc.

Edges can reveal this information about the relationship, for example:

```ruby
team {
  # this is the team name
  name

  members(first: 10) {
    edges {
      # this is a team membership
      joinedAt
      role

      node {
        # this is the person on the team
        name
      }
    }
  }
}
```

So, edges really help when the _relationship_ between two objects has special data associated with it. If you use a join table, that's a clue that you might use a custom edge to model the relationship.
