# frozen_string_literal: true

require "spec_helper"

RSpec.describe WorkItems::Transition, feature_category: :team_planning do
  let_it_be(:project) { create(:project) }

  describe 'associations' do
    it { is_expected.to belong_to(:work_item) }
    it { is_expected.to belong_to(:namespace) }

    it { is_expected.to belong_to(:moved_to).class_name('WorkItem') }
    it { is_expected.to belong_to(:duplicated_to).class_name('WorkItem') }
  end

  it 'ensures to use work_item namespace' do
    work_item = create(:work_item)
    transition = described_class.new(work_item: work_item)

    expect(transition).to be_valid
    expect(transition.namespace).to eq(work_item.namespace)
  end

  # Syncing via `trigger_sync_work_item_transitions_from_issues`
  describe 'syncs to work_item_transition from issue' do
    let_it_be(:other_work_item) { create(:work_item, project: project) }

    it 'syncs moved_to_id' do
      work_item = create(:work_item, project: project, moved_to: other_work_item)

      expect(work_item.work_item_transition.moved_to).to eq(other_work_item)

      work_item.update!(moved_to: nil)

      expect(work_item.reload.work_item_transition.moved_to).to be_nil
    end

    it 'syncs duplicated_to_id' do
      work_item = create(:work_item, project: project, duplicated_to: other_work_item)

      expect(work_item.work_item_transition.duplicated_to).to eq(other_work_item)

      work_item.update!(duplicated_to: nil)

      expect(work_item.reload.work_item_transition.duplicated_to).to be_nil
    end
  end
end
