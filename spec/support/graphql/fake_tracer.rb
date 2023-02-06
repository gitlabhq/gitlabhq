# frozen_string_literal: true

module Graphql
  class FakeTracer
    def initialize(trace_callback)
      @trace_callback = trace_callback
    end

    def trace(...)
      @trace_callback.call(...)

      yield
    end
  end
end
