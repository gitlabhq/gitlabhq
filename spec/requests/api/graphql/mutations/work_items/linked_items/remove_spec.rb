# frozen_string_literal: true

require 'spec_helper'

RSpec.describe "Remove items linked to a work item", feature_category: :portfolio_management do
  include GraphqlHelpers

  let_it_be(:project) { create(:project, :private) }
  let_it_be(:guest) { create(:user, guest_of: project) }
  let_it_be(:work_item) { create(:work_item, project: project) }
  let_it_be(:related1) { create(:work_item, project: project) }
  let_it_be(:related2) { create(:work_item, project: project) }
  let_it_be(:link1) { create(:work_item_link, source: work_item, target: related1) }
  let_it_be(:link2) { create(:work_item_link, source: work_item, target: related2) }

  let(:mutation_response) { graphql_mutation_response(:work_item_remove_linked_items) }
  let(:mutation) { graphql_mutation(:workItemRemoveLinkedItems, input, fields) }
  let(:ids_to_unlink) { [related1.to_global_id.to_s, related2.to_global_id.to_s] }
  let(:input) { { 'id' => work_item.to_global_id.to_s, 'workItemsIds' => ids_to_unlink } }

  let(:fields) do
    <<~FIELDS
      workItem {
        id
        widgets {
          type
          ... on WorkItemWidgetLinkedItems {
            linkedItems {
              edges {
                node {
                  linkType
                  workItem {
                    id
                  }
                }
              }
            }
          }
        }
      }
      errors
      message
    FIELDS
  end

  context 'when the user is not allowed to read the work item' do
    let(:current_user) { create(:user) }

    it_behaves_like 'a mutation that returns a top-level access error'
  end

  context 'when user has permissions to read the work item' do
    let(:current_user) { guest }

    it 'unlinks the work items' do
      expect do
        post_graphql_mutation(mutation, current_user: current_user)
      end.to change { WorkItems::RelatedWorkItemLink.count }.by(-2)

      expect(response).to have_gitlab_http_status(:success)
      expect(mutation_response['workItem']).to include('id' => work_item.to_global_id.to_s)
      expect(mutation_response['message']).to eq("Successfully unlinked IDs: #{related1.id} and #{related2.id}.")
      expect(mutation_response['workItem']['widgets']).to include(
        {
          'linkedItems' => { 'edges' => [] }, 'type' => 'LINKED_ITEMS'
        }
      )
    end

    context 'when some items fail' do
      let_it_be(:other_project) { create(:project, :private) }
      let_it_be(:not_related) { create(:work_item, project: project) }
      let_it_be(:no_access) { create(:work_item, project: other_project) }
      let_it_be(:no_access_link) { create(:work_item_link, source: work_item, target: no_access) }

      let(:ids_to_unlink) { [related1.to_global_id.to_s, not_related.to_global_id.to_s, no_access.to_global_id.to_s] }
      let(:error_msg) do
        "Successfully unlinked IDs: #{related1.id}. " \
          "IDs with errors: #{no_access.id} could not be removed due to insufficient permissions, " \
          "#{not_related.id} could not be removed due to not being linked."
      end

      it 'remove valid item and include failing ids in response message' do
        expect do
          post_graphql_mutation(mutation, current_user: current_user)
        end.to change { WorkItems::RelatedWorkItemLink.count }.by(-1)

        expect(response).to have_gitlab_http_status(:success)
        expect(mutation_response['message']).to eq(error_msg)
      end
    end

    context 'when there are more than the max allowed items to unlink' do
      let(:max_work_items) { Mutations::WorkItems::LinkedItems::Base::MAX_WORK_ITEMS }
      let(:ids_to_unlink) { (0..max_work_items).map { |i| "gid://gitlab/WorkItem/#{i}" } }

      it 'returns an error message' do
        expect do
          post_graphql_mutation(mutation, current_user: current_user)
        end.not_to change { WorkItems::RelatedWorkItemLink.count }

        expect_graphql_errors_to_include("No more than #{max_work_items} work items can be modified at the same time.")
      end
    end

    context 'when workItemsIds is empty' do
      let(:ids_to_unlink) { [] }

      it_behaves_like 'a mutation that returns top-level errors', errors: ['workItemsIds cannot be empty']
    end
  end
end
