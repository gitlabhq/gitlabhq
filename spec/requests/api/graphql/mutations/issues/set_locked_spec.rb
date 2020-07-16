# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Setting an issue as locked' do
  include GraphqlHelpers

  let_it_be(:current_user) { create(:user) }
  let_it_be(:issue) { create(:issue) }
  let_it_be(:project) { issue.project }
  let(:input) { { locked: true } }

  let(:mutation) do
    variables = {
      project_path: project.full_path,
      iid: issue.iid.to_s
    }
    graphql_mutation(:issue_set_locked, variables.merge(input),
                     <<-QL.strip_heredoc
                       clientMutationId
                       errors
                       issue {
                         iid
                         discussionLocked
                       }
                     QL
    )
  end

  def mutation_response
    graphql_mutation_response(:issue_set_locked)
  end

  context 'when the user is not allowed to update the issue' do
    it 'returns an error' do
      error = "The resource that you are attempting to access does not exist or you don't have permission to perform this action"
      post_graphql_mutation(mutation, current_user: current_user)

      expect(graphql_errors).to include(a_hash_including('message' => error))
    end
  end

  context 'when user is allowed to update the issue' do
    before do
      project.add_developer(current_user)
    end

    it 'updates the issue locked status' do
      post_graphql_mutation(mutation, current_user: current_user)

      expect(response).to have_gitlab_http_status(:success)
      expect(mutation_response['issue']['discussionLocked']).to be_truthy
    end
  end
end
