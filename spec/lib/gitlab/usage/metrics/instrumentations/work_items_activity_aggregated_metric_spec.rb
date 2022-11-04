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
          users_updating_work_item_labels
          users_updating_work_item_milestone
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
      let(:author1_id) { 1 }
      let(:author2_id) { 2 }
      let(:event_time) { 1.week.ago }

      before do
        counter.track_event(:users_creating_work_items, values: author1_id, time: event_time)
      end

      it 'has correct value after events are tracked', :aggregate_failures do
        expect do
          counter.track_event(:users_updating_work_item_title, values: author1_id, time: event_time)
          counter.track_event(:users_updating_work_item_dates, values: author1_id, time: event_time)
          counter.track_event(:users_updating_work_item_labels, values: author1_id, time: event_time)
          counter.track_event(:users_updating_work_item_milestone, values: author1_id, time: event_time)
        end.to not_change { described_class.new(metric_definition).value }

        expect do
          counter.track_event(:users_updating_work_item_iteration, values: author2_id, time: event_time)
          counter.track_event(:users_updating_weight_estimate, values: author1_id, time: event_time)
        end.to change { described_class.new(metric_definition).value }.from(1).to(2)
      end
    end
  end
end
