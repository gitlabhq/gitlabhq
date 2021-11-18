# frozen_string_literal: true
require "fast_spec_helper"
require "support/graphql/fake_query_type"

RSpec.describe Gitlab::Graphql::Tracers::LoggerTracer do
  let(:dummy_schema) do
    Class.new(GraphQL::Schema) do
      # LoggerTracer depends on TimerTracer
      use Gitlab::Graphql::Tracers::LoggerTracer
      use Gitlab::Graphql::Tracers::TimerTracer

      query_analyzer Gitlab::Graphql::QueryAnalyzers::LoggerAnalyzer.new

      query Graphql::FakeQueryType
    end
  end

  around do |example|
    Gitlab::ApplicationContext.with_context(caller_id: 'caller_a', feature_category: 'feature_a') do
      example.run
    end
  end

  it "logs every query", :aggregate_failures do
    variables = { name: "Ada Lovelace" }
    query_string = 'query fooOperation($name: String) { helloWorld(message: $name) }'

    # Build an actual query so we don't have to hardocde the "fingerprint" calculations
    query = GraphQL::Query.new(dummy_schema, query_string, variables: variables)

    expect(::Gitlab::GraphqlLogger).to receive(:info).with({
      "correlation_id" => anything,
      "meta.caller_id" => "caller_a",
      "meta.feature_category" => "feature_a",
      "query_analysis.duration_s" => kind_of(Numeric),
      "query_analysis.complexity" => 1,
      "query_analysis.depth" => 1,
      "query_analysis.used_deprecated_fields" => [],
      "query_analysis.used_fields" => ["FakeQuery.helloWorld"],
      duration_s: be > 0,
      is_mutation: false,
      operation_fingerprint: query.operation_fingerprint,
      operation_name: 'fooOperation',
      query_fingerprint: query.fingerprint,
      query_string: query_string,
      trace_type: "execute_query",
      variables: variables.to_s
    })

    dummy_schema.execute(query_string, variables: variables)
  end
end
