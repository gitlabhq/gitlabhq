# frozen_string_literal: true

require 'spec_helper'

RSpec.describe WorkItems::BulkMoveService, feature_category: :team_planning do
  let_it_be(:group) { create(:group) }
  let_it_be(:project) { create(:project, group: group) }
  let_it_be(:target_group) { create(:group) }
  let_it_be(:target_project) { create(:project, group: target_group) }
  let_it_be(:developer) { create(:user, developer_of: [group, target_group]) }
  let_it_be(:work_item1) { create(:work_item, :issue, project: project) }
  let_it_be(:work_item2) { create(:work_item, :issue, project: project) }
  let_it_be(:work_item3) { create(:work_item, :issue, project: project) }
  let_it_be(:task_work_item) { create(:work_item, :task, project: project) }

  let(:current_user) { developer }
  let(:work_item_ids) { [work_item1.id, work_item2.id] }
  let(:source_namespace) { project.project_namespace }
  let(:target_namespace) { target_project.project_namespace }

  subject(:service_result) do
    described_class.new(
      current_user: current_user,
      work_item_ids: work_item_ids,
      source_namespace: source_namespace,
      target_namespace: target_namespace
    ).execute
  end

  describe '#execute' do
    before do
      # Mock the MoveService to return success by default
      allow_next_instance_of(WorkItems::DataSync::MoveService) do |instance|
        allow(instance).to receive(:execute)
              .and_return(ServiceResponse.success(payload: { work_item: instance_double(WorkItem) }))
      end
    end

    context 'when moving work items between projects' do
      it 'successfully moves work items' do
        expect(service_result).to be_success
        expect(service_result[:moved_work_item_count]).to eq(2)
      end

      context 'when user cannot create work items in target namespace' do
        let_it_be(:target_namespace) { create(:project, :private).project_namespace }

        it 'returns error response' do
          expect(service_result).to be_error
          expect(service_result.message).to eq("Unknown target namespace")
        end
      end

      context 'when user cannot admin work items' do
        let_it_be(:current_user) { create(:user, developer_of: target_group) }

        it 'does not move any work items' do
          expect(service_result).to be_success
          expect(service_result[:moved_work_item_count]).to eq(0)
        end
      end

      context 'when work item is already in target namespace' do
        let(:work_item_ids) { [work_item1.id] }
        let(:target_namespace) { project.project_namespace }

        it 'does not move the work item' do
          expect(service_result).to be_success
          expect(service_result[:moved_work_item_count]).to eq(0)
        end
      end

      context 'when work item does not support move' do
        let(:work_item_ids) { [task_work_item.id] }

        it 'does not move the work item' do
          expect(service_result).to be_success
          expect(service_result[:moved_work_item_count]).to eq(0)
        end
      end

      context 'when MoveService fails' do
        before do
          allow_next_instance_of(WorkItems::DataSync::MoveService) do |instance|
            allow(instance).to receive(:execute)
                      .and_return(ServiceResponse.error(message: 'Move failed'))
          end
        end

        it 'skips failed work items' do
          expect(service_result).to be_success
          expect(service_result[:moved_work_item_count]).to eq(0)
        end
      end
    end

    context 'when target namespace is a group' do
      let(:target_namespace) { target_group }

      it 'returns error because groups do not support work item creation via move' do
        expect(service_result).to be_error
        expect(service_result.message).to eq("Unknown target namespace")
      end
    end

    context 'when source namespace is a group' do
      let(:source_namespace) { group }
      let(:target_namespace) { target_project.project_namespace }

      it 'can find work items from group projects but may fail to move to group targets' do
        expect(service_result).to be_success
        expect(service_result[:moved_work_item_count]).to eq(2)
      end
    end

    context 'with work items from different projects in same group' do
      let_it_be(:another_project) { create(:project, group: group) }
      let_it_be(:work_item_from_another_project) { create(:work_item, :issue, project: another_project) }

      let(:work_item_ids) { [work_item1.id, work_item_from_another_project.id] }
      let(:source_namespace) { group }
      let(:target_namespace) { target_project.project_namespace }

      it 'can move work items from multiple projects within a group to a project' do
        expect(service_result).to be_success
        expect(service_result[:moved_work_item_count]).to eq(2)
      end
    end

    context 'with mixed work item types' do
      let(:work_item_ids) { [work_item1.id, task_work_item.id] }

      it 'only moves work items that support move' do
        expect(service_result).to be_success
        expect(service_result[:moved_work_item_count]).to eq(1) # only the issue, not the task
      end
    end

    context 'when work item IDs are not found in source namespace' do
      let(:work_item_ids) { [work_item1.id, 999999] }

      it 'only processes existing work items' do
        expect(service_result).to be_success
        expect(service_result[:moved_work_item_count]).to eq(1)
      end
    end

    context 'when MoveService raises an exception' do
      before do
        allow_next_instance_of(WorkItems::DataSync::MoveService) do |instance|
          allow(instance).to receive(:execute).and_raise(StandardError, 'Something went wrong')
        end
      end

      it 'handles exceptions gracefully' do
        expect(service_result).to be_success
        expect(service_result[:moved_work_item_count]).to eq(0)
      end
    end
  end
end
