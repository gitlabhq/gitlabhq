---
layout: guide
doc_stub: false
search: true
section: Queries
title: Ahead-of-Time AST Analysis
desc: Check incoming query strings and reject them if they don't pass your checks
index: 1
redirect_from:
  - /queries/analysis/
---

You can do ahead-of-time analysis for your queries.

The primitive for analysis is {{ "GraphQL::Analysis::Analyzer" | api_doc }}. Analyzers must inherit from this base class and implement the desired methods for analysis.

## Using Analyzers

Query analyzers are added to the schema with `query_analyzer`, for example:

```ruby
class MySchema < GraphQL::Schema
  query_analyzer MyQueryAnalyzer
end
```

Pass the **class** (and not an _instance_) of your analyzer. The analysis engine will take care of instantiating your analyzers with the query.

## Analyzer API

Analyzers respond to methods similar to AST visitors. They're named like `on_enter_#{ast_node}` and `on_leave_#{ast_node}`. Methods are called with three arguments:

- `node`: The current AST node (being entered or left)
- `parent`: The AST node which precedes this one in the tree
- `visitor`: A {{ "GraphQL::Analysis::Visitor" | api_doc }} which is managing this analysis run

For example:

```ruby
class BasicCounterAnalyzer < GraphQL::Analysis::Analyzer
  def initialize(query_or_multiplex)
    super
    @fields = Set.new
    @arguments = Set.new
  end

  # Visitors are all defined on the Analyzer base class
  # We override them for custom analyzers.
  def on_leave_field(node, _parent, _visitor)
    @fields.add(node.name)
  end

  def result
    # Do something with the gathered result.
    Analytics.log(@fields)
  end
end
```

In this example, we counted every field, no matter if it was on fragment definitions
or if it was skipped by directives. If we want to detect those contexts, we can use helper
methods:

```ruby
class BasicFieldAnalyzer < GraphQL::Analysis::Analyzer
  def initialize(query_or_multiplex)
    super
    @fields = Set.new
  end

  # Visitors are all defined on the Analyzer base class
  # We override them for custom analyzers.
  def on_leave_field(node, _parent, visitor)
    if visitor.skipping? || visitor.visiting_fragment_definition?
      # We don't want to count skipped fields or fields
      # inside fragment definitions
    else
      @fields.add(node.name)
    end
  end

  def result
    Analytics.log(@fields)
  end
end
```

See {{ "GraphQL::Analysis::Visitor" | api_doc }} for more information about the `visitor` object.

### Field Arguments

Usually, analyzers will use `on_enter_field` and `on_leave_field` to process queries. To get a field's arguments during analysis, use `visitor.query.arguments_for(node, visitor.field_definition)` ({{ "GraphQL::Query#arguments_for" | api_doc }}). That method returns coerced argument values and normalizes argument literals and variable values.

### Errors

It is still possible to return errors from an analyzer. To reject a query and halt its execution, you may return {{ "GraphQL::AnalysisError" | api_doc }} in the `result` method:

```ruby
class NoFieldsCalledHello < GraphQL::Analysis::Analyzer
  def on_leave_field(node, _parent, visitor)
    if node.name == "hello"
      @field_called_hello = true
    end
  end

  def result
    GraphQL::AnalysisError.new("A field called `hello` was found.") if @field_called_hello
  end
end
```

### Conditional Analysis

Some analyzers might only make sense in certain context, or some might be too expensive to run for every query. To handle these scenarios, your analyzers may answer to an `analyze?` method:

```ruby
class BasicFieldAnalyzer < GraphQL::Analysis::Analyzer
  # Use the analyze? method to enable or disable a certain analyzer
  # at query time.
  def analyze?
    !!subject.context[:should_analyze]
  end

  def on_leave_field(node, _parent, visitor)
    # ...
  end

  def result
    # ...
  end
end
```

## Analyzing Multiplexes

Analyzers are initialized with the _unit of analysis_, available as `subject`.

When analyzers are hooked up to multiplexes, `query` is `nil`, but `multiplex` returns the subject of analysis. You can use `visitor.query` inside visit methods to reference the query that owns the current AST node.

Note that some built-in analyzers (eg `AST::MaxQueryDepth`) support multiplexes even though `Query` is in their name.
