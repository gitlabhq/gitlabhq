# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Database::Aggregation::AggregationResult, feature_category: :database do
  subject(:result) { described_class.new(nil, nil, nil) }

  it { is_expected.to require_method_definition(:load_data) }

  describe '#count' do
    it 'raises NoMethodError as load_count is not implemented' do
      expect { result.count }.to raise_error(NoMethodError)
    end
  end
end
