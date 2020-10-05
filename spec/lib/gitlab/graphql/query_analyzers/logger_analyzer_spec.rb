# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Graphql::QueryAnalyzers::LoggerAnalyzer do
  subject { described_class.new }

  describe '#analyze?' do
    context 'feature flag disabled' do
      before do
        stub_feature_flags(graphql_logging: false)
      end

      it 'disables the analyzer' do
        expect(subject.analyze?(anything)).to be_falsey
      end
    end

    context 'feature flag enabled by default' do
      let(:monotonic_time_before) { 42 }
      let(:monotonic_time_after) { 500 }
      let(:monotonic_time_duration) { monotonic_time_after - monotonic_time_before }

      it 'enables the analyzer' do
        expect(subject.analyze?(anything)).to be_truthy
      end

      it 'returns a duration in seconds' do
        allow(GraphQL::Analysis).to receive(:analyze_query).and_return([4, 2, [[], []]])
        allow(Gitlab::Metrics::System).to receive(:monotonic_time).and_return(monotonic_time_before, monotonic_time_after)
        allow(Gitlab::GraphqlLogger).to receive(:info)

        expected_duration = monotonic_time_duration
        memo = subject.initial_value(spy('query'))

        subject.final_value(memo)

        expect(memo).to have_key(:duration_s)
        expect(memo[:duration_s]).to eq(expected_duration)
      end
    end
  end
end
