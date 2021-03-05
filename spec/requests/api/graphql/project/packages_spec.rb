# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'getting a package list for a project' do
  include GraphqlHelpers

  let_it_be(:resource) { create(:project, :repository) }
  let_it_be(:current_user) { create(:user) }

  let_it_be(:package) { create(:package, project: resource) }
  let_it_be(:maven_package) { create(:maven_package, project: resource) }
  let_it_be(:debian_package) { create(:debian_package, project: resource) }
  let_it_be(:composer_package) { create(:composer_package, project: resource) }
  let_it_be(:composer_metadatum) do
    create(:composer_metadatum, package: composer_package,
           target_sha: 'afdeh',
           composer_json: { name: 'x', type: 'y', license: 'z', version: 1 })
  end

  let(:package_names) { graphql_data_at(:project, :packages, :nodes, :name) }
  let(:target_shas) { graphql_data_at(:project, :packages, :nodes, :metadata, :target_sha) }
  let(:packages) { graphql_data_at(:project, :packages, :nodes) }

  let(:fields) do
    <<~QUERY
    nodes {
      #{all_graphql_fields_for('packages'.classify, excluded: ['project'])}
      metadata { #{query_graphql_fragment('ComposerMetadata')} }
    }
    QUERY
  end

  let(:query) do
    graphql_query_for(
      'project',
      { 'fullPath' => resource.full_path },
      query_graphql_field('packages', {}, fields)
    )
  end

  it_behaves_like 'group and project packages query'
end
