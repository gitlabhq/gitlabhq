---
layout: guide
doc_stub: false
search: true
section: Language Tools
title: C-based Parser
desc: The GraphQL::CParser gem is a drop-in replacement for the built-in parser
index: 1
---

GraphQL-Ruby includes a plain-Ruby parser, but a faster parser is available as a C extension. To use it, add the [`graphql-c_parser` gem](https://rubygems.org/gems/graphql-c_parser) to your project, for example:

```ruby
bundle add graphql-c_parser
```

When `graphql-c_parser` is `require`d by your app, the C-based parser is installed as the default parser (as {{ "GraphQL.default_parser" | api_doc }}). Bundler requires the library automatically, but you can also require it manually:

```ruby
require "graphql/c_parser"
```

This alternative parser is faster and uses less memory.

The library also adds `GraphQL.scan_with_c` and `GraphQL.parse_with_c` for calling the C-based parser directly.
