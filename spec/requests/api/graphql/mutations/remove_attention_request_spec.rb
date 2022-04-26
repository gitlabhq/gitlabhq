# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Remove attention request' do
  include GraphqlHelpers

  let_it_be(:current_user) { create(:user) }
  let_it_be(:user) { create(:user) }
  let_it_be(:merge_request) { create(:merge_request, reviewers: [user]) }
  let_it_be(:project) { merge_request.project }

  let(:input) { { user_id: global_id_of(user) } }

  let(:mutation) do
    variables = {
      project_path: project.full_path,
      iid: merge_request.iid.to_s
    }
    graphql_mutation(:merge_request_remove_attention_request, variables.merge(input),
                     <<-QL.strip_heredoc
                       clientMutationId
                       errors
    QL
    )
  end

  def mutation_response
    graphql_mutation_response(:merge_request_remove_attention_request)
  end

  def mutation_errors
    mutation_response['errors']
  end

  before_all do
    project.add_developer(current_user)
    project.add_developer(user)
  end

  it 'is successful' do
    post_graphql_mutation(mutation, current_user: current_user)

    expect(response).to have_gitlab_http_status(:success)
    expect(mutation_errors).to be_empty
  end

  context 'when current user is not allowed to update the merge request' do
    it 'returns an error' do
      post_graphql_mutation(mutation, current_user: create(:user))

      expect(graphql_errors).not_to be_empty
    end
  end

  context 'when user is not a reviewer' do
    let(:input) { { user_id: global_id_of(create(:user)) } }

    it 'returns an error' do
      post_graphql_mutation(mutation, current_user: current_user)

      expect(response).to have_gitlab_http_status(:success)
      expect(mutation_errors).not_to be_empty
    end
  end
end
