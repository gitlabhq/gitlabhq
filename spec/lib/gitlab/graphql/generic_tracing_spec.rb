# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Graphql::GenericTracing do
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

  context "when labkit tracing is enabled" do
    before do
      expect(Labkit::Tracing).to receive(:enabled?).and_return(true)
    end

    it 'yields with labkit tracing' do
      expected_tags = {
        'component' => 'web',
        'span.kind' => 'server',
        'platform_key' => 'pkey',
        'key' => 'key'
      }

      expect(Labkit::Tracing)
        .to receive(:with_tracing)
        .with(operation_name: "pkey.key", tags: expected_tags)
        .and_yield

      expect { |b| described_class.new.platform_trace('pkey', 'key', nil, &b) }.to yield_control
    end
  end

  context "when labkit tracing is disabled" do
    before do
      expect(Labkit::Tracing).to receive(:enabled?).and_return(false)
    end

    it 'yields without measurement' do
      expect(Labkit::Tracing).not_to receive(:with_tracing)

      expect { |b| described_class.new.platform_trace('pkey', 'key', nil, &b) }.to yield_control
    end
  end

  private

  def expect_metric(platform_key, key)
    expect(graphql_duration_seconds_histogram)
      .to receive(:observe)
      .with({ platform_key: platform_key, key: key }, be > 0.0)
  end
end
