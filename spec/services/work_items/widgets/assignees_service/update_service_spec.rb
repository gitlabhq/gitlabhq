# frozen_string_literal: true

require 'spec_helper'

RSpec.describe WorkItems::Widgets::AssigneesService::UpdateService, :freeze_time, feature_category: :portfolio_management do
  let_it_be(:reporter) { create(:user) }
  let_it_be(:project) { create(:project, :private) }
  let_it_be(:new_assignee) { create(:user) }

  let(:work_item) do
    create(:work_item, project: project, updated_at: 1.day.ago)
  end

  let(:widget) { work_item.widgets.find { |widget| widget.is_a?(WorkItems::Widgets::Assignees) } }
  let(:current_user) { reporter }
  let(:params) { { assignee_ids: [new_assignee.id] } }

  before_all do
    project.add_reporter(reporter)
    project.add_guest(new_assignee)
  end

  describe '#before_update_in_transaction' do
    let(:service) { described_class.new(widget: widget, current_user: current_user) }

    subject { service.before_update_in_transaction(params: params) }

    it 'updates the assignees and sets updated_at to the current time' do
      subject

      expect(work_item.assignee_ids).to contain_exactly(new_assignee.id)
      expect(work_item.updated_at).to be_like_time(Time.current)
    end

    context 'when passing an empty array' do
      let(:params) { { assignee_ids: [] } }

      before do
        work_item.assignee_ids = [reporter.id]
      end

      it 'removes existing assignees' do
        subject

        expect(work_item.assignee_ids).to be_empty
        expect(work_item.updated_at).to be_like_time(Time.current)
      end
    end

    context 'when user does not have access' do
      let(:current_user) { create(:user) }

      it 'does not update the assignees' do
        subject

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
          subject

          expect(work_item.assignee_ids).to contain_exactly(new_assignee.id, reporter.id)
          expect(work_item.updated_at).to be_like_time(Time.current)
        end
      end

      context 'when work item does not allow multiple assignees' do
        before do
          allow(work_item).to receive(:allows_multiple_assignees?).and_return(false)
        end

        it 'only sets the first assignee' do
          subject

          expect(work_item.assignee_ids).to contain_exactly(new_assignee.id)
          expect(work_item.updated_at).to be_like_time(Time.current)
        end
      end
    end

    context 'when assignee does not have access to the work item' do
      let(:params) { { assignee_ids: [create(:user).id] } }

      it 'does not set the assignee' do
        subject

        expect(work_item.assignee_ids).to be_empty
        expect(work_item.updated_at).to be_like_time(1.day.ago)
      end
    end

    context 'when assignee ids are the same as the existing ones' do
      before do
        work_item.assignee_ids = [new_assignee.id]
      end

      it 'does not touch updated_at' do
        subject

        expect(work_item.assignee_ids).to contain_exactly(new_assignee.id)
        expect(work_item.updated_at).to be_like_time(1.day.ago)
      end
    end

    context 'when widget does not exist in new type' do
      let(:params) { {} }

      before do
        allow(service).to receive(:new_type_excludes_widget?).and_return(true)
        work_item.assignee_ids = [new_assignee.id]
      end

      it "resets the work item's assignees" do
        subject

        expect(work_item.assignee_ids).to be_empty
      end
    end
  end
end
