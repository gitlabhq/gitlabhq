# frozen_string_literal: true
require "spec_helper"

RSpec.describe Gitlab::Graphql::Tracers::LoggerTracer do
  let(:dummy_schema) do
    Class.new(GraphQL::Schema) do
      # LoggerTracer depends on TimerTracer
      use Gitlab::Graphql::Tracers::LoggerTracer
      use Gitlab::Graphql::Tracers::TimerTracer

      query_analyzer Gitlab::Graphql::QueryAnalyzers::AST::LoggerAnalyzer

      query Graphql::FakeQueryType
    end
  end

  around do |example|
    Gitlab::ApplicationContext.with_context(caller_id: 'caller_a', feature_category: 'feature_a') do
      example.run
    end
  end

  it "logs every query", :aggregate_failures, :unlimited_max_formatted_output_length do
    variables = { name: "Ada Lovelace" }
    query_string = 'query fooOperation($name: String) { helloWorld(message: $name) }'

    # Build an actual query so we don't have to hardcode the "fingerprint" calculations
    query = GraphQL::Query.new(dummy_schema, query_string, variables: variables)

    expect(::Gitlab::GraphqlLogger).to receive(:info).with({
      "correlation_id" => anything,
      "meta.caller_id" => "caller_a",
      "meta.feature_category" => "feature_a",
      "query_analysis.duration_s" => kind_of(Numeric),
      "query_analysis.complexity" => 1,
      "query_analysis.depth" => 1,
      "query_analysis.used_deprecated_fields" => [],
      "query_analysis.used_deprecated_arguments" => [],
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

  it 'logs exceptions for breaking queries' do
    query_string = "query fooOperation { breakingField }"

    expect(::Gitlab::GraphqlLogger).to receive(:info).with(a_hash_including({
      'exception.message' => 'This field is supposed to break',
      'exception.class' => 'RuntimeError'
    }))

    expect { dummy_schema.execute(query_string) }.to raise_error(/This field is supposed to break/)
  end

  it 'logs token details on authenticated requests', :aggregate_failures do
    variables = { name: "Ada Lovelace" }
    query_string = 'query fooOperation($name: String) { helloWorld(message: $name) }'
    mock_token_info = { token_type: "PersonalAccessToken", token_id: "12345" }
    mock_request_env = { ::Gitlab::Auth::AuthFinders::API_TOKEN_ENV => mock_token_info }

    mock_request = instance_double(ActionDispatch::Request, env: mock_request_env)
    context = { request: mock_request }
    expect(::Gitlab::GraphqlLogger).to receive(:info).with(hash_including({
      token_type: mock_token_info[:token_type],
      token_id: mock_token_info[:token_id]
    }))
    dummy_schema.execute(query_string, variables: variables, context: context)
  end
end
