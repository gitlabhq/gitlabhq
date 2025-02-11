# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Setting Due Date of an issue', feature_category: :team_planning do
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
    graphql_mutation(
      :issue_set_due_date,
      variables.merge(input),
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
    error = Gitlab::Graphql::Authorize::AuthorizeResource::RESOURCE_ACCESS_ERROR
    post_graphql_mutation(mutation, current_user: create(:user))

    expect(graphql_errors).to include(a_hash_including('message' => error))
  end

  context 'when due date value is a valid date' do
    it 'updates the issue due date' do
      post_graphql_mutation(mutation, current_user: current_user)

      expect(response).to have_gitlab_http_status(:success)
      expect(mutation_response['issue']['dueDate']).to eq(2.days.since.to_date.to_s)
    end
  end

  context 'when due date value is null' do
    let(:input) { { due_date: nil } }

    it 'updates the issue to remove the due date' do
      post_graphql_mutation(mutation, current_user: current_user)

      expect(response).to have_gitlab_http_status(:success)
      expect(mutation_response['issue']['dueDate']).to be_nil
    end
  end

  context 'when due date argument is not given' do
    let(:input) { {} }

    it 'returns an error' do
      post_graphql_mutation(mutation, current_user: current_user)

      expect(graphql_errors).to include(
        a_hash_including('message' => 'issueSetDueDate must include the following argument: dueDate.')
      )
    end
  end

  context 'when the due date value is not a valid time' do
    let(:input) { { due_date: 'test' } }

    it 'returns a coercion error' do
      post_graphql_mutation(mutation, current_user: current_user)

      expect(graphql_errors).to include(a_hash_including('message' => /provided invalid value for dueDate/))
    end
  end
end
