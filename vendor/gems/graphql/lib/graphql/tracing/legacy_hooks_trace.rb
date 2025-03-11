# frozen_string_literal: true

module GraphQL
  module Tracing
    module LegacyHooksTrace
      def execute_multiplex(multiplex:)
        multiplex_instrumenters = multiplex.schema.instrumenters[:multiplex]
        query_instrumenters = multiplex.schema.instrumenters[:query]
        # First, run multiplex instrumentation, then query instrumentation for each query
        RunHooks.call_hooks(multiplex_instrumenters, multiplex, :before_multiplex, :after_multiplex) do
          RunHooks.each_query_call_hooks(query_instrumenters, multiplex.queries) do
            super
          end
        end
      end

      module RunHooks
        module_function
        # Call the before_ hooks of each query,
        # Then yield if no errors.
        # `call_hooks` takes care of appropriate cleanup.
        def each_query_call_hooks(instrumenters, queries, i = 0)
          if i >= queries.length
            yield
          else
            query = queries[i]
            call_hooks(instrumenters, query, :before_query, :after_query) {
              each_query_call_hooks(instrumenters, queries, i + 1) {
                yield
              }
            }
          end
        end

        # Call each before hook, and if they all succeed, yield.
        # If they don't all succeed, call after_ for each one that succeeded.
        def call_hooks(instrumenters, object, before_hook_name, after_hook_name)
          begin
            successful = []
            instrumenters.each do |instrumenter|
              instrumenter.public_send(before_hook_name, object)
              successful << instrumenter
            end

            # if any before hooks raise an exception, quit calling before hooks,
            # but call the after hooks on anything that succeeded but also
            # raise the exception that came from the before hook.
          rescue GraphQL::ExecutionError => err
            object.context.errors << err
          rescue => e
            raise call_after_hooks(successful, object, after_hook_name, e)
          end

          begin
            yield # Call the user code
          ensure
            ex = call_after_hooks(successful, object, after_hook_name, nil)
            raise ex if ex
          end
        end

        def call_after_hooks(instrumenters, object, after_hook_name, ex)
          instrumenters.reverse_each do |instrumenter|
            begin
              instrumenter.public_send(after_hook_name, object)
            rescue => e
              ex = e
            end
          end
          ex
        end
      end
    end
  end
end
