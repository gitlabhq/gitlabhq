# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Bulk move work items', feature_category: :team_planning do
  include GraphqlHelpers

  let_it_be(:group) { create(:group) }
  let_it_be(:project) { create(:project, group: group) }
  let_it_be(:target_group) { create(:group) }
  let_it_be(:target_project) { create(:project, group: target_group) }
  let_it_be(:developer) { create(:user, :with_namespace, developer_of: group) }
  let_it_be_with_reload(:moveable_work_items) { create_list(:work_item, 2, :issue, project: project) }
  let_it_be(:task_work_item) { create(:work_item, :task, project: project) }
  let_it_be(:private_project) { create(:project, :private) }

  let(:current_user) { developer }
  let(:moveable_work_item_ids) { moveable_work_items.map { |i| i.to_gid.to_s } }
  let(:source_full_path) { project.full_path }
  let(:target_full_path) { target_project.full_path }
  let(:mutation) { graphql_mutation(:work_item_bulk_move, base_arguments) }
  let(:mutation_response) { graphql_mutation_response(:work_item_bulk_move) }
  let(:base_arguments) do
    {
      'ids' => moveable_work_item_ids,
      'sourceFullPath' => source_full_path,
      'targetFullPath' => target_full_path
    }
  end

  before_all do
    group.add_developer(developer)
    target_group.add_developer(developer)
    # Ensure support bot user is created so creation doesn't count towards query limit
    # and we don't try to obtain an exclusive lease within a transaction.
    # See https://gitlab.com/gitlab-org/gitlab/-/issues/509629
    Users::Internal.support_bot_id
  end

  context 'when user can move all work items' do
    it 'moves all work items' do
      expect do
        post_graphql_mutation(mutation, current_user: current_user)
      end.to change { target_project.work_items.count }.by(moveable_work_items.count)

      expect(mutation_response['movedWorkItemCount']).to eq(moveable_work_items.count)
      expect(mutation_response['errors']).to be_empty
    end
  end

  context 'when user cannot move all work items' do
    let_it_be(:forbidden_work_item) { create(:work_item, :issue, project: private_project) }
    let(:moveable_work_item_ids) { moveable_work_items.map { |i| i.to_gid.to_s } + [forbidden_work_item.to_gid.to_s] }

    it 'moves only work items that the user can move' do
      expect do
        post_graphql_mutation(mutation, current_user: current_user)
      end.to change { target_project.work_items.count }.by(moveable_work_items.count)

      expect(mutation_response).to include(
        'movedWorkItemCount' => moveable_work_items.count
      )
    end
  end

  context 'when user cannot create work items in target namespace' do
    let(:target_full_path) { private_project.full_path }

    it 'returns error message and do not move any work items' do
      post_graphql_mutation(mutation, current_user: current_user)

      expect(mutation_response['errors']).to include("You do not have permission to move items to this namespace.")
      expect(mutation_response['movedWorkItemCount']).to be_nil
    end
  end

  context 'when current user cannot read the source namespace' do
    let(:source_full_path) { private_project.full_path }

    it 'moves work items if user can read target but works with accessible work items' do
      # The user can't read the source namespace, so no work items will be found
      post_graphql_mutation(mutation, current_user: current_user)

      expect(mutation_response).to include(
        'movedWorkItemCount' => 0
      )
    end
  end

  context 'when source namespace is a group' do
    let_it_be(:another_project) { create(:project, group: group) }
    let_it_be(:work_item_in_group) { create(:work_item, :issue, project: another_project) }
    let(:source_full_path) { group.full_path }
    let(:moveable_work_item_ids) { [moveable_work_items.first.to_gid.to_s, work_item_in_group.to_gid.to_s] }

    it 'moves work items from all projects in the group' do
      expect do
        post_graphql_mutation(mutation, current_user: current_user)
      end.to change { target_project.work_items.count }.by(2)

      expect(mutation_response).to include(
        'movedWorkItemCount' => 2
      )
    end
  end

  context 'when target namespace is a group' do
    let(:target_full_path) { target_group.full_path }

    context 'when source namespace is a project' do
      it 'returns an error' do
        post_graphql_mutation(mutation, current_user: current_user)
        expect(mutation_response).to include('errors' => ['Cannot move work items from projects to groups.'])
      end
    end
  end

  context 'when target namespace is a user namespace' do
    let(:target_full_path) { current_user.namespace.full_path }

    it 'returns an error' do
      post_graphql_mutation(mutation, current_user: current_user)

      expect(mutation_response).to include(
        'errors' => ['User namespaces are not supported as target namespaces.']
      )
    end
  end

  context 'when work items include tasks that do not support move' do
    let(:moveable_work_item_ids) { [moveable_work_items.first.to_gid.to_s, task_work_item.to_gid.to_s] }

    it 'moves only work items that support move' do
      expect do
        post_graphql_mutation(mutation, current_user: current_user)
      end.to change { target_project.work_items.count }.by(1) # only the issue, not the task

      expect(mutation_response).to include(
        'movedWorkItemCount' => 1
      )
    end
  end

  context 'when work items are already in target namespace' do
    let(:target_full_path) { project.full_path }

    it 'does not move work items' do
      expect do
        post_graphql_mutation(mutation, current_user: current_user)
      end.not_to change { project.work_items.count }

      expect(mutation_response).to include(
        'movedWorkItemCount' => 0
      )
    end
  end

  context 'when move service returns an error' do
    before do
      allow_next_instance_of(WorkItems::BulkMoveService) do |move_service|
        allow(move_service).to receive(:execute).and_return(
          ServiceResponse.error(message: 'move error', reason: :error)
        )
      end
    end

    it 'returns an error message' do
      post_graphql_mutation(mutation, current_user: current_user)

      expect(graphql_data.dig('workItemBulkMove', 'errors')).to contain_exactly('move error')
    end
  end

  context 'when trying to move more than the max allowed' do
    before do
      stub_const('Mutations::WorkItems::BulkMove::MAX_WORK_ITEMS', moveable_work_items.count - 1)
    end

    it "restricts moving more than #{Mutations::WorkItems::BulkMove::MAX_WORK_ITEMS} work items at the same time" do
      post_graphql_mutation(mutation, current_user: current_user)

      expect_graphql_errors_to_include(
        format(
          _('No more than %{max_work_items} work items can be moved at the same time'),
          max_work_items: Mutations::WorkItems::BulkMove::MAX_WORK_ITEMS
        )
      )
    end
  end

  context 'when source namespace does not exist' do
    let(:source_full_path) { 'non/existent' }

    it 'returns an error' do
      post_graphql_mutation(mutation, current_user: current_user)

      expect(mutation_response).to include(
        'movedWorkItemCount' => 0
      )
    end
  end

  context 'when target namespace does not exist' do
    let(:target_full_path) { 'non/existent' }

    it 'returns an error' do
      post_graphql_mutation(mutation, current_user: current_user)

      expect(graphql_errors.first['message']).to eq('Cannot find target namespace.')
    end
  end

  context 'when work item IDs are invalid' do
    let(:moveable_work_item_ids) { ['gid://gitlab/WorkItem/999999'] }

    it 'handles invalid IDs gracefully' do
      post_graphql_mutation(mutation, current_user: current_user)

      expect(mutation_response).to include(
        'movedWorkItemCount' => 0
      )
    end
  end

  context 'when some moves fail' do
    let_it_be(:work_item_with_move_error) { create(:work_item, :issue, project: project) }
    let(:moveable_work_item_ids) do
      moveable_work_items.map { |i| i.to_gid.to_s } + [work_item_with_move_error.to_gid.to_s]
    end

    before do
      # Simulate a move error for one work item
      allow_next_instance_of(WorkItems::DataSync::MoveService) do |service|
        allow(service).to receive(:execute).and_call_original

        if service.instance_variable_get(:@work_item) == work_item_with_move_error
          allow(service).to receive(:execute).and_return(
            ServiceResponse.error(message: 'Move failed')
          )
        end
      end
    end

    it 'moves only the successful work items' do
      expect do
        post_graphql_mutation(mutation, current_user: current_user)
      end.to change { target_project.work_items.count }.by(moveable_work_items.count)

      expect(mutation_response).to include(
        'movedWorkItemCount' => moveable_work_items.count
      )
    end
  end

  context 'when work items have different types' do
    let_it_be(:incident) { create(:work_item, :incident, project: project) }
    let_it_be(:issue) { create(:work_item, :issue, project: project) }
    let(:moveable_work_item_ids) { [incident.to_gid.to_s, issue.to_gid.to_s] }

    it 'moves work items of different types that support move' do
      expect do
        post_graphql_mutation(mutation, current_user: current_user)
      end.to change { target_project.work_items.count }.by(2)

      expect(mutation_response).to include(
        'movedWorkItemCount' => 2
      )
    end
  end
end
