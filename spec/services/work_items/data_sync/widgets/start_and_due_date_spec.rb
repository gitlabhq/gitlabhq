# frozen_string_literal: true

require 'spec_helper'

RSpec.describe WorkItems::DataSync::Widgets::StartAndDueDate, feature_category: :team_planning do
  let_it_be(:current_user) { create(:user) }
  let_it_be_with_reload(:work_item) { create(:work_item, start_date: 1.week.ago, due_date: nil) }
  let_it_be_with_reload(:target_work_item) { create(:work_item) }

  subject(:callback) do
    described_class.new(
      work_item: work_item, target_work_item: target_work_item, current_user: current_user, params: {}
    )
  end

  describe '#after_create' do
    context 'when target work item does not have start_and_due_date widget' do
      before do
        allow(target_work_item).to receive(:get_widget).with(:start_and_due_date).and_return(false)
      end

      it 'does not copy dates source data' do
        expect { callback.after_create }.not_to change { target_work_item.dates_source }
      end
    end

    context 'when target work item has start_and_due_date widget' do
      context 'when work item does not have dates source' do
        it 'builds date source from target work item data' do
          expect { callback.after_create }.to change { target_work_item.reload.dates_source }.from(nil).to(
            have_attributes(
              {
                issue_id: target_work_item.id,
                namespace_id: target_work_item.namespace_id,
                start_date_is_fixed: true,
                due_date_is_fixed: true,
                start_date: work_item.start_date,
                due_date: work_item.due_date
              }
            )
          )
        end
      end

      context 'when work item has dates source' do
        let_it_be(:dates_source) do
          create(
            :work_items_dates_source, work_item: work_item,
            start_date: nil, start_date_fixed: nil,
            due_date: nil, due_date_fixed: 1.week.from_now,
            start_date_is_fixed: true,
            due_date_is_fixed: true
          )
        end

        it 'copies the dates source data' do
          expect(target_work_item.dates_source).to be_nil

          callback.after_create

          target_dates_source = target_work_item.reload.dates_source

          expect(target_dates_source).not_to be_nil
          expect(target_dates_source.start_date).to eq(work_item.start_date)
          expect(target_dates_source.due_date).to eq(work_item.due_date)
          expect(target_dates_source.start_date_fixed).to eq(dates_source.start_date_fixed)
          expect(target_dates_source.due_date_fixed).to eq(dates_source.due_date_fixed)
          expect(target_dates_source.start_date_is_fixed).to eq(dates_source.start_date_is_fixed)
          expect(target_dates_source.due_date_is_fixed).to eq(dates_source.due_date_is_fixed)
        end

        it 'excludes namespace_id and issue_id from copied attributes' do
          callback.after_create

          target_dates_source = target_work_item.dates_source

          expect(target_dates_source.namespace_id).not_to eq(dates_source.namespace_id)
          expect(target_dates_source.issue_id).not_to eq(dates_source.issue_id)
        end
      end
    end
  end

  describe '#post_move_cleanup' do
    context 'when work item does not have dates source' do
      it 'does not destroy any dates source' do
        expect { callback.post_move_cleanup }.not_to change { WorkItems::DatesSource.count }
      end
    end

    context 'when work item has dates source' do
      let!(:dates_source) { create(:work_items_dates_source, work_item: work_item) }

      it 'destroys the dates source' do
        expect { callback.post_move_cleanup }.to change { WorkItems::DatesSource.count }.by(-1)
      end
    end
  end
end
