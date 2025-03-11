---
layout: guide
doc_stub: false
search: true
section: Testing
title: Profiling
desc: Profiling the performance of GraphQL-Ruby
index: 4
---

If you want to know more about how time is spent during GraphQL queries, including GraphQL-Ruby internals, you can use Ruby profiling tools to take a closer look.

If you want to investigate GraphQL-Ruby performance together, prepare a runtime profile and memory profile as described below and {% open_an_issue "Performance investigation" %} on GitHub, including those files.

## StackProf

[StackProf](https://github.com/tmm1/stackprof) is a Ruby library for figuring out where an operation's time is spent. To capture a profile, surround a block with `StackProf.run { ... }`.

```ruby
require "stackprof"

# Prepare any GraphQL-related data or context:
query_string = "{ someGraphQL ... }"
context = { ... }

# This will dump a profile in `tmp/graphql-prof.dump`
StackProf.run(mode: :wall, interval: 10, out: "tmp/graphql-prof.dump") do
  # Execute the query inside the block:
  MySchema.execute(query_string, context: context)
end
```

The `out:` option tells StackProf to create a "dump" at the given location. Then, anyone who has that file can investigate the profile using the `stackprof` command, for example:

```
$ stackprof tmp/graphql-prof.dump
==================================
  Mode: wall(1)
  Samples: 2492 (58.06% miss rate)
  GC: 0 (0.00%)
==================================
     TOTAL    (pct)     SAMPLES    (pct)     FRAME
       902  (36.2%)          94   (3.8%)     GraphQL::Execution::Interpreter::Runtime#evaluate_selection_with_resolved_keyword_args
      1283  (51.5%)          87   (3.5%)     GraphQL::Execution::Interpreter::Runtime#continue_field
       274  (11.0%)          78   (3.1%)     GraphQL::Schema::Field#resolve
      1068  (42.9%)          73   (2.9%)     GraphQL::Execution::Interpreter::Runtime#evaluate_selection
      # ...
```

Additionally, `stackprof` accepts a `--method` argument which provides details about the performance and usage of a specific method, for example:

```
$ stackprof tmp/small.dump --method #gather_selections
GraphQL::Execution::Interpreter::Runtime#gather_selections (/Users/rmosolgo/code/graphql-ruby/lib/graphql/execution/interpreter/runtime.rb:305)
  samples:    17 self (0.7%)  /     17 total (0.7%)
  callers:
      16  (   94.1%)  GraphQL::Execution::Interpreter::Runtime#continue_field
       6  (   35.3%)  Array#each
       1  (    5.9%)  GraphQL::Execution::Interpreter::Runtime#run_eager
  callees (0 total):
       6  (    Inf%)  Array#each
  code:
    1    (0.0%) /     1   (0.0%)  |   305  |                 when :lookahead
    6    (0.2%) /     6   (0.2%)  |   306  |                   if !field_ast_nodes
    3    (0.1%) /     3   (0.1%)  |   307  |                     field_ast_nodes = [ast_node]
                                  |   308  |                   end
```

Anyone with the `.dump` file can perform this analysis -- it's a really useful file! If you want to investigate GraphQL-Ruby performance together, please share a runtime profile.


## MemoryProfiler

[MemoryProfiler](https://github.com/SamSaffron/memory_profiler) provides insight into where an operation interacts with system memory and the Ruby heap. This is helpful because memory usage problems cause code to run slowly; fixing them can make code run fast.

To produce a report, wrap a block in `MemoryProfiler.report { ... }` and then call `.pretty_print` on the result. For example, to create a report on a GraphQL query:

```ruby
require 'memory_profiler'

# Prepare any GraphQL-related data or context:
query_string = "{ someGraphQL ... }"
context = { ... }

report = MemoryProfiler.report do
  # Execute the query inside the block:
  MySchema.execute(query_string, context: context)
end

# Write the result to a file
report.pretty_print(to_file: "tmp/graphql-memory.txt")
```

The report will include many interesting sections including:

- Total memory and objects allocated
- Objects allocated by location and by class
- String allocations, including the number of times a string with the same value was allocated

All of these can indicate "hot spots" in the code and inform refactors to reduce memory use. In turn, this reduces time spent in Ruby GC.

If you want to investigate GraphQL-Ruby performance together, please share a memory profile.
