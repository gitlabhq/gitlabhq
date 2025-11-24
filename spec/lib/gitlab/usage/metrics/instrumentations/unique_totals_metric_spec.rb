# frozen_string_literal: true

require 'fast_spec_helper'

RSpec.describe Gitlab::Usage::Metrics::Instrumentations::UniqueTotalsMetric, :clean_gitlab_redis_shared_state,
  feature_category: :product_analytics do
  let(:metric_definition) do
    instance_double(Gitlab::Usage::MetricDefinition, event_selection_rules: rules)
  end

  let(:rule1) { instance_double(Gitlab::Usage::EventSelectionRule) }
  let(:rule2) { instance_double(Gitlab::Usage::EventSelectionRule) }
  let(:rules) { [rule1, rule2] }
  let(:time_frame) { '28d' }
  let(:keys1) { %w[key_2024-19 key_2024-21] }
  let(:keys2) { %w[key_2024-20 key_2024-21] }
  let(:hash_data1) { { 'label1' => 3, 'label2' => 5 } }
  let(:hash_data2) { { 'label2' => 2, 'label3' => 7 } }

  subject(:metric) { described_class.new(metric_definition: metric_definition, time_frame: time_frame) }

  before do
    allow(rule1).to receive(:redis_keys_for_time_frame).with(time_frame).and_return(keys1)
    allow(rule1).to receive(:unique_identifier_name).and_return(:identifier1)

    allow(rule2).to receive(:redis_keys_for_time_frame).with(time_frame).and_return(keys2)
    allow(rule2).to receive(:unique_identifier_name).and_return(:identifier2)

    allow(Gitlab::Usage::MetricDefinition).to receive(:new).and_return(metric_definition)
    allow(metric).to receive(:redis_usage_data).and_yield
    allow(metric).to receive(:get_hash).with('key_2024-19').and_return(hash_data1)
    allow(metric).to receive(:get_hash).with('key_2024-20').and_return(hash_data2)
    allow(metric).to receive(:get_hash).with('key_2024-21').and_return({})
  end

  describe '#value' do
    it 'returns hash counts for each event selection rule' do
      result = metric.value

      expect(result).to be_a(Hash)
      expect(result.keys).to contain_exactly('identifier1', 'identifier2')
      expect(result['identifier1']).to eq(hash_data1)
      expect(result['identifier2']).to eq(hash_data2)
    end

    context 'when keys have overlapping hash values' do
      before do
        allow(metric).to receive(:get_hash).with('key_2024-19').and_return(hash_data1)
        allow(metric).to receive(:get_hash).with('key_2024-21').and_return(hash_data2)
      end

      it 'sums the values for duplicate hash keys' do
        result = metric.value

        expect(result['identifier1']).to eq({
          'label1' => 3,
          'label2' => 7,
          'label3' => 7
        })
      end
    end
  end
end
