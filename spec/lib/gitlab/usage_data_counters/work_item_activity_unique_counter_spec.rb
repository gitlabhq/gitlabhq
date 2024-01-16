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

  describe '.track_work_item_date_changed_action' do
    subject(:track_event) { described_class.track_work_item_date_changed_action(author: user) }

    let(:event_name) { described_class::WORK_ITEM_DATE_CHANGED }

    it_behaves_like 'work item unique counter'
  end

  describe '.track_work_item_labels_changed_action' do
    subject(:track_event) { described_class.track_work_item_labels_changed_action(author: user) }

    let(:event_name) { described_class::WORK_ITEM_LABELS_CHANGED }

    it_behaves_like 'work item unique counter'
  end

  describe '.track_work_item_milestone_changed_action' do
    subject(:track_event) { described_class.track_work_item_milestone_changed_action(author: user) }

    let(:event_name) { described_class::WORK_ITEM_MILESTONE_CHANGED }

    it_behaves_like 'work item unique counter'
  end

  describe '.track_work_item_todo_marked_action' do
    subject(:track_event) { described_class.track_work_item_mark_todo_action(author: user) }

    let(:event_name) { described_class::WORK_ITEM_TODO_MARKED }

    it_behaves_like 'work item unique counter'
  end
end
