# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Usage::Metrics::Instrumentations::TotalSumMetric, :clean_gitlab_redis_shared_state,
  feature_category: :product_analytics do
  let(:time_frame) { 'all' }
  let(:event_selection_rule) do
    instance_double(Gitlab::Usage::EventSelectionRule, redis_keys_for_time_frame: %w[key1 key2])
  end

  let(:metric_definition) do
    instance_double(
      Gitlab::Usage::MetricDefinition,
      event_selection_rules: [event_selection_rule]
    )
  end

  let(:redis) { instance_double(Redis) }

  subject(:metric) do
    described_class.new({ time_frame: time_frame }).tap do |instance|
      allow(instance).to receive(:metric_definition).and_return(metric_definition)
    end
  end

  describe '#value' do
    before do
      allow(Gitlab::Redis::SharedState).to receive(:with).and_yield(redis)
      allow(redis).to receive(:get).with('key1').and_return(11.1)
      allow(redis).to receive(:get).with('key2').and_return(20.2)
    end

    it 'calculates the total sum from Redis keys' do
      expect(metric.value).to be_within(0.00001).of(31.3)
    end

    context 'when there are no keys' do
      before do
        allow(metric_definition).to receive(:event_selection_rules).and_return([])
      end

      it 'returns zero' do
        expect(metric.value).to eq(0)
      end
    end
  end
end
