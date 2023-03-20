# frozen_string_literal: true

require 'spec_helper'

RSpec.describe WorkItems::DeleteTaskService, feature_category: :team_planning do
  let_it_be(:project) { create(:project) }
  let_it_be(:developer) { create(:user).tap { |u| project.add_developer(u) } }
  let_it_be_with_refind(:task) { create(:work_item, project: project, author: developer) }
  let_it_be_with_refind(:list_work_item) do
    create(:work_item, project: project, description: "- [ ] #{task.to_reference}+")
  end

  let(:current_user) { developer }
  let(:line_number_start) { 1 }
  let(:params) do
    {
      line_number_start: line_number_start,
      line_number_end: 1,
      task: task
    }
  end

  before_all do
    create(:issue_link, source_id: list_work_item.id, target_id: task.id)
  end

  shared_examples 'failing WorkItems::DeleteTaskService' do |error_message|
    it { is_expected.to be_error }

    it 'does not remove work item or issue links' do
      expect do
        service_result
        list_work_item.reload
      end.to not_change(WorkItem, :count).and(
        not_change(IssueLink, :count)
      ).and(
        not_change(list_work_item, :description)
      )
    end

    it 'returns an error message' do
      expect(service_result.errors).to contain_exactly(error_message)
    end
  end

  describe '#execute' do
    subject(:service_result) do
      described_class.new(
        work_item: list_work_item,
        current_user: current_user,
        lock_version: list_work_item.lock_version,
        task_params: params
      ).execute
    end

    context 'when work item params are valid' do
      it { is_expected.to be_success }

      it 'deletes the work item and the related issue link' do
        expect do
          service_result
        end.to change(WorkItem, :count).by(-1).and(
          change(IssueLink, :count).by(-1)
        )
      end

      it 'removes the task list item with the work item reference' do
        expect do
          service_result
        end.to change(list_work_item, :description).from(list_work_item.description).to("- [ ] #{task.title}")
      end
    end

    context 'when first operation fails' do
      let(:line_number_start) { -1 }

      it_behaves_like 'failing WorkItems::DeleteTaskService', 'line_number_start must be greater than 0'
    end

    context 'when last operation fails' do
      let_it_be(:non_member_user) { create(:user) }

      let(:current_user) { non_member_user }

      it_behaves_like 'failing WorkItems::DeleteTaskService', 'User not authorized to delete work item'
    end
  end
end
