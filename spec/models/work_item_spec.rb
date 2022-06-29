# frozen_string_literal: true

require 'spec_helper'

RSpec.describe WorkItem do
  describe 'associations' do
    it { is_expected.to have_one(:work_item_parent).class_name('WorkItem') }

    it 'has one `parent_link`' do
      is_expected.to have_one(:parent_link)
        .class_name('::WorkItems::ParentLink')
        .with_foreign_key('work_item_id')
    end

    it 'has many `work_item_children`' do
      is_expected.to have_many(:work_item_children)
        .class_name('WorkItem')
        .with_foreign_key('work_item_id')
    end

    it 'has many `child_links`' do
      is_expected.to have_many(:child_links)
        .class_name('::WorkItems::ParentLink')
        .with_foreign_key('work_item_parent_id')
    end
  end

  describe '#noteable_target_type_name' do
    it 'returns `issue` as the target name' do
      work_item = build(:work_item)

      expect(work_item.noteable_target_type_name).to eq('issue')
    end
  end

  describe '#widgets' do
    subject { build(:work_item).widgets }

    it 'returns instances of supported widgets' do
      is_expected.to match_array([instance_of(WorkItems::Widgets::Description),
                                  instance_of(WorkItems::Widgets::Hierarchy),
                                  instance_of(WorkItems::Widgets::Assignees)])
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
