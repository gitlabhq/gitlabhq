# frozen_string_literal: true

require 'spec_helper'

RSpec.describe WorkItems::DataSync::MoveService, feature_category: :team_planning do
  let_it_be(:group) { create(:group) }
  let_it_be(:project) { create(:project, group: group) }
  let_it_be(:target_project) { create(:project, group: group) }
  let_it_be_with_reload(:original_work_item) { create(:work_item, :opened, project: project) }
  let_it_be(:source_project_member) { create(:user, reporter_of: project) }
  let_it_be(:target_project_member) { create(:user, reporter_of: target_project) }
  let_it_be(:projects_member) { create(:user, reporter_of: [project, target_project]) }

  let_it_be_with_refind(:target_namespace) { target_project.project_namespace }

  let(:service) do
    described_class.new(
      work_item: original_work_item,
      target_namespace: target_namespace,
      current_user: current_user
    )
  end

  context 'when user does not have permissions' do
    context 'when user cannot read original work item' do
      let_it_be(:current_user) { target_project_member }

      it_behaves_like 'fails to transfer work item', 'Cannot move work item due to insufficient permissions'
    end

    context 'when user cannot create work items in target namespace' do
      let_it_be(:current_user) { source_project_member }

      it_behaves_like 'fails to transfer work item', 'Cannot move work item due to insufficient permissions'
    end

    context 'when work item is already moved once' do
      let_it_be(:current_user) { projects_member }

      before do
        original_work_item.update!(moved_to: create(:issue))
      end

      it_behaves_like 'fails to transfer work item', 'Cannot move work item due to insufficient permissions'
    end
  end

  context 'when user has permission to move work item' do
    let_it_be(:current_user) { projects_member }

    context 'when moving a project level work item to same project' do
      let(:target_namespace) { project }

      it_behaves_like 'fails to transfer work item', 'Cannot move work item to same project or group it originates from'
    end

    context 'when moving a project level work item to same project, using project namespace' do
      let(:target_namespace) { project.project_namespace }

      it_behaves_like 'fails to transfer work item', 'Cannot move work item to same project or group it originates from'
    end

    context 'when moving project level work item to a group' do
      let(:target_namespace) { group }

      it_behaves_like 'fails to transfer work item', 'Cannot move work item between Projects and Groups'
    end

    context 'when moving to a pending delete project' do
      before do
        target_namespace.project.update!(pending_delete: true)
      end

      after do
        target_namespace.project.update!(pending_delete: false)
      end

      it_behaves_like 'fails to transfer work item',
        'Cannot move work item to target namespace as it is pending deletion'
    end

    context 'when moving unsupported work item type' do
      let_it_be_with_reload(:original_work_item) { create(:work_item, :task, project: project) }

      it_behaves_like 'fails to transfer work item', 'Cannot move work items of \'Task\' type'
    end

    context 'when moving work item raises an error' do
      let(:error_message) { 'Something went wrong' }

      before do
        allow_next_instance_of(::WorkItems::DataSync::BaseCreateService) do |create_service|
          allow(create_service).to receive(:execute).and_return(ServiceResponse.error(message: error_message))
        end
      end

      it_behaves_like 'fails to transfer work item', 'Something went wrong'
    end

    context 'when moving work item with success', :freeze_time do
      let(:expected_original_work_item_state) { Issue.available_states[:closed] }
      let(:service_desk_alias_address) do
        target_namespace.respond_to?(:project) &&
          ::ServiceDesk::Emails.new(target_namespace.project).alias_address
      end

      let!(:original_work_item_attrs) do
        {
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
          service_desk_reply_to: service_desk_alias_address
        }
      end

      it_behaves_like 'cloneable and moveable work item'

      context 'when cleanup original data is enabled' do
        before do
          stub_feature_flags(cleanup_data_source_work_item_data: true)
        end

        it_behaves_like 'cloneable and moveable widget data'
      end

      context 'when cleanup original data is disabled' do
        before do
          stub_feature_flags(cleanup_data_source_work_item_data: false)
        end

        it_behaves_like 'cloneable and moveable widget data'
      end
    end
  end
end
