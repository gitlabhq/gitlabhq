# frozen_string_literal: true
require "graphql/tracing/detailed_trace/memory_backend"
require "graphql/tracing/detailed_trace/redis_backend"

module GraphQL
  module Tracing
    # `DetailedTrace` can make detailed profiles for a subset of production traffic.
    #
    # When `MySchema.detailed_trace?(query)` returns `true`, a profiler-specific `trace_mode: ...` will be used for the query,
    # overriding the one in `context[:trace_mode]`.
    #
    # __Redis__: The sampler stores its results in a provided Redis database. Depending on your needs,
    # You can configure this database to retail all data (persistent) or to expire data according to your rules.
    # If you need to save traces indefinitely, you can download them from Perfetto after opening them there.
    #
    # @example Adding the sampler to your schema
    #   class MySchema < GraphQL::Schema
    #     # Add the sampler:
    #     use GraphQL::Tracing::DetailedTrace, redis: Redis.new(...), limit: 100
    #
    #     # And implement this hook to tell it when to take a sample:
    #     def self.detailed_trace?(query)
    #       # Could use `query.context`, `query.selected_operation_name`, `query.query_string` here
    #       # Could call out to Flipper, etc
    #       rand <= 0.000_1 # one in ten thousand
    #     end
    #   end
    #
    # @see Graphql::Dashboard GraphQL::Dashboard for viewing stored results
    class DetailedTrace
      # @param redis [Redis] If provided, profiles will be stored in Redis for later review
      # @param limit [Integer] A maximum number of profiles to store
      def self.use(schema, trace_mode: :profile_sample, memory: false, redis: nil, limit: nil)
        storage = if redis
          RedisBackend.new(redis: redis, limit: limit)
        elsif memory
          MemoryBackend.new(limit: limit)
        else
          raise ArgumentError, "Pass `redis: ...` to store traces in Redis for later review"
        end
        schema.detailed_trace = self.new(storage: storage, trace_mode: trace_mode)
        schema.trace_with(PerfettoTrace, mode: trace_mode, save_profile: true)
      end

      def initialize(storage:, trace_mode:)
        @storage = storage
        @trace_mode = trace_mode
      end

      # @return [Symbol] The trace mode to use when {Schema.detailed_trace?} returns `true`
      attr_reader :trace_mode

      # @return [String] ID of saved trace
      def save_trace(operation_name, duration_ms, begin_ms, trace_data)
        @storage.save_trace(operation_name, duration_ms, begin_ms, trace_data)
      end

      # @param last [Integer]
      # @param before [Integer] Timestamp in milliseconds since epoch
      # @return [Enumerable<StoredTrace>]
      def traces(last: nil, before: nil)
        @storage.traces(last: last, before: before)
      end

      # @return [StoredTrace, nil]
      def find_trace(id)
        @storage.find_trace(id)
      end

      # @return [void]
      def delete_trace(id)
        @storage.delete_trace(id)
      end

      # @return [void]
      def delete_all_traces
        @storage.delete_all_traces
      end

      class StoredTrace
        def initialize(id:, operation_name:, duration_ms:, begin_ms:, trace_data:)
          @id = id
          @operation_name = operation_name
          @duration_ms = duration_ms
          @begin_ms = begin_ms
          @trace_data = trace_data
        end

        attr_reader :id, :operation_name, :duration_ms, :begin_ms, :trace_data
      end
    end
  end
end
