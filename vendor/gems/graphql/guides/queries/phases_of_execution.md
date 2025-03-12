---
layout: guide
doc_stub: false
search: true
section: Queries
title: Phases of Execution
desc: The steps GraphQL takes to run your query
index: 2
---

When GraphQL receives a query string, it goes through these steps:

- Tokenize: {{ "GraphQL::Language::Lexer" | api_doc }} splits the string into a stream of tokens
- Parse: {{ "GraphQL::Language::Parser" | api_doc }} builds an abstract syntax tree (AST) out of the stream of tokens
- Validate: {{ "GraphQL::StaticValidation::Validator" | api_doc }} validates the incoming AST as a valid query for the schema
- Analyze: If there are any query analyzers, they are run with {{ "GraphQL::Analysis.analyze_query" | api_doc }}
- Execute: The query is traversed, `resolve` functions are called and the response is built
- Respond: The response is returned as a {{ "GraphQL::Query::Result" | api_doc }}
