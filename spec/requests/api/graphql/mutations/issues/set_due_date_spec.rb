# frozen_string_literal: true

require 'spec_helper'

describe 'Setting Due Date of an issue' do
  include GraphqlHelpers

  let(:current_user) { create(:user) }
  let(:issue) { create(:issue) }
  let(:project) { issue.project }
  let(:input) { { due_date: 2.days.since } }

  let(:mutation) do
    variables = {
      project_path: project.full_path,
      iid: issue.iid.to_s
    }
    graphql_mutation(:issue_set_due_date, variables.merge(input),
                     <<-QL.strip_heredoc
                       clientMutationId
                       errors
                       issue {
                         iid
                         dueDate
                       }
                     QL
    )
  end

  def mutation_response
    graphql_mutation_response(:issue_set_due_date)
  end

  before do
    project.add_developer(current_user)
  end

  it 'returns an error if the user is not allowed to update the issue' do
    error = "The resource that you are attempting to access does not exist or you don't have permission to perform this action"
    post_graphql_mutation(mutation, current_user: create(:user))

    expect(graphql_errors).to include(a_hash_including('message' => error))
  end

  it 'updates the issue due date' do
    post_graphql_mutation(mutation, current_user: current_user)

    expect(response).to have_gitlab_http_status(:success)
    expect(mutation_response['issue']['dueDate']).to eq(2.days.since.to_date.to_s)
  end

  context 'when passing due date without a date value' do
    let(:input) { { due_date: 'test' } }

    it 'returns internal server error' do
      post_graphql_mutation(mutation, current_user: current_user)

      expect(graphql_errors).to include(a_hash_including('message' => 'Internal server error'))
    end
  end
end
