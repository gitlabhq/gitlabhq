# frozen_string_literal: true

require 'spec_helper'

RSpec.describe WorkItems::DatesSource, feature_category: :portfolio_management do
  describe 'associations' do
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

    expect(date_source).to be_valid

    expect(date_source.namespace).to eq(work_item.namespace)
  end

  describe 'before_save' do
    let_it_be(:work_item) { create(:work_item) }

    describe 'set_fixed_start_date' do
      context 'when start date is fixed' do
        it 'sets start_date to match fixed_start_date' do
          date_source =
            described_class.new(work_item: work_item, start_date_fixed: 1.day.ago, start_date_is_fixed: true)

          expect { date_source.save! }.to change { date_source.start_date }.from(nil).to(date_source.start_date_fixed)
        end
      end

      context 'when start date is not fixed' do
        it 'does not update start_date' do
          date_source =
            described_class.new(work_item: work_item, start_date_fixed: 1.day.ago, start_date_is_fixed: false)

          expect { date_source.save! }.to not_change { date_source.start_date }
        end
      end
    end

    describe 'set_fixed_due_date' do
      context 'when due date is fixed' do
        it 'sets due_date to match fixed_due_date' do
          date_source = described_class.new(work_item: work_item, due_date_fixed: 1.day.ago, due_date_is_fixed: true)

          expect { date_source.save! }.to change { date_source.due_date }.from(nil).to(date_source.due_date_fixed)
        end
      end

      context 'when start date is not fixed' do
        it 'does not update start_date' do
          date_source = described_class.new(work_item: work_item, due_date_fixed: 1.day.ago, due_date_is_fixed: false)

          expect { date_source.save! }.to not_change { date_source.due_date }
        end
      end
    end
  end

  context 'on database triggers' do
    let_it_be_with_reload(:work_item) { create(:work_item) }

    context 'on create' do
      it 'ensures to keep the issues table start_date and due_date columns updated' do
        date_source = described_class.new(
          work_item: work_item,
          start_date: 1.day.ago,
          due_date: 1.day.from_now
        )

        expect { date_source.save! }
          .to change { work_item.reload.start_date }.from(nil).to(date_source.start_date)
          .and change { work_item.reload.due_date }.from(nil).to(date_source.due_date)
      end
    end

    context 'on update' do
      it 'ensures to keep the issues table start_date and due_date columns updated' do
        start_date = 2.days.ago.to_date
        due_date = 2.days.from_now.to_date

        date_source = described_class.create!(
          work_item: work_item,
          start_date: start_date - 1.day,
          due_date: due_date + 1.day
        )

        expect { date_source.update!(start_date: start_date, due_date: due_date) }
          .to change { work_item.reload.start_date }.to(start_date)
          .and change { work_item.reload.due_date }.to(due_date)
      end
    end
  end
end
