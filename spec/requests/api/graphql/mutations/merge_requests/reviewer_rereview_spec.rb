# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Setting assignees of a merge request', feature_category: :code_review_workflow do
  include GraphqlHelpers

  let(:current_user) { create(:user) }
  let(:merge_request) { create(:merge_request, reviewers: [user]) }
  let(:project) { merge_request.project }
  let(:user) { create(:user) }
  let(:input) { { user_id: global_id_of(user) } }

  let(:mutation) do
    variables = {
      project_path: project.full_path,
      iid: merge_request.iid.to_s
    }
    graphql_mutation(
      :merge_request_reviewer_rereview,
      variables.merge(input),
      <<-QL.strip_heredoc
        clientMutationId
        errors
      QL
    )
  end

  def mutation_response
    graphql_mutation_response(:merge_request_reviewer_rereview)
  end

  def mutation_errors
    mutation_response['errors']
  end

  before do
    project.add_developer(current_user)
    project.add_developer(user)
  end

  it 'returns an error if the user is not allowed to update the merge request' do
    post_graphql_mutation(mutation, current_user: create(:user))

    expect(graphql_errors).not_to be_empty
  end

  describe 'reviewer does not exist' do
    let(:input) { { user_id: global_id_of(create(:user)) } }

    it 'returns an error' do
      post_graphql_mutation(mutation, current_user: current_user)

      expect(response).to have_gitlab_http_status(:success)
      expect(mutation_errors).not_to be_empty
    end
  end

  describe 'reviewer exists' do
    it 'does not return an error' do
      post_graphql_mutation(mutation, current_user: current_user)

      expect(response).to have_gitlab_http_status(:success)
      expect(mutation_errors).to be_empty
    end
  end
end
