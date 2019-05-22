# frozen_string_literal: true

require 'spec_helper'

describe Gitlab::Graphql::QueryAnalyzers::LoggerAnalyzer do
  subject { described_class.new }
  let(:query_string) { "abc" }
  let(:provided_variables) { { a: 1, b: 2, c: 3 } }
  let!(:now) { Gitlab::Metrics::System.monotonic_time }
  let(:complexity) { 4 }
  let(:depth) { 2 }
  let(:initial_values) do
    { time_started: now,
      query_string: query_string,
      variables: provided_variables,
      complexity: nil,
      depth: nil,
      duration: nil }
  end
  before do
    allow(Gitlab::Metrics::System).to receive(:monotonic_time).and_return(now)
  end

  describe '#analyze?' do
    context 'feature flag disabled' do
      before do
        stub_feature_flags(graphql_logging: false)
      end

      specify do
        expect(subject.analyze?(anything)).to be_falsey
      end
    end

    context 'feature flag enabled by default' do
      specify do
        expect(subject.analyze?(anything)).to be_truthy
      end
    end
  end
end
