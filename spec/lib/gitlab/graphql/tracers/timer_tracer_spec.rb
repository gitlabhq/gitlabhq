# frozen_string_literal: true
require "fast_spec_helper"

RSpec.describe Gitlab::Graphql::Tracers::TimerTracer do
  let(:expected_duration) { 5 }
  let(:tracer_spy) { spy('tracer_spy') }
  let(:dummy_schema) do
    schema = Class.new(GraphQL::Schema) do
      use Gitlab::Graphql::Tracers::TimerTracer

      query Graphql::FakeQueryType
    end

    schema.tracer(Graphql::FakeTracer.new(lambda { |*args| tracer_spy.trace(*args) }))

    schema
  end

  before do
    current_time = 0
    allow(tracer_spy).to receive(:trace)
    allow(Gitlab::Metrics::System).to receive(:monotonic_time) do
      current_time += expected_duration
    end
  end

  it "adds duration_s to the trace metadata", :aggregate_failures do
    query_string = "query fooOperation { helloWorld }"

    dummy_schema.execute(query_string)

    expect_to_have_traced(tracer_spy, expected_duration, query_string)
  end

  it "adds a duration_s even if the query failed" do
    query_string = "query fooOperation { breakingField }"

    expect { dummy_schema.execute(query_string) }.to raise_error(/This field is supposed to break/)

    expect_to_have_traced(tracer_spy, expected_duration, query_string)
  end

  def expect_to_have_traced(tracer_spy, expected_duration, query_string)
    # "parse" and "execute_query" are just arbitrary trace events
    expect(tracer_spy).to have_received(:trace).with("parse", {
      duration_s: expected_duration,
      query_string: query_string
    })
    expect(tracer_spy).to have_received(:trace).with("execute_query", {
      # greater than expected duration because other calls made to `.monotonic_time` are outside our control
      duration_s: be >= expected_duration,
      query: instance_of(GraphQL::Query)
    })
  end
end
