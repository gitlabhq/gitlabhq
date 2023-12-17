# frozen_string_literal: true

require 'spec_helper'

RSpec.describe WorkItems::DatesSource, feature_category: :portfolio_management do
  describe 'ssociations' do
    it { is_expected.to belong_to(:namespace).inverse_of(:work_items_dates_source) }
    it { is_expected.to belong_to(:work_item).with_foreign_key('issue_id').inverse_of(:dates_source) }
    it { is_expected.to belong_to(:due_date_sourcing_work_item).class_name('WorkItem') }
    it { is_expected.to belong_to(:start_date_sourcing_work_item).class_name('WorkItem') }
    it { is_expected.to belong_to(:due_date_sourcing_milestone).class_name('Milestone') }
    it { is_expected.to belong_to(:start_date_sourcing_milestone).class_name('Milestone') }
  end

  it 'ensures to use work_item namespace' do
    work_item = create(:work_item)
    date_source = described_class.new(work_item: work_item)

    date_source.valid?

    expect(date_source.namespace).to eq(work_item.namespace)
  end
end
