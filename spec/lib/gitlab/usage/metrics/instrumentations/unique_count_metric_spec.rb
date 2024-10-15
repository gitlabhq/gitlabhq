# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Usage::Metrics::Instrumentations::UniqueCountMetric, :clean_gitlab_redis_shared_state,
  feature_category: :product_analytics do
  let(:metric_definition) do
    instance_double("Gitlab::Usage::MetricDefinition", event_selection_rules: event_selection_rules)
  end

  let(:event_selection_rule1) { instance_double("Gitlab::Usage::EventSelectionRule") }
  let(:event_selection_rule2) { instance_double("Gitlab::Usage::EventSelectionRule") }
  let(:event_selection_rules) { [event_selection_rule1, event_selection_rule2] }
  let(:time_frame) { '28d' }
  let(:keys1) { %w[key_2024-19 key_2024-21] }
  let(:keys2) { %w[key_2024-20 key_2024-21] }

  before do
    allow(event_selection_rule1).to receive(:redis_keys_for_time_frame).with(time_frame).and_return(keys1)
    allow(event_selection_rule2).to receive(:redis_keys_for_time_frame).with(time_frame).and_return(keys2)
    allow(Gitlab::Usage::MetricDefinition).to receive(:new).and_return(metric_definition)
  end

  describe '#value' do
    it 'returns the unique count of all keys from Redis' do
      all_keys = %w[key_2024-19 key_2024-20 key_2024-21]
      expect(Gitlab::Redis::HLL).to receive(:count).with(keys: contain_exactly(*all_keys)).and_return(42)

      expect(described_class.new(metric_definition: metric_definition, time_frame: time_frame).value).to eq(42)
    end
  end
end
