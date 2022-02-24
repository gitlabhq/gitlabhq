# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::UsageDataCounters::WorkItemActivityUniqueCounter, :clean_gitlab_redis_shared_state do
  let(:user) { build(:user, id: 1) }

  shared_examples 'counter that does not track the event' do
    it 'does not track the event' do
      expect { 3.times { track_event } }.to not_change {
        Gitlab::UsageDataCounters::HLLRedisCounter.unique_events(
          event_names: event_name,
          start_date: 2.weeks.ago,
          end_date: 2.weeks.from_now
        )
      }
    end
  end

  shared_examples 'work item unique counter' do
    context 'when track_work_items_activity FF is enabled' do
      it 'tracks a unique event only once' do
        expect { 3.times { track_event } }.to change {
          Gitlab::UsageDataCounters::HLLRedisCounter.unique_events(
            event_names: event_name,
            start_date: 2.weeks.ago,
            end_date: 2.weeks.from_now
          )
        }.by(1)
      end

      context 'when author is nil' do
        let(:user) { nil }

        it_behaves_like 'counter that does not track the event'
      end
    end

    context 'when track_work_items_activity FF is disabled' do
      before do
        stub_feature_flags(track_work_items_activity: false)
      end

      it_behaves_like 'counter that does not track the event'
    end
  end

  describe '.track_work_item_created_action' do
    subject(:track_event) { described_class.track_work_item_created_action(author: user) }

    let(:event_name) { described_class::WORK_ITEM_CREATED }

    it_behaves_like 'work item unique counter'
  end

  describe '.track_work_item_title_changed_action' do
    subject(:track_event) { described_class.track_work_item_title_changed_action(author: user) }

    let(:event_name) { described_class::WORK_ITEM_TITLE_CHANGED }

    it_behaves_like 'work item unique counter'
  end
end
