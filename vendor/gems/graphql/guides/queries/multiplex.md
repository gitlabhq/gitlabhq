---
title: Multiplex
layout: guide
doc_stub: false
search: true
section: Queries
desc: Run multiple queries concurrently
index: 10
---

Some clients may send _several_ queries to the server at once (for example, [Apollo Client's query batching](https://www.apollographql.com/docs/react/api/link/apollo-link-batch-http/)). You can execute them concurrently with {{ "Schema#multiplex" | api_doc }}.

Multiplex runs have their own context, analyzers and instrumentation.

__NOTE:__ As an implementation detail, _all_ queries run inside multiplexes. That is, a stand-alone query is executed as a "multiplex of one", so instrumentation and multiplex analyzers and tracers _will_ apply to standalone queries run with `MySchema.execute(...)`.

## Concurrent Execution

To run queries concurrently, build an array of query options, using `query:` for the query string. For example:

```ruby
# Prepare the context for each query:
context = {
  current_user: current_user,
}

# Prepare the query options:
queries = [
  {
   query: "query Query1 { someField }",
   variables: {},
   operation_name: 'Query1',
   context: context,
 },
 {
   query: "query Query2 ($num: Int){ plusOne(num: $num) }",
   variables: { num: 3 },
   operation_name: 'Query2',
   context: context,
 }
]
```

Then, pass them to `Schema#multiplex`:

```ruby
results = MySchema.multiplex(queries)
```

`results` will contain the result for each query in `queries`. __NOTE:__ The results will always be in the same order that their respective requests were sent in.

## Apollo Query Batching

Apollo sends batches of queries as an array of queries. Rails' ActionDispatch will parse the request and put the result into the `_json` field of the `params` variable. You also need to ensure that your schema can handle both batched and non-batched queries, below is an example of the default GraphqlController rewritten to handle Apollo batches:

```ruby
def execute
  context = {}

  # Apollo sends the queries in an array when batching is enabled. The data ends up in the _json field of the params variable.
  # see the Apollo Documentation about query batching: https://www.apollographql.com/docs/react/api/link/apollo-link-batch-http/
  result = if params[:_json]
    queries = params[:_json].map do |param|
      {
        query: param[:query],
        operation_name: param[:operationName],
        variables: ensure_hash(param[:variables]),
        context: context
      }
    end
    MySchema.multiplex(queries)
  else
    MySchema.execute(
      params[:query],
      operation_name: params[:operationName],
      variables: ensure_hash(params[:variables]),
      context: context
    )
  end

  render json: result, root: false
end
```

## Validation and Error Handling

Each query is validated and {% internal_link "analyzed","/queries/ast_analysis" %} independently. The `results` array may include a mix of successful results and failed results.

## Multiplex-Level Context

You can add values to {{ "Execution::Multiplex#context" | api_doc }} by providing a `context:` hash:

```ruby
MySchema.multiplex(queries, context: { current_user: current_user })
```

This will be available to instrumentation as `multiplex.context[:current_user]` (see below).

## Multiplex-Level Analysis

You can analyze _all_ queries in a multiplex by adding a multiplex analyzer. For example:

```ruby
class MySchema < GraphQL::Schema
  # ...
  multiplex_analyzer(MyAnalyzer)
end
```

The API is the same as {% internal_link "query analyzers","/queries/ast_analysis#analyzing-multiplexes" %}.

Multiplex analyzers may return {{ "AnalysisError" | api_doc }} to halt execution of the whole multiplex.

## Multiplex Tracing

You can add hooks for each multiplex run with {% internal_link "trace modules", "/queries/tracing" %}.

The trace module may implement `def execute_multiplex(multiplex:)` which `yield`s to allow the multiplex to execute. See {{ "Execution::Multiplex" | api_doc }} for available methods.

For example:

```ruby
# Count how many queries are in the multiplex run:
module MultiplexCounter
  def execute_multiplex(multiplex:)
    Rails.logger.info("Multiplex size: #{multiplex.queries.length}")
    yield
  end
end

# ...

class MySchema < GraphQL::Schema
  # ...
  trace_with(MultiplexCounter )
end
```

Now, `MultiplexCounter#execute_multiplex` will be called for each execution, logging the size of each multiplex.
