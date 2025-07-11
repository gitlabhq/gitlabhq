# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'work item add children items', feature_category: :team_planning do
  include GraphqlHelpers

  let_it_be(:group) { create(:group) }
  let_it_be(:project) { create(:project, group: group) }
  let_it_be(:author) { create(:user, reporter_of: group) }
  let_it_be(:guest) { create(:user, guest_of: group) }
  let_it_be(:planner) { create(:user, planner_of: group) }
  let_it_be(:work_item, refind: true) { create(:work_item, project: project, author: author) }

  let_it_be(:valid_child1) { create(:work_item, :task, project: project, created_at: 5.minutes.ago) }
  let_it_be(:valid_child2) { create(:work_item, :task, project: project, created_at: 5.minutes.from_now) }
  let(:children_ids) { [valid_child1.to_global_id.to_s, valid_child2.to_global_id.to_s] }
  let(:input) { { 'childrenIds' => children_ids } }

  let(:fields) do
    <<~FIELDS
        addedChildren {
        id
        }
        errors
    FIELDS
  end

  let(:mutation_work_item) { work_item }
  let(:mutation) do
    graphql_mutation(:workItemHierarchyAddChildrenItems, input.merge('id' => mutation_work_item.to_gid.to_s), fields)
  end

  let(:mutation_response) { graphql_mutation_response(:work_item_hierarchy_add_children_items) }
  let(:added_children_response) { mutation_response['addedChildren'] }

  before_all do
    # Ensure support bot user is created so creation doesn't count towards query limit
    # and we don't try to obtain an exclusive lease within a transaction.
    # See https://gitlab.com/gitlab-org/gitlab/-/issues/509629
    Users::Internal.support_bot_id
  end

  shared_examples 'request with error' do |message|
    it 'ignores update and returns an error' do
      post_graphql_mutation(mutation, current_user: current_user)

      expect(response).to have_gitlab_http_status(:success)
      expect(added_children_response).to be_empty
      expect(mutation_response['errors'].first).to include(message)
    end
  end

  context 'when user has permissions to update a work item' do
    let(:current_user) { planner }

    context 'when updating children' do
      let_it_be(:invalid_child) { create(:work_item, project: project) }

      let(:error) do
        "#{invalid_child.to_reference} cannot be added: it's not allowed to add this type of parent item"
      end

      context 'when child work item type is invalid' do
        let(:children_ids) { [invalid_child.to_global_id.to_s] }

        it 'returns response with errors' do
          post_graphql_mutation(mutation, current_user: current_user)

          expect(added_children_response).to be_empty
          expect(mutation_response['errors']).to match_array([error])
        end
      end

      context 'when there is a mix of existing and non existing work items' do
        let(:children_ids) { [valid_child1.to_global_id.to_s, "gid://gitlab/WorkItem/#{non_existing_record_id}"] }

        it 'returns a top level error and does not add valid work item' do
          expect do
            post_graphql_mutation(mutation, current_user: current_user)
            work_item.reload
          end.not_to change { work_item.work_item_children.count }

          expect(graphql_errors.first['message']).to include('No object found for `childrenIds')
        end
      end

      context 'when child work item type is valid' do
        it 'updates the work item children' do
          expect do
            post_graphql_mutation(mutation, current_user: current_user)
            work_item.reload
          end.to change { work_item.work_item_children.count }.by(2)

          expect(response).to have_gitlab_http_status(:success)
          expect(added_children_response).to match_array([
            { 'id' => valid_child2.to_global_id.to_s },
            { 'id' => valid_child1.to_global_id.to_s }
          ])
        end
      end

      context 'when updating hierarchy for incident' do
        let_it_be(:incident) { create(:work_item, :incident, project: project) }
        let_it_be(:child_item) { create(:work_item, :task, project: project) }
        let(:mutation_work_item) { incident }

        let(:input) do
          { 'childrenIds' => [child_item.to_global_id.to_s] }
        end

        context 'when user is a guest' do
          let(:current_user) { guest }

          it 'returns an error and does not update' do
            expect do
              post_graphql_mutation(mutation, current_user: current_user)
              incident.reload
            end.not_to change { incident.work_item_children.count }

            expect(added_children_response).to be_empty
            expect(mutation_response['errors']).to include(
              "No matching work item found. Make sure that you are adding a valid work item ID."
            )
          end
        end

        context 'when user is an admin' do
          let_it_be(:admin) { create(:admin) }
          let(:current_user) { admin }

          it 'successfully updates the incident hierarchy' do
            expect do
              post_graphql_mutation(mutation, current_user: current_user)
              incident.reload
            end.to change { incident.work_item_children.count }.by(1)

            expect(response).to have_gitlab_http_status(:success)
            expect(added_children_response).to match_array([{ 'id' => child_item.to_global_id.to_s }])
          end
        end

        context 'when guest updates hierarchy for non-incident work item' do
          let(:current_user) { guest }
          let(:mutation_work_item) { work_item } # regular work item, not incident

          it 'successfully updates the work item hierarchy' do
            expect do
              post_graphql_mutation(mutation, current_user: current_user)
              work_item.reload
            end.to change { work_item.work_item_children.count }.by(1)

            expect(response).to have_gitlab_http_status(:success)
            expect(added_children_response).to match_array([{ 'id' => child_item.to_global_id.to_s }])
          end
        end
      end
    end
  end
end
