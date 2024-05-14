# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Querying for integration exclusions', feature_category: :integrations do
  include GraphqlHelpers
  let_it_be(:project) { create(:project) }
  let_it_be(:project2) { create(:project) }
  let_it_be(:admin_user) { create(:admin) }
  let_it_be(:user) { create(:user) }
  let(:current_user) { admin_user }
  let(:query) { graphql_query_for('integrationExclusions', args, fields) }
  let(:args) { { 'integrationName' => :BEYOND_IDENTITY } }
  let(:fields) do
    <<~GRAPHQL
      nodes {
        project {
          id
        }
      }
    GRAPHQL
  end

  context 'when the user is authorized' do
    let!(:instance_integration)  { create(:beyond_identity_integration) }
    let!(:integration_exclusion) do
      create(:beyond_identity_integration, active: false, instance: false, project: project2, inherit_from_id: nil)
    end

    let!(:propagated_integration) do
      create(:beyond_identity_integration, active: false, instance: false, project: project,
        inherit_from_id: instance_integration.id)
    end

    before do
      post_graphql(query, current_user: current_user)
    end

    it_behaves_like 'a working graphql query that returns data'

    it 'returns projects that are custom exclusions' do
      nodes = graphql_data['integrationExclusions']['nodes']
      expect(nodes.size).to eq(1)
      expect(nodes).to include(a_hash_including('project' => { 'id' => project2.to_global_id.to_s }))
    end
  end

  context 'when the user is not authorized' do
    let(:current_user) { user }

    it 'responds with an error' do
      post_graphql(query, current_user: current_user)
      expect(graphql_errors.first['message']).to eq(
        Gitlab::Graphql::Authorize::AuthorizeResource::RESOURCE_ACCESS_ERROR
      )
    end
  end

  context 'when the user is not authenticated' do
    let(:current_user) { nil }

    it 'responds with an error' do
      post_graphql(query, current_user: current_user)
      expect(graphql_errors.first['message']).to eq(
        Gitlab::Graphql::Authorize::AuthorizeResource::RESOURCE_ACCESS_ERROR
      )
    end
  end
end
