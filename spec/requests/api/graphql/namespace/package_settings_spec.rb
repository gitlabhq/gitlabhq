# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'getting namespace package settings in a namespace' do
  include GraphqlHelpers

  let_it_be(:package_settings) { create(:namespace_package_setting) }
  let_it_be(:namespace) { package_settings.namespace }
  let_it_be(:current_user) { namespace.owner }

  let(:package_settings_response) { graphql_data.dig('namespace', 'packageSettings') }
  let(:fields) { all_graphql_fields_for('PackageSettings') }

  let(:query) do
    graphql_query_for(
      'namespace',
      { 'fullPath' => namespace.full_path },
      query_graphql_field('package_settings', {}, fields)
    )
  end

  subject { post_graphql(query, current_user: current_user) }

  it_behaves_like 'a working graphql query' do
    before do
      subject
    end

    it 'matches the JSON schema' do
      expect(package_settings_response).to match_schema('graphql/namespace/package_settings')
    end
  end
end
