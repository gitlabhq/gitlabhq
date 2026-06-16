# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Setting assignees of an issue', feature_category: :team_planning do
  include GraphqlHelpers

  let_it_be(:current_user) { create(:user) }
  let_it_be(:project) { create(:project) }
  let_it_be(:issue) { create(:issue, project: project) }
  let_it_be(:assignee) { create(:user) }

  let(:input) { { assignee_usernames: [assignee.username] } }

  let(:mutation) do
    variables = { project_path: project.full_path, iid: issue.iid.to_s }
    graphql_mutation(
      :issue_set_assignees,
      variables.merge(input),
      <<-QL.strip_heredoc
        clientMutationId
        errors
        issue {
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
    graphql_mutation_response(:issue_set_assignees)
  end

  before_all do
    project.add_developer(current_user)
    project.add_developer(assignee)
  end

  it 'returns an error if the user is not allowed to update the issue' do
    error = Gitlab::Graphql::Authorize::AuthorizeResource::RESOURCE_ACCESS_ERROR
    post_graphql_mutation(mutation, current_user: create(:user))

    expect(graphql_errors).to include(a_hash_including('message' => error))
  end

  it 'assigns the user to the issue' do
    post_graphql_mutation(mutation, current_user: current_user)

    expect(response).to have_gitlab_http_status(:success)
    expect(mutation_response.dig('issue', 'assignees', 'nodes')).to match_array(
      [{ 'username' => assignee.username }]
    )
  end

  it_behaves_like 'authorizing granular token permissions for GraphQL', :update_issue do
    let(:user) { current_user }
    let(:boundary_object) { project }
    let(:mutation) do
      graphql_mutation(
        :issue_set_assignees,
        { project_path: project.full_path, iid: issue.iid.to_s, assignee_usernames: [assignee.username] },
        'errors'
      )
    end

    let(:request) { post_graphql_mutation(mutation, token: { personal_access_token: pat }) }
  end
end
