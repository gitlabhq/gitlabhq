# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Updating an existing HTTP Integration' do
  include GraphqlHelpers

  let_it_be(:user) { create(:user) }
  let_it_be(:project) { create(:project) }
  let_it_be(:integration) { create(:alert_management_http_integration, project: project) }

  let(:mutation) do
    variables = {
      id: GitlabSchema.id_from_object(integration).to_s,
      name: 'Modified Name',
      active: false
    }
    graphql_mutation(:http_integration_update, variables) do
      <<~QL
         clientMutationId
         errors
         integration {
           id
           name
           active
           url
         }
      QL
    end
  end

  let(:mutation_response) { graphql_mutation_response(:http_integration_update) }

  before do
    project.add_maintainer(user)
  end

  it 'updates the integration' do
    post_graphql_mutation(mutation, current_user: user)

    integration_response = mutation_response['integration']

    expect(response).to have_gitlab_http_status(:success)
    expect(integration_response['id']).to eq(GitlabSchema.id_from_object(integration).to_s)
    expect(integration_response['name']).to eq('Modified Name')
    expect(integration_response['active']).to be_falsey
    expect(integration_response['url']).to include('modified-name')
  end
end
