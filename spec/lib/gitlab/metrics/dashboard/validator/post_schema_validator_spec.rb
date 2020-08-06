# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Metrics::Dashboard::Validator::PostSchemaValidator do
  describe '#validate' do
    context 'unique metric ids' do
      it 'returns blank array' do
        expect(described_class.new(metric_ids: [1, 2, 3]).validate).to eq([])
      end
    end

    context 'duplicate metric ids' do
      it 'raises error' do
        expect(described_class.new(metric_ids: [1, 1]).validate)
          .to eq([Gitlab::Metrics::Dashboard::Validator::Errors::DuplicateMetricIds])
      end
    end
  end
end
