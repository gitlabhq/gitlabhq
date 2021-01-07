# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::UsageDataCounters::MergeRequestActivityUniqueCounter, :clean_gitlab_redis_shared_state do
  let(:merge_request) { build(:merge_request, id: 1) }
  let(:user) { build(:user, id: 1) }

  shared_examples_for 'a tracked merge request unique event' do
    specify do
      expect { 3.times { subject } }
        .to change {
          Gitlab::UsageDataCounters::HLLRedisCounter.unique_events(
            event_names: action,
            start_date: 2.weeks.ago,
            end_date: 2.weeks.from_now
          )
        }
        .by(1)
    end
  end

  describe '.track_mr_diffs_action' do
    subject { described_class.track_mr_diffs_action(merge_request: merge_request) }

    it_behaves_like 'a tracked merge request unique event' do
      let(:action) { described_class::MR_DIFFS_ACTION }
    end
  end

  describe '.track_mr_diffs_single_file_action' do
    subject { described_class.track_mr_diffs_single_file_action(merge_request: merge_request, user: user) }

    it_behaves_like 'a tracked merge request unique event' do
      let(:action) { described_class::MR_DIFFS_SINGLE_FILE_ACTION }
    end

    it_behaves_like 'a tracked merge request unique event' do
      let(:action) { described_class::MR_DIFFS_USER_SINGLE_FILE_ACTION }
    end
  end

  describe '.track_create_mr_action' do
    subject { described_class.track_create_mr_action(user: user) }

    it_behaves_like 'a tracked merge request unique event' do
      let(:action) { described_class::MR_CREATE_ACTION }
    end
  end

  describe '.track_close_mr_action' do
    subject { described_class.track_close_mr_action(user: user) }

    it_behaves_like 'a tracked merge request unique event' do
      let(:action) { described_class::MR_CLOSE_ACTION }
    end
  end

  describe '.track_merge_mr_action' do
    subject { described_class.track_merge_mr_action(user: user) }

    it_behaves_like 'a tracked merge request unique event' do
      let(:action) { described_class::MR_MERGE_ACTION }
    end
  end

  describe '.track_reopen_mr_action' do
    subject { described_class.track_reopen_mr_action(user: user) }

    it_behaves_like 'a tracked merge request unique event' do
      let(:action) { described_class::MR_REOPEN_ACTION }
    end
  end
end
