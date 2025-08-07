# frozen_string_literal: true

require "spec_helper"

RSpec.describe WorkItems::Transition, feature_category: :team_planning do
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
end
