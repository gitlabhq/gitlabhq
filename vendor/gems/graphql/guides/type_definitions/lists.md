---
layout: guide
doc_stub: false
search: true
section: Type Definitions
title: Lists
desc: Ordered lists containing other types
index: 6
---

GraphQL has _list types_ which are ordered lists containing items of other types. The following examples use the [GraphQL Schema Definition Language](https://graphql.org/learn/schema/#type-language) (SDL).

Fields may return a single scalar value (eg `String`), or a _list_ of scalar values (eg, `[String]`, a list of strings):

```ruby
type Spy {
  # This spy's real name
  realName: String!
  # Any other names that this spy goes by
  aliases: [String!]
}
```

Fields may also return lists of other types as well:

```ruby
enum PostCategory {
  SOFTWARE
  UPHOLSTERY
  MAGIC_THE_GATHERING
}

type BlogPost {
  # Zero or more categories this post belongs to
  categories: [PostCategory!]
  # Other posts related to this one
  relatedPosts: [BlogPost!]
}
```

Inputs may also be lists. Arguments can accept list types, for example:

```ruby
type Query {
  # Return the latest posts, filtered by `categories`
  posts(categories: [PostCategory!]): [BlogPost!]
}
```

When GraphQL is sent and received with JSON, GraphQL lists are expressed in JSON arrays.

## List Types in Ruby

To define a list type in Ruby use `[...]` (a Ruby array with one member, the inner type). For example:

```ruby
# A field returning a list type:
# Equivalent to `aliases: [String!]` above
field :aliases, [String]

# An argument which accepts a list type:
argument :categories, [Types::PostCategory], required: false
```

For input, GraphQL lists are converted to Ruby arrays.

For fields that return list types, any object responding to `#each` may be returned. It will be enumerated as a GraphQL list.

To define lists where `nil` may be a member of the list, use `null: true` in the definition array, for example:

```ruby
# Equivalent to `previousEmployers: [Employer]!`
field :previous_employers, [Types::Employer, null: true], "Previous employers; `null` represents a period of self-employment or unemployment" null: false
```

## Lists, Nullable Lists, and Lists of Nulls

Combining list types and non-null types can be a bit tricky. There are four possible combinations, based on two parameters:

- Nullability of the field: can this field return `null`, or does it always return a list?
- Nullability of the list items: when a list is present, may it include `null`?

Here's how those combinations play out:

 &nbsp;  | nullable field | non-null field
 ------|------|------
nullable items  | <code>[Integer, null: true], null: true</code><br><code># => [Int]</code> | <code>[Integer, null: true], null: false</code><br><code># => [Int]!</code>
non-null items   | <code>[Integer]</code><br><code># => [Int!]</code> | <code>[Integer], null: false</code><br><code># => [Int!]!</code>

(The first line is GraphQL-Ruby code. The second line, beginning with `# =>`, is the corresponding GraphQL SDL code.)


Let's look at some examples.

#### Non-null lists with non-null items

Here's an example field:

```ruby
field :scores, [Integer], null: false
# In GraphQL,
#   scores: [Int!]!
```

In this example, `scores` may not return `null`. It must _always_ return a list. Additionally, the list may _never_ contain `null` -- it may only contain `Int`s. (It may be empty, but it cannot have `null` in it.)

Here are values the field may return:

| Valid | Invalid |
| ------ | ------ |
| `[]` | `null` |
| `[1, 2, ...]` | `[null]` |
| | `[1, null, 2, ...]` |

### Non-null lists with nullable items

Here's an example field:

```ruby
field :scores, [Integer, null: true], null: false
# In GraphQL,
#   scores: [Int]!
```

In this example, `scores` may not return `null`. It must _always_ return a list. However, the list _may_ contain `null`s and/or `Int`s.

Here are values the field may return:

Valid | Invalid
------|------
`[]`  | `null`
`[1, 2, ...]`|
`[null]` |
 `[1, null, 2, ...]` |

### Nullable lists with nullable items

Here's an example field:

```ruby
field :scores, [Integer, null: true]
# In GraphQL,
#   scores: [Int]
```

In this example, `scores` return `null` _or_ a list. Additionally, the list _may_ contain `null`s and/or `Int`s.

Here are values the field may return:

Valid | Invalid
------|------
`null` |
`[]`  |
`[1, 2, ...]`|
`[null]` |
 `[1, null, 2, ...]` |


### Nullable lists with non-null items

Here's an example field:

```ruby
field :scores, [Integer]
# In GraphQL,
#   scores: [Int!]
```

In this example, `scores` return `null` _or_ a list. However, if a list is present, it may _not_ contain `null` -- only `Int`s.

Here are values the field may return:

Valid | Invalid
------|------
`null` | `[null]`
`[]`  | `[1, null, 2, ...]`
`[1, 2, ...]` |
