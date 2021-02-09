# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Usage::Metrics::Aggregates::Sources::RedisHll do
  describe '.calculate_events_union' do
    let(:event_names) { %w[event_a event_b] }
    let(:start_date) { 7.days.ago }
    let(:end_date) { Date.current }

    subject(:calculate_metrics_union) do
      described_class.calculate_metrics_union(metric_names: event_names, start_date: start_date, end_date: end_date, recorded_at: nil)
    end

    it 'calls Gitlab::UsageDataCounters::HLLRedisCounter.calculate_events_union' do
      expect(Gitlab::UsageDataCounters::HLLRedisCounter).to receive(:calculate_events_union)
                                                              .with(event_names: event_names, start_date: start_date, end_date: end_date)
                                                              .and_return(5)

      calculate_metrics_union
    end

    it 'prevents from using fallback value as valid union result' do
      allow(Gitlab::UsageDataCounters::HLLRedisCounter).to receive(:calculate_events_union).and_return(-1)

      expect { calculate_metrics_union }.to raise_error Gitlab::Usage::Metrics::Aggregates::Sources::UnionNotAvailable
    end
  end
end
