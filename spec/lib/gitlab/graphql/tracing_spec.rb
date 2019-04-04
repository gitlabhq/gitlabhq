# frozen_string_literal: true

require 'spec_helper'

describe Gitlab::Graphql::Tracing do
  let(:graphql_duration_seconds_histogram) { double('Gitlab::Metrics::NullMetric') }

  it 'updates graphql histogram with expected labels' do
    query = 'query { users { id } }'
    tracer = described_class.new

    allow(tracer)
      .to receive(:graphql_duration_seconds)
      .and_return(graphql_duration_seconds_histogram)

    expect_metric('graphql.lex', 'lex')
    expect_metric('graphql.parse', 'parse')
    expect_metric('graphql.validate', 'validate')
    expect_metric('graphql.analyze', 'analyze_multiplex')
    expect_metric('graphql.execute', 'execute_query_lazy')
    expect_metric('graphql.execute', 'execute_multiplex')

    GitlabSchema.execute(query, context: { tracers: [tracer] })
  end

  private

  def expect_metric(platform_key, key)
    expect(graphql_duration_seconds_histogram)
      .to receive(:observe)
      .with({ platform_key: platform_key, key: key }, be > 0.0)
  end
end
