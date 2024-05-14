# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Creating a new Prometheus Integration', feature_category: :incident_management do
  include GraphqlHelpers

  let_it_be(:current_user) { create(:user) }
  let_it_be(:project) { create(:project, maintainers: current_user) }

  let(:api_url) { 'https://prometheus-url.com' }

  let(:variables) do
    {
      project_path: project.full_path,
      active: false,
      api_url: api_url
    }
  end

  let(:mutation) do
    graphql_mutation(:prometheus_integration_create, variables) do
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

  let(:mutation_response) { graphql_mutation_response(:prometheus_integration_create) }

  it 'creates a new integration' do
    post_graphql_mutation(mutation, current_user: current_user)

    new_integration = ::Integrations::Prometheus.last!
    integration_response = mutation_response['integration']

    expect(response).to have_gitlab_http_status(:success)
    expect(integration_response['id']).to eq(GitlabSchema.id_from_object(new_integration).to_s)
    expect(integration_response['type']).to eq('PROMETHEUS')
    expect(integration_response['name']).to eq(new_integration.title)
    expect(integration_response['active']).to eq(new_integration.manual_configuration?)
    expect(integration_response['token']).to eq(new_integration.project.alerting_setting.token)
    expect(integration_response['url']).to eq("http://localhost/#{project.full_path}/prometheus/alerts/notify.json")
    expect(integration_response['apiUrl']).to eq(new_integration.api_url)
  end

  context 'without api url' do
    let(:api_url) { nil }

    it 'creates a new integration' do
      post_graphql_mutation(mutation, current_user: current_user)

      integration_response = mutation_response['integration']

      expect(response).to have_gitlab_http_status(:success)
      expect(integration_response['apiUrl']).to be_nil
    end
  end

  [:project_path, :active].each do |argument|
    context "without required argument #{argument}" do
      before do
        variables.delete(argument)
      end

      it_behaves_like 'an invalid argument to the mutation', argument_name: argument
    end
  end
end
