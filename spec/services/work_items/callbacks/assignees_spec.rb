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
  let(:service) { described_class.new(issuable: work_item, current_user: current_user, params: params) }

  shared_examples 'assignee callback' do
    it 'updates the assignees' do
      assignees_callback

      expect(work_item.assignee_ids).to contain_exactly(new_assignee.id)
    end

    context 'when passing an empty array' do
      let(:params) { { assignee_ids: [] } }

      before do
        work_item.assignee_ids = [reporter.id]
      end

      it 'removes existing assignees' do
        assignees_callback

        expect(work_item.assignee_ids).to be_empty
      end
    end

    context 'when user does not have access' do
      let(:current_user) { create(:user) }

      it 'does not update the assignees' do
        assignees_callback

        expect(work_item.assignee_ids).to be_empty
      end
    end

    context 'when multiple assignees are given' do
      let(:params) { { assignee_ids: [new_assignee.id, reporter.id] } }

      context 'when work item allows multiple assignees' do
        before do
          allow(work_item).to receive(:allows_multiple_assignees?).and_return(true)
        end

        it 'sets all the given assignees' do
          assignees_callback

          expect(work_item.assignee_ids).to contain_exactly(new_assignee.id, reporter.id)
        end
      end

      context 'when work item does not allow multiple assignees' do
        before do
          allow(work_item).to receive(:allows_multiple_assignees?).and_return(false)
        end

        it 'only sets the first assignee' do
          assignees_callback

          expect(work_item.assignee_ids).to contain_exactly(new_assignee.id)
        end
      end
    end

    context 'when assignee does not have access to the work item' do
      let(:params) { { assignee_ids: [create(:user).id] } }

      it 'does not set the assignee' do
        assignees_callback

        expect(work_item.assignee_ids).to be_empty
      end
    end

    context 'when assignee ids are the same as the existing ones' do
      before do
        work_item.assignee_ids = [new_assignee.id]
      end

      it 'does not touch updated_at' do
        assignees_callback

        expect(work_item.assignee_ids).to contain_exactly(new_assignee.id)
      end
    end

    context 'when widget does not exist in new type' do
      let(:params) { {} }

      before do
        allow(service).to receive(:excluded_in_new_type?).and_return(true)
        work_item.assignee_ids = [new_assignee.id]
      end

      it "resets the work item's assignees" do
        assignees_callback

        expect(work_item.assignee_ids).to be_empty
      end
    end
  end

  describe '#before_create' do
    subject(:assignees_callback) { service.before_create }

    it_behaves_like 'assignee callback'
  end

  describe '#before_update' do
    subject(:assignees_callback) { service.before_update }

    it_behaves_like 'assignee callback'
  end
end
