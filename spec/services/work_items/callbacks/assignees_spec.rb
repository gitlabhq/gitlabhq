# frozen_string_literal: true

require 'spec_helper'

RSpec.describe WorkItems::Callbacks::Assignees, :freeze_time, feature_category: :portfolio_management do
  let_it_be(:reporter) { create(:user) }
  let_it_be(:project) { create(:project, :private, reporters: reporter) }
  let_it_be(:new_assignee) { create(:user, guest_of: project) }

  let(:work_item) do
    create(:work_item, project: project, updated_at: 1.day.ago)
  end

  let(:current_user) { reporter }
  let(:params) { { assignee_ids: [new_assignee.id] } }

  describe '#before_update' do
    let(:service) { described_class.new(issuable: work_item, current_user: current_user, params: params) }

    subject(:before_update_callback) { service.before_update }

    it 'updates the assignees and sets updated_at to the current time' do
      before_update_callback

      expect(work_item.assignee_ids).to contain_exactly(new_assignee.id)
      expect(work_item.updated_at).to be_like_time(Time.current)
    end

    context 'when passing an empty array' do
      let(:params) { { assignee_ids: [] } }

      before do
        work_item.assignee_ids = [reporter.id]
      end

      it 'removes existing assignees' do
        before_update_callback

        expect(work_item.assignee_ids).to be_empty
        expect(work_item.updated_at).to be_like_time(Time.current)
      end
    end

    context 'when user does not have access' do
      let(:current_user) { create(:user) }

      it 'does not update the assignees' do
        before_update_callback

        expect(work_item.assignee_ids).to be_empty
        expect(work_item.updated_at).to be_like_time(1.day.ago)
      end
    end

    context 'when multiple assignees are given' do
      let(:params) { { assignee_ids: [new_assignee.id, reporter.id] } }

      context 'when work item allows multiple assignees' do
        before do
          allow(work_item).to receive(:allows_multiple_assignees?).and_return(true)
        end

        it 'sets all the given assignees' do
          before_update_callback

          expect(work_item.assignee_ids).to contain_exactly(new_assignee.id, reporter.id)
          expect(work_item.updated_at).to be_like_time(Time.current)
        end
      end

      context 'when work item does not allow multiple assignees' do
        before do
          allow(work_item).to receive(:allows_multiple_assignees?).and_return(false)
        end

        it 'only sets the first assignee' do
          before_update_callback

          expect(work_item.assignee_ids).to contain_exactly(new_assignee.id)
          expect(work_item.updated_at).to be_like_time(Time.current)
        end
      end
    end

    context 'when assignee does not have access to the work item' do
      let(:params) { { assignee_ids: [create(:user).id] } }

      it 'does not set the assignee' do
        before_update_callback

        expect(work_item.assignee_ids).to be_empty
        expect(work_item.updated_at).to be_like_time(1.day.ago)
      end
    end

    context 'when assignee ids are the same as the existing ones' do
      before do
        work_item.assignee_ids = [new_assignee.id]
      end

      it 'does not touch updated_at' do
        before_update_callback

        expect(work_item.assignee_ids).to contain_exactly(new_assignee.id)
        expect(work_item.updated_at).to be_like_time(1.day.ago)
      end
    end

    context 'when widget does not exist in new type' do
      let(:params) { {} }

      before do
        allow(service).to receive(:excluded_in_new_type?).and_return(true)
        work_item.assignee_ids = [new_assignee.id]
      end

      it "resets the work item's assignees" do
        before_update_callback

        expect(work_item.assignee_ids).to be_empty
      end
    end
  end
end
