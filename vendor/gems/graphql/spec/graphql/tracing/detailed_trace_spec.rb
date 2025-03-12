# frozen_string_literal: true
require "spec_helper"

describe GraphQL::Tracing::DetailedTrace do
  class SamplerSchema < GraphQL::Schema
    class Query < GraphQL::Schema::Object
      field :truthy, Boolean, fallback_value: true
    end

    query(Query)
    use GraphQL::Tracing::DetailedTrace, memory: true
    def self.detailed_trace?(query)
      if query.is_a?(GraphQL::Execution::Multiplex)
        query.queries.all? { |q| q.context[:profile] != false }
      else
        query.context[:profile] != false
      end
    end
  end

  before do
    SamplerSchema.detailed_trace.delete_all_traces
  end

  it "runs when the configured trace mode is set" do
    assert_equal 0, SamplerSchema.detailed_trace.traces.size
    res = SamplerSchema.execute("{ truthy }", context: { profile: false })
    assert_equal true, res["data"]["truthy"]
    assert_equal 0, SamplerSchema.detailed_trace.traces.size

    SamplerSchema.execute("{ truthy }")
    assert_equal 1, SamplerSchema.detailed_trace.traces.size
  end

  it "calls through to storage for access methods" do
    SamplerSchema.execute("{ truthy }")
    id = SamplerSchema.detailed_trace.traces.first.id
    assert_kind_of GraphQL::Tracing::DetailedTrace::StoredTrace, SamplerSchema.detailed_trace.find_trace(id)
    SamplerSchema.detailed_trace.delete_trace(id)
    assert_equal 0, SamplerSchema.detailed_trace.traces.size

    SamplerSchema.execute("{ truthy }")
    assert_equal 1, SamplerSchema.detailed_trace.traces.size
    SamplerSchema.detailed_trace.delete_all_traces
  end

  it "raises when no storage is configured" do
    err = assert_raises ArgumentError do
      Class.new(GraphQL::Schema) do
        use GraphQL::Tracing::DetailedTrace
      end
    end
    assert_equal "Pass `redis: ...` to store traces in Redis for later review", err.message
  end

  it "calls detailed_profile? on a Multiplex" do
    assert_equal 0, SamplerSchema.detailed_trace.traces.size

    SamplerSchema.multiplex([
      { query: "{ truthy }", context: { profile: false } },
      { query: "{ truthy }", context: { profile: true } },
    ])
    assert_equal 0, SamplerSchema.detailed_trace.traces.size

    SamplerSchema.multiplex([
      { query: "{ truthy }", context: { profile: true } },
      { query: "{ truthy }", context: { profile: true } },
    ])
    assert_equal 1, SamplerSchema.detailed_trace.traces.size
  end
end
