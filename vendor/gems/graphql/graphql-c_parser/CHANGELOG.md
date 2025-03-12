# GraphQL::CParser

## 1.1.2

- Fix to handle strings with null bytes #5193

## 1.1.1

- Add support for `Schema.max_query_string_tokens` #4929

## 1.1.0

- Drop support for Ruby 2.7 #4899
- Reduce allocation of repeated strings for identifiers when parsing schemas #4899

## 1.0.8

- Support directives on variable definitions, requires `graphql` 2.2.10+ #4847

## 1.0.5

- Properly parse integers with leading zeros as Integers, not Floats #4556

## 1.0.4

- Use UTF-8 encoding for static strings #4526

## 1.0.3

- Raise a `ParseError` on bad Unicode escapes (like the Ruby parser) #4514
- Force UTF-8 encoding (like the Ruby parser) #4467

## 1.0.2

- Remove `.y` and `.rl` files to avoid triggering build tasks during install

## 1.0.1

- Fix gem files (to include `ext`)

## 1.0.0

- Release GraphQL::CParser
