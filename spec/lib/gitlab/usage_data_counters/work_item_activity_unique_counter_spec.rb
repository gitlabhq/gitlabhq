# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::UsageDataCounters::WorkItemActivityUniqueCounter, :clean_gitlab_redis_shared_state do
  let(:user) { build(:user, id: 1) }

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
