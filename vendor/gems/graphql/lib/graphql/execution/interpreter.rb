# frozen_string_literal: true
require "fiber"
require "graphql/execution/interpreter/argument_value"
require "graphql/execution/interpreter/arguments"
require "graphql/execution/interpreter/arguments_cache"
require "graphql/execution/interpreter/execution_errors"
require "graphql/execution/interpreter/runtime"
require "graphql/execution/interpreter/resolve"
require "graphql/execution/interpreter/handles_raw_value"

module GraphQL
  module Execution
    class Interpreter
      class << self
        # Used internally to signal that the query shouldn't be executed
        # @api private
        NO_OPERATION = GraphQL::EmptyObjects::EMPTY_HASH

        # @param schema [GraphQL::Schema]
        # @param queries [Array<GraphQL::Query, Hash>]
        # @param context [Hash]
        # @param max_complexity [Integer, nil]
        # @return [Array<GraphQL::Query::Result>] One result per query
        def run_all(schema, query_options, context: {}, max_complexity: schema.max_complexity)
          queries = query_options.map do |opts|
            case opts
            when Hash
              schema.query_class.new(schema, nil, **opts)
            when GraphQL::Query
              opts
            else
              raise "Expected Hash or GraphQL::Query, not #{opts.class} (#{opts.inspect})"
            end
          end


          multiplex = Execution::Multiplex.new(schema: schema, queries: queries, context: context, max_complexity: max_complexity)
          Fiber[:__graphql_current_multiplex] = multiplex
          trace = multiplex.current_trace
          trace.begin_execute_multiplex(multiplex)
          trace.execute_multiplex(multiplex: multiplex) do
            schema = multiplex.schema
            queries = multiplex.queries
            lazies_at_depth = Hash.new { |h, k| h[k] = [] }
            multiplex_analyzers = schema.multiplex_analyzers
            if multiplex.max_complexity
              multiplex_analyzers += [GraphQL::Analysis::MaxQueryComplexity]
            end

            trace.begin_analyze_multiplex(multiplex, multiplex_analyzers)
            schema.analysis_engine.analyze_multiplex(multiplex, multiplex_analyzers)
            trace.end_analyze_multiplex(multiplex, multiplex_analyzers)

            begin
              # Since this is basically the batching context,
              # share it for a whole multiplex
              multiplex.context[:interpreter_instance] ||= multiplex.schema.query_execution_strategy(deprecation_warning: false).new
              # Do as much eager evaluation of the query as possible
              results = []
              queries.each_with_index do |query, idx|
                if query.subscription? && !query.subscription_update?
                  subs_namespace = query.context.namespace(:subscriptions)
                  subs_namespace[:events] = []
                  subs_namespace[:subscriptions] = {}
                end
                multiplex.dataloader.append_job {
                  operation = query.selected_operation
                  result = if operation.nil? || !query.valid? || !query.context.errors.empty?
                    NO_OPERATION
                  else
                    begin
                      # Although queries in a multiplex _share_ an Interpreter instance,
                      # they also have another item of state, which is private to that query
                      # in particular, assign it here:
                      runtime = Runtime.new(query: query, lazies_at_depth: lazies_at_depth)
                      query.context.namespace(:interpreter_runtime)[:runtime] = runtime

                      query.current_trace.execute_query(query: query) do
                        runtime.run_eager
                      end
                    rescue GraphQL::ExecutionError => err
                      query.context.errors << err
                      NO_OPERATION
                    end
                  end
                  results[idx] = result
                }
              end

              multiplex.dataloader.run

              # Then, work through lazy results in a breadth-first way
              multiplex.dataloader.append_job {
                query = multiplex.queries.length == 1 ? multiplex.queries[0] : nil
                queries = multiplex ? multiplex.queries : [query]
                final_values = queries.map do |query|
                  runtime = query.context.namespace(:interpreter_runtime)[:runtime]
                  # it might not be present if the query has an error
                  runtime ? runtime.final_result : nil
                end
                final_values.compact!
                multiplex.current_trace.execute_query_lazy(multiplex: multiplex, query: query) do
                  Interpreter::Resolve.resolve_each_depth(lazies_at_depth, multiplex.dataloader)
                end
              }
              multiplex.dataloader.run

              # Then, find all errors and assign the result to the query object
              results.each_with_index do |data_result, idx|
                query = queries[idx]
                if (events = query.context.namespace(:subscriptions)[:events]) && !events.empty?
                  schema.subscriptions.write_subscription(query, events)
                end
                # Assign the result so that it can be accessed in instrumentation
                query.result_values = if data_result.equal?(NO_OPERATION)
                  if !query.valid? || !query.context.errors.empty?
                    # A bit weird, but `Query#static_errors` _includes_ `query.context.errors`
                    { "errors" => query.static_errors.map(&:to_h) }
                  else
                    data_result
                  end
                else
                  result = {}

                  if !query.context.errors.empty?
                    error_result = query.context.errors.map(&:to_h)
                    result["errors"] = error_result
                  end

                  result["data"] = query.context.namespace(:interpreter_runtime)[:runtime].final_result

                  result
                end
                if query.context.namespace?(:__query_result_extensions__)
                  query.result_values["extensions"] = query.context.namespace(:__query_result_extensions__)
                end
                # Get the Query::Result, not the Hash
                results[idx] = query.result
              end

              results
            rescue Exception
              # TODO rescue at a higher level so it will catch errors in analysis, too
              # Assign values here so that the query's `@executed` becomes true
              queries.map { |q| q.result_values ||= {} }
              raise
            ensure
              Fiber[:__graphql_current_multiplex] = nil
              queries.map { |query|
                runtime = query.context.namespace(:interpreter_runtime)[:runtime]
                if runtime
                  runtime.delete_all_interpreter_context
                end
              }
            end
          end
        ensure
          trace&.end_execute_multiplex(multiplex)
        end
      end

      class ListResultFailedError < GraphQL::Error
        def initialize(value:, path:, field:)
          message = "Failed to build a GraphQL list result for field `#{field.path}` at path `#{path.join(".")}`.\n".dup

          message << "Expected `#{value.inspect}` (#{value.class}) to implement `.each` to satisfy the GraphQL return type `#{field.type.to_type_signature}`.\n"

          if field.connection?
            message << "\nThis field was treated as a Relay-style connection; add `connection: false` to the `field(...)` to disable this behavior."
          end
          super(message)
        end
      end
    end
  end
end
