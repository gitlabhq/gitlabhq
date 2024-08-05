# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Reorder a work item in the hierarchy tree', feature_category: :team_planning do
  include GraphqlHelpers

  let_it_be(:group) { create(:group, :private) }
  let_it_be(:project) { create(:project, group: group) }
  let_it_be(:guest) { create(:user, guest_of: group) }

  let_it_be(:parent_work_item) { create(:work_item, :issue, project: project) }
  let_it_be(:child1) { create(:work_item, :task, project: project) }
  let_it_be(:child2) { create(:work_item, :task, project: project) }
  let_it_be(:child3) { create(:work_item, :task, project: project) }

  let_it_be(:child1_link) do
    create(:parent_link, work_item_parent: parent_work_item, work_item: child1, relative_position: 20)
  end

  let_it_be(:child2_link) do
    create(:parent_link, work_item_parent: parent_work_item, work_item: child2, relative_position: 30)
  end

  let_it_be(:child3_link) do
    create(:parent_link, work_item_parent: parent_work_item, work_item: child3, relative_position: 40)
  end

  let(:mutation) do
    graphql_mutation(:workItemsHierarchyReorder, input.merge('id' => work_item.to_global_id.to_s), fields)
  end

  let(:mutation_response) { graphql_mutation_response(:work_items_hierarchy_reorder) }

  describe 'reordering' do
    let(:work_item) { child3 }

    let(:fields) do
      <<~FIELDS
        workItem {
          id
        }
        adjacentWorkItem {
          id
        }
        parentWorkItem {
          id
        }
        errors
      FIELDS
    end

    context 'when user lacks permissions' do
      let(:current_user) { create(:user) }

      let(:input) do
        { 'adjacentWorkItemId' => child1.to_gid.to_s, 'relativePosition' => 'AFTER' }
      end

      it 'returns an error' do
        post_graphql_mutation(mutation, current_user: current_user)

        expect_graphql_errors_to_include(
          "The resource that you are attempting to access does not " \
            "exist or you don't have permission to perform this action"
        )
      end
    end

    context 'when user has permissions' do |position|
      let(:current_user) { guest }

      let(:input) do
        { 'adjacentWorkItemId' => child1.to_gid.to_s, 'relativePosition' => position }
      end

      shared_examples 'reorders item position' do
        it 'moves the item to the specified position in relation to the adjacent item' do
          post_graphql_mutation(mutation, current_user: current_user)

          expect(response).to have_gitlab_http_status(:success)
          expect(parent_work_item.reload.work_item_children_by_relative_position).to match_array(reorders_items)

          expect(mutation_response['workItem']['id']).to eq(work_item.to_gid.to_s)
          expect(mutation_response['parentWorkItem']['id']).to eq(parent_work_item.to_gid.to_s)
          expect(mutation_response['adjacentWorkItem']['id']).to eq(child1.to_gid.to_s)
        end
      end

      it_behaves_like 'reorders item position', 'AFTER' do
        let(:reorders_items) { [child1, work_item, child2] }
      end

      it_behaves_like 'reorders item position', 'BEFORE' do
        let(:reorders_items) { [work_item, child1, child2] }
      end
    end
  end
end
