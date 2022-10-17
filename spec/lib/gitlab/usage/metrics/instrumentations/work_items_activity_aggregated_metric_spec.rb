# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Usage::Metrics::Instrumentations::WorkItemsActivityAggregatedMetric do
  let(:metric_definition) do
    {
      data_source: 'redis_hll',
      time_frame: time_frame,
      options: {
        aggregate: {
          operator: 'OR'
        },
        events: %w[
          users_creating_work_items
          users_updating_work_item_title
          users_updating_work_item_dates
          users_updating_work_item_iteration
        ]
      }
    }
  end

  around do |example|
    freeze_time { example.run }
  end

  where(:time_frame) { [['28d'], ['7d']] }

  with_them do
    describe '#available?' do
      it 'returns false without track_work_items_activity feature' do
        stub_feature_flags(track_work_items_activity: false)

        expect(described_class.new(metric_definition).available?).to eq(false)
      end

      it 'returns true with track_work_items_activity feature' do
        stub_feature_flags(track_work_items_activity: true)

        expect(described_class.new(metric_definition).available?).to eq(true)
      end
    end

    describe '#value', :clean_gitlab_redis_shared_state do
      let(:counter) { Gitlab::UsageDataCounters::HLLRedisCounter }

      before do
        counter.track_event(:users_creating_work_items, values: 1, time: 1.week.ago)
        counter.track_event(:users_updating_work_item_title, values: 1, time: 1.week.ago)
        counter.track_event(:users_updating_work_item_dates, values: 2, time: 1.week.ago)
        counter.track_event(:users_updating_work_item_iteration, values: 2, time: 1.week.ago)
      end

      it 'has correct value' do
        expect(described_class.new(metric_definition).value).to eq 2
      end
    end
  end
end
