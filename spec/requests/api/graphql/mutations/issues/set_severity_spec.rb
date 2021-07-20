# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Setting severity level of an incident' do
  include GraphqlHelpers

  let_it_be(:user) { create(:user) }

  let(:incident) { create(:incident) }
  let(:project) { incident.project }
  let(:input) { { severity: 'CRITICAL' } }

  let(:mutation) do
    variables = {
      project_path: project.full_path,
      iid: incident.iid.to_s
    }

    graphql_mutation(:issue_set_severity, variables.merge(input),
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
    it 'returns an error' do
      error = "The resource that you are attempting to access does not exist or you don't have permission to perform this action"
      post_graphql_mutation(mutation, current_user: user)

      expect(response).to have_gitlab_http_status(:success)
      expect(graphql_errors).to include(a_hash_including('message' => error))
    end
  end

  context 'when the user is allowed to update the incident' do
    before do
      project.add_developer(user)
    end

    it 'updates the issue' do
      post_graphql_mutation(mutation, current_user: user)

      expect(response).to have_gitlab_http_status(:success)
      expect(mutation_response.dig('issue', 'severity')).to eq('CRITICAL')
    end
  end
end
