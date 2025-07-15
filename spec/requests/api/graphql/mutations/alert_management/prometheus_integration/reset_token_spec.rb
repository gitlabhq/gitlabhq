# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Resetting a token on an existing Prometheus Integration', feature_category: :incident_management do
  include GraphqlHelpers

  let_it_be(:user) { create(:user) }
  let_it_be(:project) { create(:project, maintainers: user) }
  let_it_be(:old_integration) { create(:prometheus_integration, project: project) }
  let_it_be(:integration) { create(:alert_management_prometheus_integration, :legacy, project: project) }

  let(:mutation) do
    variables = {
      id: GitlabSchema.id_from_object(old_integration).to_s
    }
    graphql_mutation(:prometheus_integration_reset_token, variables) do
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

  let(:mutation_response) { graphql_mutation_response(:prometheus_integration_reset_token) }

  it 'updates the token' do
    expect { post_graphql_mutation(mutation, current_user: user) }
      .to change { integration.reload.token }

    integration_response = mutation_response['integration']

    expect(response).to have_gitlab_http_status(:success)
    expect(integration_response['id']).to eq(GitlabSchema.id_from_object(integration).to_s)
    expect(integration_response['token']).not_to be_nil
    expect(integration_response['token']).to eq(integration.token)
  end
end
