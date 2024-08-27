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

  context 'when the `bulk_update_work_items_mutation` feature flag is disabled' do
    before do
      stub_feature_flags(bulk_update_work_items_mutation: false)
    end

    it 'returns a resource not available error' do
      post_graphql_mutation(mutation, current_user: current_user)

      expect_graphql_errors_to_include(
        '`bulk_update_work_items_mutation` feature flag is disabled.'
      )
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
end
