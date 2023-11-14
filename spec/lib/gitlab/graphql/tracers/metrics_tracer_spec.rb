# frozen_string_literal: true

require 'spec_helper'
require 'rspec-parameterized'

RSpec.describe Gitlab::Graphql::Tracers::MetricsTracer do
  using RSpec::Parameterized::TableSyntax

  let(:default_known_operations) { ::Gitlab::Graphql::KnownOperations.new(%w[lorem foo bar]) }

  let(:fake_schema) do
    Class.new(GraphQL::Schema) do
      use Gitlab::Graphql::Tracers::ApplicationContextTracer
      use Gitlab::Graphql::Tracers::MetricsTracer
      use Gitlab::Graphql::Tracers::TimerTracer

      query Graphql::FakeQueryType
    end
  end

  around do |example|
    ::Gitlab::ApplicationContext.with_context(feature_category: 'test_feature_category') do
      example.run
    end
  end

  before do
    allow(::Gitlab::Graphql::KnownOperations).to receive(:default).and_return(default_known_operations)
  end

  describe 'when used as tracer and query is executed' do
    where(:duration, :expected_success) do
      0.1                                                          | true
      0.1 + ::Gitlab::EndpointAttributes::DEFAULT_URGENCY.duration | false
    end

    with_them do
      it 'increments apdex sli' do
        # Trigger initialization
        fake_schema

        # setup timer
        current_time = 0
        allow(Gitlab::Metrics::System).to receive(:monotonic_time) { current_time += duration }

        expect(Gitlab::Metrics::RailsSlis.graphql_query_apdex).to receive(:increment).with(
          labels: {
            endpoint_id: 'graphql:lorem',
            feature_category: 'test_feature_category',
            query_urgency: ::Gitlab::EndpointAttributes::DEFAULT_URGENCY.name
          },
          success: expected_success
        )

        fake_schema.execute("query lorem { helloWorld }")
      end
    end

    it "does not record apdex for failing queries" do
      query_string = "query fooOperation { breakingField }"

      expect(Gitlab::Metrics::RailsSlis.graphql_query_apdex).not_to receive(:increment)

      expect { fake_schema.execute(query_string) }.to raise_error(/This field is supposed to break/)
    end
  end
end
