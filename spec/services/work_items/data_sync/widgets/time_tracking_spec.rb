# frozen_string_literal: true

require 'spec_helper'

RSpec.describe WorkItems::DataSync::Widgets::TimeTracking, feature_category: :team_planning do
  let_it_be(:current_user) { create(:user) }
  let_it_be_with_reload(:work_item) { create(:work_item) }
  let_it_be_with_reload(:target_work_item) { create(:work_item) }
  let_it_be(:timelogs) { create_list(:timelog, 3, issue: work_item) }

  let(:params) { { operation: :move } }

  subject(:callback) do
    described_class.new(
      work_item: work_item, target_work_item: target_work_item, current_user: current_user, params: params
    )
  end

  describe '#before_create' do
    let_it_be(:work_item) { create(:work_item, time_estimate: 3600) }

    context 'when target work item has time_tracking widget' do
      before do
        allow(target_work_item).to receive(:get_widget).with(:time_tracking).and_return(true)
      end

      it "updates the time_estimate attributes in target work item" do
        expect { callback.before_create }.to change { target_work_item.time_estimate }.from(0).to(3600)
      end
    end

    context 'when target work item does not have time_tracking widget' do
      before do
        allow(target_work_item).to receive(:get_widget).with(:time_tracking).and_return(false)
      end

      it "does not update the time_estimate attributes in target work item" do
        expect { callback.before_create }.not_to change { target_work_item.time_estimate }
      end
    end
  end

  describe '#after_save_commit' do
    context 'when target work item has time_tracking widget' do
      before do
        allow(target_work_item).to receive(:get_widget).with(:time_tracking).and_return(true)
      end

      it 'calls the copy timelogs worker' do
        expect(WorkItems::CopyTimelogsWorker).to receive(:perform_async).with(work_item.id, target_work_item.id)

        callback.after_save_commit
      end

      context 'when cloning work item' do
        let(:params) { { operation: :clone } }

        it 'does not call the copy timelogs worker' do
          expect(WorkItems::CopyTimelogsWorker).not_to receive(:perform_async)

          callback.after_save_commit
        end
      end

      context "when work_item does not have timelogs" do
        before do
          work_item.timelogs.delete_all
        end

        it 'does not call the copy timelogs worker' do
          expect(WorkItems::CopyTimelogsWorker).not_to receive(:perform_async)

          callback.after_save_commit
        end
      end
    end

    context 'when target work item does not have time_tracking widget' do
      before do
        allow(target_work_item).to receive(:get_widget).with(:time_tracking).and_return(false)
      end

      it 'does not call the copy timelogs worker' do
        expect(WorkItems::CopyTimelogsWorker).not_to receive(:perform_async)

        callback.after_save_commit
      end
    end
  end

  describe '#post_move_cleanup' do
    it "deletes all the original work item timelog records" do
      expect { callback.post_move_cleanup }.to change { work_item.timelogs.count }.from(3).to(0)
    end
  end
end
