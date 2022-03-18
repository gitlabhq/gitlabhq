# frozen_string_literal: true

require 'spec_helper'

RSpec.describe WorkItem do
  describe '#noteable_target_type_name' do
    it 'returns `issue` as the target name' do
      work_item = build(:work_item)

      expect(work_item.noteable_target_type_name).to eq('issue')
    end
  end

  describe 'callbacks' do
    describe 'record_create_action' do
      it 'records the creation action after saving' do
        expect(Gitlab::UsageDataCounters::WorkItemActivityUniqueCounter).to receive(:track_work_item_created_action)
        # During the work item transition we also want to track work items as issues
        expect(Gitlab::UsageDataCounters::IssueActivityUniqueCounter).to receive(:track_issue_created_action)

        create(:work_item)
      end
    end
  end
end
