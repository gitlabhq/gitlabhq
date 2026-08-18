# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Query.ciCatalogBundledResources', feature_category: :pipeline_composition do
  include GraphqlHelpers

  let_it_be(:user) { create(:user) }
  let_it_be(:bundled_resource) do
    create(:ci_catalog_bundled_resource, name: 'SAST', full_path: 'components/sast', server_fqdn: 'gitlab.com')
  end

  let(:query) do
    graphql_query_for('ciCatalogBundledResources', {}, 'nodes { id name fullPath serverFqdn }')
  end

  subject(:nodes) { graphql_data.dig('ciCatalogBundledResources', 'nodes') }

  context 'when the ci_catalog_bundled_components flag is enabled' do
    before do
      post_graphql(query, current_user: user)
    end

    it 'returns the bundled resources on the cell' do
      expect(nodes).to be_present
      expect(nodes.first).to include('name' => 'SAST', 'fullPath' => 'components/sast')
    end
  end

  context 'with latestVersionName' do
    let(:query) do
      graphql_query_for('ciCatalogBundledResources', {}, 'nodes { id name latestVersionName }')
    end

    before_all do
      create(:ci_catalog_bundled_resource_version, bundled_resource: bundled_resource, semver: '1.0.0')
      create(:ci_catalog_bundled_resource_version, bundled_resource: bundled_resource, semver: '2.1.0')
    end

    it 'returns the highest semantic version' do
      post_graphql(query, current_user: user)

      expect(nodes.first).to include('latestVersionName' => '2.1.0')
    end

    it 'avoids N+1 queries when resolving versions for multiple resources' do
      post_graphql(query, current_user: user)

      control = ActiveRecord::QueryRecorder.new { post_graphql(query, current_user: user) }

      other_resource = create(:ci_catalog_bundled_resource, name: 'DAST', full_path: 'components/dast')
      create(:ci_catalog_bundled_resource_version, bundled_resource: other_resource, semver: '3.0.0')

      expect { post_graphql(query, current_user: user) }.not_to exceed_query_limit(control)
    end
  end

  context 'when the ci_catalog_bundled_components flag is disabled' do
    before do
      stub_feature_flags(ci_catalog_bundled_components: false)
      post_graphql(query, current_user: user)
    end

    it 'returns no bundled resources' do
      expect(nodes).to be_empty
    end
  end

  it_behaves_like 'authorizing granular token permissions for GraphQL', :read_catalog_bundled_resource do
    let(:boundary_object) { :instance }
    let(:request) { post_graphql(query, token: { personal_access_token: pat }) }
  end
end
