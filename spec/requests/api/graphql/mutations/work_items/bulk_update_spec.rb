# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Bulk update work items', feature_category: :team_planning do
  include GraphqlHelpers

  let_it_be(:group) { create(:group) }
  let_it_be(:project) { create(:project, group: group) }
  let_it_be(:developer) { create(:user, developer_of: group) }
  let_it_be(:label1) { create(:group_label, group: group) }
  let_it_be(:label2) { create(:group_label, group: group) }
  let_it_be_with_reload(:updatable_work_items) { create_list(:work_item, 2, project: project, label_ids: [label1.id]) }
  let_it_be(:private_project) { create(:project, :private) }
  let(:parent) { project }
  let(:mutation) { graphql_mutation(:work_item_bulk_update, base_arguments.merge(additional_arguments)) }
  let(:mutation_response) { graphql_mutation_response(:work_item_bulk_update) }
  let(:current_user) { developer }
  let(:updatable_work_item_ids) { updatable_work_items.map { |i| i.to_gid.to_s } }
  let(:base_arguments) { { parent_id: parent.to_gid.to_s, ids: updatable_work_item_ids } }

  let(:additional_arguments) do
    {
      'labelsWidget' => {
        'addLabelIds' => [label2.to_gid.to_s],
        'removeLabelIds' => [label1.to_gid.to_s]
      }
    }
  end

  context 'when Gitlab is FOSS only' do
    unless Gitlab.ee?
      context 'when parent is a group' do
        let(:parent) { group }

        it 'does not allow bulk updating work items at the group level' do
          post_graphql_mutation(mutation, current_user: current_user)

          expect_graphql_errors_to_include(/does not represent an instance of WorkItems::Parent/)
        end
      end
    end
  end

  context 'when user can not update all work_items' do
    let_it_be(:forbidden_work_item) { create(:work_item, project: private_project) }
    let(:updatable_work_item_ids) { updatable_work_items.map { |i| i.to_gid.to_s } + [forbidden_work_item.to_gid.to_s] }

    it 'updates only work items that the user can update' do
      expect do
        post_graphql_mutation(mutation, current_user: current_user)
        updatable_work_items.each(&:reload)
        forbidden_work_item.reload
      end.to change { updatable_work_items.flat_map(&:label_ids) }.from([label1.id] * 2).to([label2.id] * 2).and(
        not_change { forbidden_work_item.label_ids }.from([])
      )

      expect(mutation_response).to include(
        'updatedWorkItemCount' => updatable_work_items.count
      )
    end
  end

  context 'when user can update all work items' do
    it 'updates all work items' do
      expect do
        post_graphql_mutation(mutation, current_user: current_user)
        updatable_work_items.each(&:reload)
      end.to change { updatable_work_items.flat_map(&:label_ids) }.from([label1.id] * 2).to([label2.id] * 2)

      expect(mutation_response).to include(
        'updatedWorkItemCount' => updatable_work_items.count
      )
    end

    context 'when current user cannot read the specified project' do
      let(:parent) { private_project }

      it 'returns a resource not found error' do
        post_graphql_mutation(mutation, current_user: current_user)

        expect_graphql_errors_to_include(
          "The resource that you are attempting to access does not exist or you don't have " \
            'permission to perform this action'
        )
      end
    end
  end

  context 'when update service returns an error' do
    before do
      allow_next_instance_of(WorkItems::BulkUpdateService) do |update_service|
        allow(update_service).to receive(:execute).and_return(
          ServiceResponse.error(message: 'update error', reason: :error)
        )
      end
    end

    it 'returns an error message' do
      post_graphql_mutation(mutation, current_user: current_user)

      expect(graphql_data.dig('workItemBulkUpdate', 'errors')).to contain_exactly('update error')
    end
  end

  context 'when trying to update more than the max allowed' do
    before do
      stub_const('Mutations::WorkItems::BulkUpdate::MAX_WORK_ITEMS', updatable_work_items.count - 1)
    end

    it "restricts updating more than #{Mutations::WorkItems::BulkUpdate::MAX_WORK_ITEMS} work items at the same time" do
      post_graphql_mutation(mutation, current_user: current_user)

      expect_graphql_errors_to_include(
        format(
          _('No more than %{max_work_items} work items can be updated at the same time'),
          max_work_items: Mutations::WorkItems::BulkUpdate::MAX_WORK_ITEMS
        )
      )
    end
  end

  context 'when updating confidential attribute' do
    let(:additional_arguments) do
      {
        'confidential' => true
      }
    end

    it 'updates the confidential attribute for all work items' do
      expect do
        post_graphql_mutation(mutation, current_user: current_user)
        updatable_work_items.each(&:reload)
      end.to change { updatable_work_items.map(&:confidential) }.from([false, false]).to([true, true])

      expect(mutation_response).to include(
        'updatedWorkItemCount' => updatable_work_items.count
      )
    end
  end

  context 'when updating multiple attributes simultaneously' do
    let_it_be(:assignee) { create(:user, developer_of: group) }
    let_it_be(:milestone) { create(:milestone, project: project) }

    let(:additional_arguments) do
      {
        'confidential' => true,
        'assigneesWidget' => {
          'assigneeIds' => [assignee.to_gid.to_s]
        },
        'milestoneWidget' => {
          'milestoneId' => milestone.to_gid.to_s
        },
        'labelsWidget' => {
          'addLabelIds' => [label2.to_gid.to_s]
        }
      }
    end

    it 'updates all specified attributes' do
      expect do
        post_graphql_mutation(mutation, current_user: current_user)
        updatable_work_items.each(&:reload)
      end.to change { updatable_work_items.map(&:confidential) }.from([false, false]).to([true, true])
         .and change { updatable_work_items.flat_map(&:assignee_ids) }.from([]).to([assignee.id] * 2)
         .and change { updatable_work_items.map(&:milestone_id) }.from([nil, nil]).to([milestone.id] * 2)
         .and change { updatable_work_items.flat_map(&:label_ids) }.from([label1.id] * 2).to([label1.id, label2.id] * 2)

      expect(mutation_response).to include(
        'updatedWorkItemCount' => updatable_work_items.count
      )
    end

    context 'when updating work items that do not support requested widgets' do
      let_it_be(:key_result) { create(:work_item, :key_result, project: project) }
      let_it_be(:issue) { create(:work_item, :issue, project: project) }

      let(:updatable_work_item_ids) { [key_result.to_gid.to_s, issue.to_gid.to_s] }

      context 'when updating milestone widget' do
        let(:additional_arguments) do
          {
            'milestoneWidget' => {
              'milestoneId' => milestone.to_gid.to_s
            }
          }
        end

        it 'updates only work items that support the milestone widget' do
          # Key Results don't support milestones, but Issues do
          expect do
            post_graphql_mutation(mutation, current_user: current_user)
          end.to change { issue.reload.milestone }.from(nil).to(milestone)
            .and not_change { key_result.reload.attributes['milestone_id'] }

          expect(mutation_response).to include(
            'updatedWorkItemCount' => 1
          )
        end
      end
    end
  end

  context 'when work items have different types' do
    let_it_be(:task) { create(:work_item, :task, project: project) }
    let_it_be(:issue) { create(:work_item, :issue, project: project) }
    let(:updatable_work_item_ids) { [task.to_gid.to_s, issue.to_gid.to_s] }

    let(:additional_arguments) do
      {
        'labelsWidget' => {
          'addLabelIds' => [label2.to_gid.to_s]
        }
      }
    end

    it 'updates work items of different types' do
      expect do
        post_graphql_mutation(mutation, current_user: current_user)
        task.reload
        issue.reload
      end.to change { task.label_ids + issue.label_ids }.from([]).to([label2.id, label2.id])

      expect(mutation_response).to include(
        'updatedWorkItemCount' => 2
      )
    end
  end

  context 'when some updates fail' do
    let_it_be(:work_item_with_validation) { create(:work_item, project: project) }
    let(:updatable_work_item_ids) do
      updatable_work_items.map do |i|
        i.to_gid.to_s
      end + [work_item_with_validation.to_gid.to_s]
    end

    let(:additional_arguments) do
      {
        'confidential' => true
      }
    end

    before do
      # Simulate a validation error for one work item
      allow_next_instance_of(WorkItems::UpdateService) do |service|
        allow(service).to receive(:execute).and_call_original
        allow(service).to receive(:execute).with(work_item_with_validation).and_return(
          { status: :error, message: 'Validation failed' }
        )
      end
    end

    it 'updates only the successful work items' do
      expect do
        post_graphql_mutation(mutation, current_user: current_user)
        updatable_work_items.each(&:reload)
        work_item_with_validation.reload
      end.to change { updatable_work_items.map(&:confidential) }.from([false, false]).to([true, true])
         .and not_change { work_item_with_validation.confidential }.from(false)

      expect(mutation_response).to include(
        'updatedWorkItemCount' => updatable_work_items.count
      )
    end
  end

  context 'when no work items are provided' do
    let(:updatable_work_item_ids) { [] }

    it 'returns 0 updated work items' do
      post_graphql_mutation(mutation, current_user: current_user)

      expect(mutation_response).to include(
        'updatedWorkItemCount' => 0
      )
    end
  end
end
