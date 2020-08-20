# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Reposition and move issue within board lists' do
  include GraphqlHelpers

  let_it_be(:group)   { create(:group, :private) }
  let_it_be(:project) { create(:project, group: group) }
  let_it_be(:board)   { create(:board, group: group) }
  let_it_be(:user)    { create(:user) }
  let_it_be(:development) { create(:label, project: project, name: 'Development') }
  let_it_be(:testing) { create(:label, project: project, name: 'Testing') }
  let_it_be(:list1)   { create(:list, board: board, label: development, position: 0) }
  let_it_be(:list2)   { create(:list, board: board, label: testing, position: 1) }
  let_it_be(:existing_issue1) { create(:labeled_issue, project: project, labels: [testing], relative_position: 10) }
  let_it_be(:existing_issue2) { create(:labeled_issue, project: project, labels: [testing], relative_position: 50) }
  let_it_be(:issue1) { create(:labeled_issue, project: project, labels: [development]) }

  let(:mutation_class) { Mutations::Boards::Issues::IssueMoveList }
  let(:mutation_name) { mutation_class.graphql_name }
  let(:mutation_result_identifier) { mutation_name.camelize(:lower) }
  let(:current_user) { user }
  let(:params) { { board_id: board.to_global_id.to_s, project_path: project.full_path, iid: issue1.iid.to_s } }
  let(:issue_move_params) do
    {
      from_list_id: list1.id,
      to_list_id: list2.id
    }
  end

  before_all do
    group.add_maintainer(user)
  end

  shared_examples 'returns an error' do
    it 'fails with error' do
      message = "The resource that you are attempting to access does not exist or you don't have "\
                "permission to perform this action"

      post_graphql_mutation(mutation(params), current_user: current_user)

      expect(graphql_errors).to include(a_hash_including('message' => message))
    end
  end

  context 'when user has access to resources' do
    context 'when repositioning an issue' do
      let(:issue_move_params) { { move_after_id: existing_issue1.id, move_before_id: existing_issue2.id } }

      it 'repositions an issue' do
        post_graphql_mutation(mutation(params), current_user: current_user)

        expect(response).to have_gitlab_http_status(:success)
        response_issue = json_response['data'][mutation_result_identifier]['issue']
        expect(response_issue['iid']).to eq(issue1.iid.to_s)
        expect(response_issue['relativePosition']).to be > existing_issue1.relative_position
        expect(response_issue['relativePosition']).to be < existing_issue2.relative_position
      end
    end

    context 'when moving an issue to a different list' do
      let(:issue_move_params) { { from_list_id: list1.id, to_list_id: list2.id } }

      it 'moves issue to a different list' do
        post_graphql_mutation(mutation(params), current_user: current_user)

        expect(response).to have_gitlab_http_status(:success)
        response_issue = json_response['data'][mutation_result_identifier]['issue']
        expect(response_issue['iid']).to eq(issue1.iid.to_s)
        expect(response_issue['labels']['edges'][0]['node']['title']).to eq(testing.title)
      end
    end
  end

  context 'when user has no access to resources' do
    context 'the user is not allowed to update the issue' do
      let(:current_user) { create(:user) }

      it_behaves_like 'returns an error'
    end

    context 'when the user can not read board' do
      let(:board) { create(:board, group: create(:group, :private)) }

      it_behaves_like 'returns an error'
    end
  end

  def mutation(additional_params = {})
    graphql_mutation(mutation_name, issue_move_params.merge(additional_params),
                     <<-QL.strip_heredoc
                       clientMutationId
                       issue {
                         iid,
                         relativePosition
                         labels {
                           edges {
                             node{
                               title
                             }
                           }
                         }
                       }
                       errors
    QL
    )
  end
end
