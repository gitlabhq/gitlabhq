# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Graphql::Tracers::ApplicationContextTracer do
  let(:tracer_spy) { spy('tracer_spy') }
  let(:default_known_operations) { ::Gitlab::Graphql::KnownOperations.new(['fooOperation']) }
  let(:dummy_schema) do
    schema = Class.new(GraphQL::Schema) do
      use Gitlab::Graphql::Tracers::ApplicationContextTracer

      query Graphql::FakeQueryType
    end

    fake_tracer = Graphql::FakeTracer.new(lambda do |key, *args|
      tracer_spy.trace(key, Gitlab::ApplicationContext.current)
    end)

    schema.tracer(fake_tracer)

    schema
  end

  before do
    allow(::Gitlab::Graphql::KnownOperations).to receive(:default).and_return(default_known_operations)
  end

  it "sets application context during execute_query and cleans up afterwards", :aggregate_failures do
    dummy_schema.execute("query fooOperation { helloWorld }")

    # "parse" is just an arbitrary trace event that isn't setting caller_id
    expect(tracer_spy).to have_received(:trace).with("parse", hash_excluding("meta.caller_id"))
    expect(tracer_spy).to have_received(:trace).with("execute_query", hash_including("meta.caller_id" => "graphql:fooOperation")).once
    expect(Gitlab::ApplicationContext.current).not_to include("meta.caller_id")
  end

  it "sets caller_id when operation is not known" do
    dummy_schema.execute("query fuzz { helloWorld }")

    expect(tracer_spy).to have_received(:trace).with("execute_query", hash_including("meta.caller_id" => "graphql:unknown")).once
  end
end
