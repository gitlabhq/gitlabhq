# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Setting reviewers of a merge request', :assume_throttled, feature_category: :code_review_workflow do
  include GraphqlHelpers

  let_it_be(:project) { create(:project, :repository) }
  let_it_be(:current_user) { create(:user, developer_of: project) }
  let_it_be(:reviewer) { create(:user) }
  let_it_be(:reviewer2) { create(:user) }
  let_it_be_with_reload(:merge_request) { create(:merge_request, source_project: project) }

  let(:input) { { reviewer_usernames: [reviewer.username] } }
  let(:expected_result) do
    [{ 'username' => reviewer.username }]
  end

  let(:mutation) do
    variables = {
      project_path: project.full_path,
      iid: merge_request.iid.to_s
    }
    graphql_mutation(
      :merge_request_set_reviewers,
      variables.merge(input),
      <<-QL.strip_heredoc
        clientMutationId
        errors
        mergeRequest {
          id
          reviewers {
            nodes {
              username
            }
          }
        }
      QL
    )
  end

  def mutation_response
    graphql_mutation_response(:merge_request_set_reviewers)
  end

  def mutation_reviewer_nodes
    mutation_response['mergeRequest']['reviewers']['nodes']
  end

  def run_mutation!
    post_graphql_mutation(mutation, current_user: current_user)
  end

  before do
    project.add_developer(reviewer)
    project.add_developer(reviewer2)

    merge_request.update!(reviewers: [])
  end

  it 'returns an error if the user is not allowed to update the merge request' do
    post_graphql_mutation(mutation, current_user: create(:user))

    expect(graphql_errors).not_to be_empty
  end

  context 'when the current user does not have permission to add reviewers' do
    let(:current_user) { create(:user) }

    it 'does not change the reviewers' do
      project.add_guest(current_user)

      expect { run_mutation! }.not_to change { merge_request.reset.reviewers.pluck(:id) }

      expect(graphql_errors).not_to be_empty
    end
  end

  context 'with reviewers already assigned' do
    before do
      merge_request.reviewers = [reviewer2]
      merge_request.save!
    end

    it 'replaces the reviewer' do
      run_mutation!

      expect(response).to have_gitlab_http_status(:success)
      expect(mutation_reviewer_nodes).to match_array(expected_result)
    end
  end

  context 'when passing an empty list of reviewers' do
    let(:input) { { reviewer_usernames: [] } }

    before do
      merge_request.reviewers = [reviewer2]
      merge_request.save!
    end

    it 'removes reviewer' do
      run_mutation!

      expect(response).to have_gitlab_http_status(:success)
      expect(mutation_reviewer_nodes).to eq([])
    end
  end
end
