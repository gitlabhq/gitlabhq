# frozen_string_literal: true

module GraphQL
  module Tracing
    class DetailedTrace
      # An in-memory trace storage backend. Suitable for testing and development only.
      # It won't work for multi-process deployments and everything is erased when the app is restarted.
      class MemoryBackend
        def initialize(limit: nil)
          @limit = limit
          @traces = {}
          @next_id = 0
        end

        def traces(last:, before:)
          page = []
          @traces.values.reverse_each do |trace|
            if page.size == last
              break
            elsif before.nil? || trace.begin_ms < before
              page << trace
            end
          end
          page
        end

        def find_trace(id)
          @traces[id]
        end

        def delete_trace(id)
          @traces.delete(id.to_i)
          nil
        end

        def delete_all_traces
          @traces.clear
          nil
        end

        def save_trace(operation_name, duration, begin_ms, trace_data)
          id = @next_id
          @next_id += 1
          @traces[id] = DetailedTrace::StoredTrace.new(
            id: id,
            operation_name: operation_name,
            duration_ms: duration,
            begin_ms: begin_ms,
            trace_data: trace_data
          )
          if @limit && @traces.size > @limit
            del_keys = @traces.keys[0...-@limit]
            del_keys.each { |k| @traces.delete(k) }
          end
          id
        end
      end
    end
  end
end
