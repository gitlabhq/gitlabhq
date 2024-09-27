# frozen_string_literal: true

require 'spec_helper'

RSpec.describe WorkItems::DataSync::MoveService, feature_category: :team_planning do
  let_it_be(:group) { create(:group) }
  let_it_be(:project) { create(:project) }
  let_it_be(:target_project) { create(:project, group: group) }
  let_it_be(:issue_work_item) { create(:work_item, project: project) }
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

      it 'raises error' do
        expect { service.execute }.to raise_error(
          described_class::MoveError, 'Cannot move work item due to insufficient permissions!'
        )
      end
    end

    context 'when user cannot create work items in target namespace' do
      let(:current_user) { source_project_member }

      it 'raises error' do
        expect { service.execute }.to raise_error(
          described_class::MoveError, 'Cannot move work item due to insufficient permissions!'
        )
      end
    end
  end

  context 'when user has permission to move work item' do
    let(:current_user) { projects_member }

    context 'when moving project level work item to a group' do
      let(:target_namespace) { group }

      it 'raises error' do
        expect { service.execute }.to raise_error(
          described_class::MoveError, 'Cannot move work item between Projects and Groups.'
        )
      end
    end

    context 'when moving to a pending delete project' do
      before do
        target_namespace.project.update!(pending_delete: true)
      end

      after do
        target_namespace.project.update!(pending_delete: false)
      end

      it 'raises error' do
        expect { service.execute }.to raise_error(
          described_class::MoveError, 'Cannot move work item to target namespace as it is pending deletion.'
        )
      end
    end

    context 'when moving unsupported work item type' do
      let(:original_work_item) { task_work_item }

      it 'raises error' do
        expect { service.execute }.to raise_error(
          described_class::MoveError, 'Cannot move work items of \'Task\' type.'
        )
      end
    end

    context 'when moving work item raises an error' do
      let(:error_message) { 'Something went wrong' }

      before do
        allow_next_instance_of(::WorkItems::DataSync::BaseCreateService) do |create_service|
          allow(create_service).to receive(:execute).and_return(ServiceResponse.error(message: error_message))
        end
      end

      it 'raises error' do
        expect { service.execute }.to raise_error(described_class::MoveError, error_message)
      end
    end

    context 'when moving work item with success' do
      it 'increases the target namespace work items count by 1' do
        expect do
          service.execute
        end.to change { target_namespace.work_items.count }.by(1)
      end

      it 'returns a new work item with the same attributes' do
        new_work_item = service.execute

        expect(new_work_item).to be_persisted
        expect(new_work_item).to have_attributes(
          title: original_work_item.title,
          description: original_work_item.description,
          author: original_work_item.author,
          work_item_type: original_work_item.work_item_type,
          project: target_namespace.project,
          namespace: target_namespace
        )
      end

      it 'runs all widget callbacks' do
        create_service_params = {
          work_item: anything, target_work_item: anything, widget: anything, current_user: current_user, params: {}
        }
        cleanup_service_params = {
          work_item: anything, target_work_item: nil, widget: anything, current_user: current_user, params: {}
        }

        original_work_item.widgets.flat_map(&:sync_data_callback_class).each do |callback_class|
          allow_next_instance_of(callback_class, **create_service_params) do |callback_instance|
            expect(callback_instance).to receive(:before_create)
            expect(callback_instance).to receive(:after_save_commit)
          end

          allow_next_instance_of(callback_class, **cleanup_service_params) do |callback_instance|
            expect(callback_instance).to receive(:post_move_cleanup)
          end
        end

        service.execute
      end
    end
  end
end
