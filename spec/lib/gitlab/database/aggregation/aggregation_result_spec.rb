# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Database::Aggregation::AggregationResult, feature_category: :value_stream_management do
  subject(:result) { described_class.new(nil, nil, nil) }

  it { is_expected.to require_method_definition(:load_data) }

  describe '#count' do
    it 'raises NoMethodError as load_count is not implemented' do
      expect { result.count }.to raise_error(NoMethodError)
    end

    it 'measures the count query' do
      expect(Gitlab::Metrics::AggregationEngineSlis).to receive(:measure)
        .with(engine: nil, query_type: :count).and_call_original

      expect { result.count }.to raise_error(NoMethodError)
    end
  end

  describe '#to_a' do
    it 'measures the data query' do
      expect(Gitlab::Metrics::AggregationEngineSlis).to receive(:measure)
        .with(engine: nil, query_type: :data).and_call_original

      expect { result.to_a }.to raise_error(NoMethodError)
    end
  end
end
