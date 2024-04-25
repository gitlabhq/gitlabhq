# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Updating an existing Prometheus Integration', feature_category: :incident_management do
  include GraphqlHelpers

  let_it_be(:user) { create(:user) }
  let_it_be(:project) { create(:project, maintainers: user) }
  let_it_be(:integration) { create(:prometheus_integration, project: project) }

  let(:mutation) do
    variables = {
      id: GitlabSchema.id_from_object(integration).to_s,
      api_url: 'http://modified-url.com',
      active: true
    }
    graphql_mutation(:prometheus_integration_update, variables) do
      <<~QL
         clientMutationId
         errors
         integration {
           id
           active
           apiUrl
         }
      QL
    end
  end

  let(:mutation_response) { graphql_mutation_response(:prometheus_integration_update) }

  it 'updates the integration' do
    post_graphql_mutation(mutation, current_user: user)

    integration_response = mutation_response['integration']

    expect(response).to have_gitlab_http_status(:success)
    expect(integration_response['id']).to eq(GitlabSchema.id_from_object(integration).to_s)
    expect(integration_response['apiUrl']).to eq('http://modified-url.com')
    expect(integration_response['active']).to be_truthy
  end
end
