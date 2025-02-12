# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Delete a work item', feature_category: :team_planning do
  include GraphqlHelpers

  let_it_be(:group) { create(:group) }
  let_it_be(:owner) { create(:user, owner_of: group) }
  let_it_be(:project) { create(:project, group: group) }
  let_it_be(:planner) { create(:user, planner_of: project) }
  let_it_be(:author) { create(:user, developer_of: project) }
  let_it_be(:developer) { create(:user, developer_of: project) }
  let_it_be(:issue) { create(:work_item, :issue, project: project, author: author) }
  let_it_be(:incident) { create(:work_item, :incident, project: project) }

  let(:mutation) { graphql_mutation(:workItemDelete, { 'id' => work_item.to_global_id.to_s }) }
  let(:mutation_response) { graphql_mutation_response(:work_item_delete) }

  context 'when the user is not allowed to delete a work item' do
    context 'with issue type' do
      let(:work_item) { issue }
      let(:current_user) { developer }

      it_behaves_like 'a mutation that returns a top-level access error'
    end

    context 'with incident type' do
      let(:work_item) { incident }

      context 'when user is planner' do
        let(:current_user) { planner }

        it_behaves_like 'a mutation that returns a top-level access error'
      end

      context 'when user is author' do
        let(:current_user) { author }

        it_behaves_like 'a mutation that returns a top-level access error'
      end
    end
  end

  context 'when user has permissions to delete a work item' do
    shared_examples 'mutation that deletes work item' do
      it 'deletes the work item' do
        expect do
          post_graphql_mutation(mutation, current_user: current_user)
        end.to change(WorkItem, :count).by(-1)

        expect(response).to have_gitlab_http_status(:success)
        expect(mutation_response['project']).to include('id' => work_item.project.to_global_id.to_s)
      end

      context 'when an error is produced when trying to delete the work item' do
        let(:error_response) { ServiceResponse.error(message: 'Failed to delete') }

        before do
          allow_next_instance_of(WorkItems::DeleteService) do |instance|
            allow(instance).to receive(:execute).and_return(error_response)
          end
        end

        it 'returns an error message' do
          expect do
            post_graphql_mutation(mutation, current_user: current_user)
          end.to not_change(WorkItem, :count)

          expect(mutation_response['errors']).to contain_exactly('Failed to delete')
        end
      end
    end

    context 'with issue type' do
      context 'when user is author' do
        let(:work_item) { issue }
        let(:current_user) { author }

        it_behaves_like 'mutation that deletes work item'
      end

      context 'when user is planner' do
        let(:work_item) { issue }
        let(:current_user) { planner }

        it_behaves_like 'mutation that deletes work item'
      end

      context 'when user is owner' do
        let(:work_item) { issue }
        let(:current_user) { owner }

        it_behaves_like 'mutation that deletes work item'
      end
    end

    context 'with incident type' do
      context 'when user is owner' do
        let(:work_item) { incident }
        let(:current_user) { owner }

        it_behaves_like 'mutation that deletes work item'
      end
    end
  end
end
