# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Resetting a token on an existing HTTP Integration', feature_category: :incident_management do
  include GraphqlHelpers

  let_it_be(:user) { create(:user) }
  let_it_be(:project) { create(:project, maintainers: user) }
  let_it_be(:integration) { create(:alert_management_http_integration, project: project) }

  let(:mutation) do
    variables = {
      id: GitlabSchema.id_from_object(integration).to_s
    }
    graphql_mutation(:http_integration_reset_token, variables) do
      <<~QL
         clientMutationId
         errors
         integration {
           id
           token
         }
      QL
    end
  end

  let(:mutation_response) { graphql_mutation_response(:http_integration_reset_token) }

  it 'updates the integration' do
    previous_token = integration.token

    post_graphql_mutation(mutation, current_user: user)
    integration_response = mutation_response['integration']

    expect(response).to have_gitlab_http_status(:success)
    expect(integration_response['id']).to eq(GitlabSchema.id_from_object(integration).to_s)
    expect(integration_response['token']).not_to eq(previous_token)
    expect(integration_response['token']).to eq(integration.reload.token)
  end
end
