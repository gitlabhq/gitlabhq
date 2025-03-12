# frozen_string_literal: true

module GraphQL
  class Schema
    # This plugin will stop resolving new fields after `max_seconds` have elapsed.
    # After the time has passed, any remaining fields will be `nil`, with errors added
    # to the `errors` key. Any already-resolved fields will be in the `data` key, so
    # you'll get a partial response.
    #
    # You can subclass `GraphQL::Schema::Timeout` and override `max_seconds` and/or `handle_timeout`
    # to provide custom logic when a timeout error occurs.
    #
    # Note that this will stop a query _in between_ field resolutions, but
    # it doesn't interrupt long-running `resolve` functions. Be sure to use
    # timeout options for external connections. For more info, see
    # www.mikeperham.com/2015/05/08/timeout-rubys-most-dangerous-api/
    #
    # @example Stop resolving fields after 2 seconds
    #   class MySchema < GraphQL::Schema
    #     use GraphQL::Schema::Timeout, max_seconds: 2
    #   end
    #
    # @example Notifying Bugsnag and logging a timeout
    #   class MyTimeout < GraphQL::Schema::Timeout
    #     def handle_timeout(error, query)
    #        Rails.logger.warn("GraphQL Timeout: #{error.message}: #{query.query_string}")
    #        Bugsnag.notify(error, {query_string: query.query_string})
    #     end
    #   end
    #
    #   class MySchema < GraphQL::Schema
    #     use MyTimeout, max_seconds: 2
    #   end
    #
    class Timeout
      def self.use(schema, max_seconds: nil)
        timeout = self.new(max_seconds: max_seconds)
        schema.trace_with(self::Trace, timeout: timeout)
      end

      def initialize(max_seconds:)
        @max_seconds = max_seconds
      end

      module Trace
        # @param max_seconds [Numeric] how many seconds the query should be allowed to resolve new fields
        def initialize(timeout:, **rest)
          @timeout = timeout
          super
        end

        def execute_multiplex(multiplex:)
          multiplex.queries.each do |query|
            timeout_duration_s = @timeout.max_seconds(query)
            timeout_state = if timeout_duration_s == false
              # if the method returns `false`, don't apply a timeout
              false
            else
              now = Process.clock_gettime(Process::CLOCK_MONOTONIC, :millisecond)
              timeout_at = now + (timeout_duration_s * 1000)
              {
                timeout_at: timeout_at,
                timed_out: false
              }
            end
            query.context.namespace(@timeout)[:state] = timeout_state
          end
          super
        end

        def execute_field(query:, field:, **_rest)
          timeout_state = query.context.namespace(@timeout).fetch(:state)
          # If the `:state` is `false`, then `max_seconds(query)` opted out of timeout for this query.
          if timeout_state != false && Process.clock_gettime(Process::CLOCK_MONOTONIC, :millisecond) > timeout_state.fetch(:timeout_at)
            error = GraphQL::Schema::Timeout::TimeoutError.new(field)
            # Only invoke the timeout callback for the first timeout
            if !timeout_state[:timed_out]
              timeout_state[:timed_out] = true
              @timeout.handle_timeout(error, query)
            end

            error
          else
            super
          end
        end
      end

      # Called at the start of each query.
      # The default implementation returns the `max_seconds:` value from installing this plugin.
      #
      # @param query [GraphQL::Query] The query that's about to run
      # @return [Numeric, false] The number of seconds after which to interrupt query execution and call {#handle_error}, or `false` to bypass the timeout.
      def max_seconds(query)
        @max_seconds
      end

      # Invoked when a query times out.
      # @param error [GraphQL::Schema::Timeout::TimeoutError]
      # @param query [GraphQL::Error]
      def handle_timeout(error, query)
        # override to do something interesting
      end

      # This error is raised when a query exceeds `max_seconds`.
      # Since it's a child of {GraphQL::ExecutionError},
      # its message will be added to the response's `errors` key.
      #
      # To raise an error that will stop query resolution, use a custom block
      # to take this error and raise a new one which _doesn't_ descend from {GraphQL::ExecutionError},
      # such as `RuntimeError`.
      class TimeoutError < GraphQL::ExecutionError
        def initialize(field)
          super("Timeout on #{field.path}")
        end
      end
    end
  end
end
