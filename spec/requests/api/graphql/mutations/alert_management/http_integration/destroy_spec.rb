# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Removing an HTTP Integration', feature_category: :incident_management do
  include GraphqlHelpers

  let_it_be(:user) { create(:user) }
  let_it_be(:project) { create(:project, maintainers: user) }
  let_it_be(:integration) { create(:alert_management_http_integration, project: project) }

  let(:mutation) do
    variables = {
      id: GitlabSchema.id_from_object(integration).to_s
    }
    graphql_mutation(:http_integration_destroy, variables) do
      <<~QL
         clientMutationId
         errors
         integration {
           id
           type
           name
           active
           token
           url
           apiUrl
         }
      QL
    end
  end

  let(:mutation_response) { graphql_mutation_response(:http_integration_destroy) }

  it 'removes the integration' do
    post_graphql_mutation(mutation, current_user: user)

    integration_response = mutation_response['integration']

    expect(response).to have_gitlab_http_status(:success)
    expect(integration_response['id']).to eq(GitlabSchema.id_from_object(integration).to_s)
    expect(integration_response['type']).to eq('HTTP')
    expect(integration_response['name']).to eq(integration.name)
    expect(integration_response['active']).to eq(integration.active)
    expect(integration_response['token']).to eq(integration.token)
    expect(integration_response['url']).to eq(integration.url)
    expect(integration_response['apiUrl']).to eq(nil)

    expect { integration.reload }.to raise_error ActiveRecord::RecordNotFound
  end
end
