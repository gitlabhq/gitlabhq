# frozen_string_literal: true
module GraphQL
  module Execution
    # Execute multiple queries under the same multiplex "umbrella".
    # They can share a batching context and reduce redundant database hits.
    #
    # The flow is:
    #
    # - Multiplex instrumentation setup
    # - Query instrumentation setup
    # - Analyze the multiplex + each query
    # - Begin each query
    # - Resolve lazy values, breadth-first across all queries
    # - Finish each query (eg, get errors)
    # - Query instrumentation teardown
    # - Multiplex instrumentation teardown
    #
    # If one query raises an application error, all queries will be in undefined states.
    #
    # Validation errors and {GraphQL::ExecutionError}s are handled in isolation:
    # one of these errors in one query will not affect the other queries.
    #
    # @see {Schema#multiplex} for public API
    # @api private
    class Multiplex
      include Tracing::Traceable

      attr_reader :context, :queries, :schema, :max_complexity, :dataloader, :current_trace

      def initialize(schema:, queries:, context:, max_complexity:)
        @schema = schema
        @queries = queries
        @queries.each { |q| q.multiplex = self }
        @context = context
        @current_trace = @context[:trace] || schema.new_trace(multiplex: self)
        @dataloader = @context[:dataloader] ||= @schema.dataloader_class.new
        @tracers = schema.tracers + (context[:tracers] || [])
        @max_complexity = max_complexity
      end
    end
  end
end
