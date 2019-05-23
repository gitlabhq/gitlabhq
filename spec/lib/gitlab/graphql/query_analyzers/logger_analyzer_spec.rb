# frozen_string_literal: true

require 'spec_helper'

describe Gitlab::Graphql::QueryAnalyzers::LoggerAnalyzer do
  subject { described_class.new }

  let!(:now) { Gitlab::Metrics::System.monotonic_time }

  before do
    allow(Gitlab::Metrics::System).to receive(:monotonic_time).and_return(now)
  end

  describe '#analyze?' do
    context 'feature flag disabled' do
      before do
        stub_feature_flags(graphql_logging: false)
      end

      it 'enables the analyzer' do
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
