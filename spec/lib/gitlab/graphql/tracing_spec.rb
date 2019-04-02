# frozen_string_literal: true

require 'spec_helper'

describe Gitlab::Graphql::Tracing do
  let!(:graphql_duration_seconds) { double('Gitlab::Metrics::NullMetric') }

  before do
    allow(Gitlab::Metrics)
      .to receive(:histogram)
      .with(:graphql_duration_seconds, 'GraphQL execution time')
      .and_return(graphql_duration_seconds)
  end

  it 'updates graphql histogram with expected labels' do
    query = 'query { users { id } }'

    expect_metric('graphql.lex', 'lex')
    expect_metric('graphql.parse', 'parse')
    expect_metric('graphql.validate', 'validate')
    expect_metric('graphql.analyze', 'analyze_multiplex')
    expect_metric('graphql.execute', 'execute_query_lazy')
    expect_metric('graphql.execute', 'execute_multiplex')

    GitlabSchema.execute(query)
  end

  private

  def expect_metric(platform_key, key)
    expect(graphql_duration_seconds)
      .to receive(:observe)
      .with({ platform_key: platform_key, key: key }, be > 0.0)
  end
end
