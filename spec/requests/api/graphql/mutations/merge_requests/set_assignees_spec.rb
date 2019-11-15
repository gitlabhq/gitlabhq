# frozen_string_literal: true

require 'spec_helper'

describe 'Setting assignees of a merge request' do
  include GraphqlHelpers

  let(:current_user) { create(:user) }
  let(:merge_request) { create(:merge_request) }
  let(:project) { merge_request.project }
  let(:assignee) { create(:user) }
  let(:assignee2) { create(:user) }
  let(:input) { { assignee_usernames: [assignee.username] } }
  let(:expected_result) do
    [{ 'username' => assignee.username }]
  end

  let(:mutation) do
    variables = {
      project_path: project.full_path,
      iid: merge_request.iid.to_s
    }
    graphql_mutation(:merge_request_set_assignees, variables.merge(input),
                     <<-QL.strip_heredoc
                       clientMutationId
                       errors
                       mergeRequest {
                         id
                         assignees {
                           nodes {
                             username
                           }
                         }
                       }
    QL
    )
  end

  def mutation_response
    graphql_mutation_response(:merge_request_set_assignees)
  end

  def mutation_assignee_nodes
    mutation_response['mergeRequest']['assignees']['nodes']
  end

  before do
    project.add_developer(current_user)
    project.add_developer(assignee)
    project.add_developer(assignee2)
  end

  it 'returns an error if the user is not allowed to update the merge request' do
    post_graphql_mutation(mutation, current_user: create(:user))

    expect(graphql_errors).not_to be_empty
  end

  it 'does not allow members without the right permission to add assignees' do
    user = create(:user)
    project.add_guest(user)

    post_graphql_mutation(mutation, current_user: user)

    expect(graphql_errors).not_to be_empty
  end

  context 'with assignees already assigned' do
    before do
      merge_request.assignees = [assignee2]
      merge_request.save!
    end

    it 'replaces the assignee' do
      post_graphql_mutation(mutation, current_user: current_user)

      expect(response).to have_gitlab_http_status(:success)
      expect(mutation_assignee_nodes).to match_array(expected_result)
    end
  end

  context 'when passing an empty list of assignees' do
    let(:input) { { assignee_usernames: [] } }

    before do
      merge_request.assignees = [assignee2]
      merge_request.save!
    end

    it 'removes assignee' do
      post_graphql_mutation(mutation, current_user: current_user)

      expect(response).to have_gitlab_http_status(:success)
      expect(mutation_assignee_nodes).to eq([])
    end
  end

  context 'when passing append as true' do
    let(:input) { { assignee_usernames: [assignee2.username], operation_mode: Types::MutationOperationModeEnum.enum[:append] } }

    before do
      # In CE, APPEND is a NOOP as you can't have multiple assignees
      # We test multiple assignment in EE specs
      stub_licensed_features(multiple_merge_request_assignees: false)

      merge_request.assignees = [assignee]
      merge_request.save!
    end

    it 'does not replace the assignee in CE' do
      post_graphql_mutation(mutation, current_user: current_user)

      expect(response).to have_gitlab_http_status(:success)
      expect(mutation_assignee_nodes).to match_array(expected_result)
    end
  end

  context 'when passing remove as true' do
    let(:input) { { assignee_usernames: [assignee.username], operation_mode: Types::MutationOperationModeEnum.enum[:remove] } }
    let(:expected_result) { [] }

    before do
      merge_request.assignees = [assignee]
      merge_request.save!
    end

    it 'removes the users in the list, while adding none' do
      post_graphql_mutation(mutation, current_user: current_user)

      expect(response).to have_gitlab_http_status(:success)
      expect(mutation_assignee_nodes).to match_array(expected_result)
    end
  end
end
