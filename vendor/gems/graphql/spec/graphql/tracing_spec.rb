# frozen_string_literal: true
require "spec_helper"

describe GraphQL::Tracing do
  class DummyTraceable
    def initialize(*tracers)
      @tracers = tracers
    end

    include GraphQL::Tracing::Traceable
  end

  describe "#trace" do
    it "delivers the metadata to send_trace, with result and key" do
      returned_value = nil
      traceable = DummyTraceable.new(TestTracing)
      traces = TestTracing.with_trace  do
        returned_value = traceable.trace("something", { some_stuff: true }) do
          "do stuff"
        end
      end

      assert_equal 1, traces.length
      trace = traces.first
      assert_equal "something", trace[:key]
      assert_equal true, trace[:some_stuff]
      # Any override of .trace must return the block's return value
      assert_equal "do stuff", returned_value
    end

    module OtherRandomTracer
      CALLS = []

      def self.trace(key, metadata)
        CALLS << key.upcase
        yield
      end
    end

    it "calls multiple tracers" do
      OtherRandomTracer::CALLS.clear

      traceable = DummyTraceable.new(TestTracing, OtherRandomTracer)
      traces = TestTracing.with_trace do
        traceable.trace("stuff", { }) { :stuff }
      end

      assert_equal ["stuff"], traces.map { |t| t[:key] }
      assert_equal ["STUFF"], OtherRandomTracer::CALLS
    end
  end
end
