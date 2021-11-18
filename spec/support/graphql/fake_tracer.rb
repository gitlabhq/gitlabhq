# frozen_string_literal: true

module Graphql
  class FakeTracer
    def initialize(trace_callback)
      @trace_callback = trace_callback
    end

    def trace(*args)
      @trace_callback.call(*args)

      yield
    end
  end
end
