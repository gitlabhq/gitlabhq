# frozen_string_literal: true

RSpec.shared_examples 'creating a new HTTP integration' do
  it 'creates a new integration' do
    post_graphql_mutation(mutation, current_user: current_user)

    new_integration = ::AlertManagement::HttpIntegration.last!
    integration_response = mutation_response['integration']

    expect(response).to have_gitlab_http_status(:success)
    expect(integration_response['id']).to eq(GitlabSchema.id_from_object(new_integration).to_s)
    expect(integration_response['type']).to eq('HTTP')
    expect(integration_response['name']).to eq(new_integration.name)
    expect(integration_response['active']).to eq(new_integration.active)
    expect(integration_response['token']).to eq(new_integration.token)
    expect(integration_response['url']).to eq(new_integration.url)
    expect(integration_response['apiUrl']).to eq(nil)
  end
end
