# frozen_string_literal: true

require 'spec_helper'

describe 'Setting an issue as confidential' do
  include GraphqlHelpers

  let(:current_user) { create(:user) }
  let(:issue) { create(:issue) }
  let(:project) { issue.project }
  let(:input) { { confidential: true } }

  let(:mutation) do
    variables = {
      project_path: project.full_path,
      iid: issue.iid.to_s
    }
    graphql_mutation(:issue_set_confidential, variables.merge(input),
                     <<-QL.strip_heredoc
                       clientMutationId
                       errors
                       issue {
                         iid
                         confidential
                       }
                     QL
    )
  end

  def mutation_response
    graphql_mutation_response(:issue_set_confidential)
  end

  before do
    project.add_developer(current_user)
  end

  it 'returns an error if the user is not allowed to update the issue' do
    error = "The resource that you are attempting to access does not exist or you don't have permission to perform this action"
    post_graphql_mutation(mutation, current_user: create(:user))

    expect(graphql_errors).to include(a_hash_including('message' => error))
  end

  it 'updates the issue confidentiality' do
    post_graphql_mutation(mutation, current_user: current_user)

    expect(response).to have_gitlab_http_status(:success)
    expect(mutation_response['issue']['confidential']).to be_truthy
  end
end
