# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Usage::Metrics::Aggregates::Sources::RedisHll do
  let_it_be(:event_names) { %w[event_a event_b] }
  let_it_be(:start_date) { 7.days.ago }
  let_it_be(:end_date) { Date.current }
  let_it_be(:recorded_at) { Time.current }
  let_it_be(:property_name) { 'property_name' }

  describe '.calculate_events_union' do
    subject(:calculate_metrics_union) do
      described_class.calculate_metrics_union(metric_names: event_names, start_date: start_date, end_date: end_date, recorded_at: nil, property_name: property_name)
    end

    it 'calls Gitlab::UsageDataCounters::HLLRedisCounter.calculate_events_union' do
      expect(Gitlab::UsageDataCounters::HLLRedisCounter).to receive(:calculate_events_union)
                                                              .with(event_names: event_names, start_date: start_date, end_date: end_date, property_name: property_name)
                                                              .and_return(5)

      calculate_metrics_union
    end

    it 'prevents from using fallback value as valid union result' do
      allow(Gitlab::UsageDataCounters::HLLRedisCounter).to receive(:calculate_events_union).and_return(-1)

      expect { calculate_metrics_union }.to raise_error Gitlab::Usage::Metrics::Aggregates::Sources::UnionNotAvailable
    end
  end
end
