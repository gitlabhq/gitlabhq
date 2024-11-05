# frozen_string_literal: true

require 'spec_helper'

RSpec.describe WorkItems::DataSync::MoveService, feature_category: :team_planning do
  let_it_be(:group) { create(:group) }
  let_it_be(:project) { create(:project) }
  let_it_be(:target_project) { create(:project, group: group) }
  let_it_be_with_reload(:issue_work_item) { create(:work_item, :opened, project: project) }
  let_it_be(:task_work_item) { create(:work_item, :task, project: project) }
  let_it_be(:source_project_member) { create(:user, reporter_of: project) }
  let_it_be(:target_project_member) { create(:user, reporter_of: target_project) }
  let_it_be(:projects_member) { create(:user, reporter_of: [project, target_project]) }

  let(:original_work_item) { issue_work_item }
  let(:target_namespace) { target_project.project_namespace.reload }

  let(:service) do
    described_class.new(
      work_item: original_work_item,
      target_namespace: target_namespace,
      current_user: current_user
    )
  end

  context 'when user does not have permissions' do
    context 'when user cannot read original work item' do
      let(:current_user) { target_project_member }

      it 'does not raise error' do
        expect { service.execute }.not_to raise_error
      end

      it 'returns error response' do
        response = service.execute

        expect(response.success?).to be false
        expect(response.error?).to be true
        expect(response.message).to eq('Cannot move work item due to insufficient permissions!')
      end
    end

    context 'when user cannot create work items in target namespace' do
      let(:current_user) { source_project_member }

      it 'does not raise error' do
        expect { service.execute }.not_to raise_error
      end

      it 'returns error response' do
        response = service.execute

        expect(response.success?).to be false
        expect(response.error?).to be true
        expect(response.message).to eq('Cannot move work item due to insufficient permissions!')
      end
    end
  end

  context 'when user has permission to move work item' do
    let(:current_user) { projects_member }

    context 'when moving project level work item to a group' do
      let(:target_namespace) { group }

      it 'does not raise error' do
        expect { service.execute }.not_to raise_error
      end

      it 'returns error response' do
        response = service.execute

        expect(response.success?).to be false
        expect(response.error?).to be true
        expect(response.message).to eq('Cannot move work item between Projects and Groups.')
      end
    end

    context 'when moving to a pending delete project' do
      before do
        target_namespace.project.update!(pending_delete: true)
      end

      after do
        target_namespace.project.update!(pending_delete: false)
      end

      it 'does not raise error' do
        expect { service.execute }.not_to raise_error
      end

      it 'returns error response' do
        response = service.execute

        expect(response.success?).to be false
        expect(response.error?).to be true
        expect(response.message).to eq('Cannot move work item to target namespace as it is pending deletion.')
      end
    end

    context 'when moving unsupported work item type' do
      let(:original_work_item) { task_work_item }

      it 'does not raise error' do
        expect { service.execute }.not_to raise_error
      end

      it 'returns error response' do
        response = service.execute

        expect(response.success?).to be false
        expect(response.error?).to be true
        expect(response.message).to eq('Cannot move work items of \'Task\' type.')
      end
    end

    context 'when moving work item raises an error' do
      let(:error_message) { 'Something went wrong' }

      before do
        allow_next_instance_of(::WorkItems::DataSync::BaseCreateService) do |create_service|
          allow(create_service).to receive(:execute).and_return(ServiceResponse.error(message: error_message))
        end
      end

      it 'does not raise error' do
        expect { service.execute }.not_to raise_error
      end

      it 'returns error response' do
        response = service.execute

        expect(response.success?).to be false
        expect(response.error?).to be true
        expect(response.message).to eq('Something went wrong')
      end
    end

    context 'when moving work item with success', :freeze_time do
      let(:expected_original_work_item_state) { Issue.available_states[:closed] }
      let!(:original_work_item_attrs) do
        {
          iid: original_work_item.iid,
          project: target_namespace.try(:project),
          namespace: target_namespace,
          work_item_type: original_work_item.work_item_type,
          author: original_work_item.author,
          title: original_work_item.title,
          description: original_work_item.description,
          state_id: original_work_item.state_id,
          created_at: original_work_item.reload.created_at,
          updated_by: original_work_item.updated_by,
          updated_at: original_work_item.reload.updated_at,
          confidential: original_work_item.confidential,
          cached_markdown_version: original_work_item.cached_markdown_version,
          lock_version: original_work_item.lock_version,
          imported_from: "none",
          last_edited_at: original_work_item.last_edited_at,
          last_edited_by: original_work_item.last_edited_by,
          closed_at: original_work_item.closed_at,
          closed_by: original_work_item.closed_by,
          duplicated_to_id: original_work_item.duplicated_to_id,
          moved_to_id: original_work_item.moved_to_id,
          promoted_to_epic_id: original_work_item.promoted_to_epic_id,
          external_key: original_work_item.external_key,
          upvotes_count: original_work_item.upvotes_count,
          blocking_issues_count: original_work_item.blocking_issues_count,
          service_desk_reply_to: target_namespace.service_desk_alias_address
        }
      end

      it_behaves_like 'cloneable and moveable work item'

      context 'with specific widgets' do
        let!(:assignees) { [source_project_member, target_project_member, projects_member] }

        it_behaves_like 'cloneable and moveable widget data'
      end
    end
  end
end
