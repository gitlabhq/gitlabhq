# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Graphql::Tracers::ApplicationContextTracer do
  let(:default_known_operations) { ::Gitlab::Graphql::KnownOperations.new(['fooOperation']) }
  let(:dummy_schema) do
    Class.new(GraphQL::Schema) do
      query Graphql::FakeQueryType
    end
  end

  let(:inner_tracer) { Module.new }
  let!(:context) do
    context = {}

    inner_tracer.define_method(:execute_query, ->(*) {
      context.merge!(Gitlab::ApplicationContext.current)
    })

    context
  end

  before do
    allow(::Gitlab::Graphql::KnownOperations).to receive(:default).and_return(default_known_operations)

    dummy_schema.trace_with inner_tracer
    dummy_schema.trace_with described_class
  end

  it "sets application context during execute_query and cleans up afterwards", :aggregate_failures do
    dummy_schema.execute("query fooOperation { helloWorld }")

    expect(context).to include("meta.caller_id" => "graphql:fooOperation")
    expect(Gitlab::ApplicationContext.current).not_to include("meta.caller_id")
  end

  it "sets caller_id when operation is not known" do
    dummy_schema.execute("query fuzz { helloWorld }")

    expect(context).to include("meta.caller_id" => "graphql:unknown")
  end
end
