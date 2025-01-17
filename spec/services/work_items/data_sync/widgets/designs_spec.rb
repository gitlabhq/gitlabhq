# frozen_string_literal: true

require 'spec_helper'

RSpec.describe WorkItems::DataSync::Widgets::Designs, feature_category: :team_planning do
  let_it_be(:current_user) { create(:user) }
  let_it_be(:work_item) { create(:work_item) }
  let_it_be_with_refind(:target_work_item) { create(:work_item) }
  let_it_be(:design) { create(:design, :with_versions, issue: work_item) }

  subject(:callback) do
    described_class.new(
      work_item: work_item, target_work_item: target_work_item, current_user: current_user, params: {}
    )
  end

  describe '#after_save_commit' do
    subject(:after_save_commit) { callback.after_save_commit }

    shared_examples 'does not copy designs' do
      it 'does not call the worker' do
        expect(DesignManagement::CopyDesignCollectionWorker).not_to receive(:perform_async)

        after_save_commit
      end
    end

    context 'when target work item does not have designs widget' do
      before do
        allow(target_work_item).to receive(:get_widget).with(:designs).and_return(false)
      end

      it_behaves_like 'does not copy designs'
    end

    context "when work_item does not have designs" do
      before do
        work_item.designs.delete_all
      end

      it_behaves_like 'does not copy designs'
    end

    context "when user does not have permissions to read designs" do
      it "logs the error message" do
        expect(::Gitlab::AppLogger).to receive(:error).with("User cannot copy designs to work item")

        after_save_commit
      end

      it_behaves_like 'does not copy designs'
    end

    context "when user has permission to read designs", :clean_gitlab_redis_shared_state do
      before do
        allow(current_user).to receive(:can?).with(:read_design, work_item).and_return(true)
        allow(current_user).to receive(:can?).with(:admin_issue, target_work_item).and_return(true)
      end

      context "when target design collection copy state is not ready" do
        before do
          target_work_item.design_collection.start_copy!
        end

        it "logs the error message" do
          expect(::Gitlab::AppLogger).to receive(:error).with("Target design collection copy state must be `ready`")

          after_save_commit
        end

        it_behaves_like 'does not copy designs'
      end

      context 'when target work item has designs widget' do
        it 'calls the copy design collection worker' do
          expect(DesignManagement::CopyDesignCollectionWorker).to receive(:perform_async).with(
            current_user.id,
            work_item.id,
            target_work_item.id
          )

          after_save_commit
        end

        it 'sets the correct design collection copy state' do
          expect { after_save_commit }.to change {
            target_work_item.design_collection.copy_state
          }.from('ready').to('in_progress')
        end
      end
    end
  end

  describe '#post_move_cleanup' do
    let_it_be(:designs) { create_list(:design, 3, :with_versions, issue: work_item) }

    it "deletes the original work item design data" do
      actions = DesignManagement::Action.where(design: work_item.designs)

      expect { callback.post_move_cleanup }.to change { work_item.designs.count }.from(4).to(0)
        .and change { work_item.design_versions.count }.from(4).to(0)
        .and change { actions.reload.count }.from(4).to(0)
    end
  end
end
