# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Setting severity level of an incident', feature_category: :incident_management do
  include GraphqlHelpers

  let_it_be(:incident) { create(:incident) }
  let_it_be(:project) { incident.project }
  let_it_be(:planner) { create(:user, planner_of: project) }
  let_it_be(:reporter) { create(:user, reporter_of: project) }

  let(:input) { { severity: 'CRITICAL' } }

  let(:mutation) do
    variables = {
      project_path: project.full_path,
      iid: incident.iid.to_s
    }

    graphql_mutation(
      :issue_set_severity,
      variables.merge(input),
      <<-QL.strip_heredoc
        clientMutationId
        errors
        issue {
          iid
          severity
        }
      QL
    )
  end

  def mutation_response
    graphql_mutation_response(:issue_set_severity)
  end

  context 'when the user is not allowed to update the incident' do
    let(:user) { planner }

    it 'returns an error' do
      error = Gitlab::Graphql::Authorize::AuthorizeResource::RESOURCE_ACCESS_ERROR
      post_graphql_mutation(mutation, current_user: user)

      expect(response).to have_gitlab_http_status(:success)
      expect(graphql_errors).to include(a_hash_including('message' => error))
    end
  end

  context 'when the user is allowed to update the incident' do
    let(:user) { reporter }

    it 'updates the issue' do
      post_graphql_mutation(mutation, current_user: user)

      expect(response).to have_gitlab_http_status(:success)
      expect(mutation_response.dig('issue', 'severity')).to eq('CRITICAL')
    end
  end
end
