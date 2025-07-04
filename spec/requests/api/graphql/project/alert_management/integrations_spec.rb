# frozen_string_literal: true
require 'spec_helper'

RSpec.describe 'getting Alert Management Integrations', feature_category: :incident_management do
  include ::Gitlab::Routing
  include GraphqlHelpers

  let_it_be(:project) { create(:project, :repository) }
  let_it_be(:current_user) { create(:user) }
  let_it_be(:old_prometheus_integration) { create(:prometheus_integration, project: project) }
  let_it_be(:prometheus_integration) { create(:alert_management_prometheus_integration, :legacy, project: project) }
  let_it_be(:active_http_integration) { create(:alert_management_http_integration, project: project) }
  let_it_be(:inactive_http_integration) { create(:alert_management_http_integration, :inactive, project: project) }
  let_it_be(:other_project_http_integration) { create(:alert_management_http_integration) }

  let(:params) { {} }

  let(:fields) do
    <<~QUERY
      nodes {
        #{all_graphql_fields_for('AlertManagementIntegration')}
      }
    QUERY
  end

  let(:query) do
    graphql_query_for(
      'project',
      { 'fullPath' => project.full_path },
      query_graphql_field('alertManagementIntegrations', params, fields)
    )
  end

  context 'with integrations' do
    let(:integrations) { graphql_data.dig('project', 'alertManagementIntegrations', 'nodes') }

    context 'without project permissions' do
      let(:user) { create(:user) }

      before do
        post_graphql(query, current_user: current_user)
      end

      it_behaves_like 'a working graphql query'

      it { expect(integrations).to be_nil }
    end

    context 'with project permissions' do
      before do
        project.add_maintainer(current_user)
        post_graphql(query, current_user: current_user)
      end

      context 'when no extra params given' do
        it_behaves_like 'a working graphql query'

        it 'returns the correct properties of the integrations' do
          expect(integrations).to match [
            a_graphql_entity_for(
              active_http_integration,
              :name, :active, :token, :url, type: 'HTTP', api_url: nil
            ),
            a_graphql_entity_for(
              prometheus_integration,
              :name, :active, :token, :url, type: 'PROMETHEUS', api_url: nil
            )
          ]
        end
      end

      context 'when HTTP Integration ID is given' do
        let(:params) { { id: global_id_of(active_http_integration) } }

        it_behaves_like 'a working graphql query'

        it 'returns the correct properties of the HTTP integration' do
          expect(integrations).to contain_exactly a_graphql_entity_for(
            active_http_integration, :name, :active, :token, :url, type: 'HTTP', api_url: nil
          )
        end
      end

      context 'when Prometheus Integration ID is given' do
        let(:params) { { id: global_id_of(old_prometheus_integration) } }

        it_behaves_like 'a working graphql query'

        it 'returns the correct properties of the Prometheus Integration' do
          expect(integrations).to contain_exactly a_graphql_entity_for(
            prometheus_integration,
            :name, :active, :token, :url, type: 'PROMETHEUS', api_url: nil
          )
        end
      end

      it_behaves_like 'GraphQL query with several integrations requested', graphql_query_name: 'alertManagementIntegrations'
    end
  end
end
