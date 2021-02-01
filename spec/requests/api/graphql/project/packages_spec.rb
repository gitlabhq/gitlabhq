# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'getting a package list for a project' do
  include GraphqlHelpers

  let_it_be(:project) { create(:project, :repository) }
  let_it_be(:current_user) { create(:user) }

  let_it_be(:package) { create(:package, project: project) }
  let_it_be(:maven_package) { create(:maven_package, project: project) }
  let_it_be(:debian_package) { create(:debian_package, project: project) }
  let_it_be(:composer_package) { create(:composer_package, project: project) }
  let_it_be(:composer_metadatum) do
    create(:composer_metadatum, package: composer_package,
           target_sha: 'afdeh',
           composer_json: { name: 'x', type: 'y', license: 'z', version: 1 })
  end

  let(:package_names) { graphql_data_at(:project, :packages, :edges, :node, :name) }

  let(:fields) do
    <<~QUERY
    edges {
      node {
        #{all_graphql_fields_for('packages'.classify, excluded: ['project'])}
        metadata { #{query_graphql_fragment('ComposerMetadata')} }
      }
    }
    QUERY
  end

  let(:query) do
    graphql_query_for(
      'project',
      { 'fullPath' => project.full_path },
      query_graphql_field('packages', {}, fields)
    )
  end

  context 'when user has access to the project' do
    before do
      project.add_reporter(current_user)
      post_graphql(query, current_user: current_user)
    end

    it_behaves_like 'a working graphql query'

    it 'returns packages successfully' do
      expect(package_names).to contain_exactly(
        package.name,
        maven_package.name,
        debian_package.name,
        composer_package.name
      )
    end

    it 'deals with metadata' do
      target_shas = graphql_data_at(:project, :packages, :edges, :node, :metadata, :target_sha)
      expect(target_shas).to contain_exactly(composer_metadatum.target_sha)
    end
  end

  context 'when the user does not have access to the project/packages' do
    before do
      post_graphql(query, current_user: current_user)
    end

    it_behaves_like 'a working graphql query'

    it 'returns nil' do
      expect(graphql_data['project']).to be_nil
    end
  end

  context 'when the user is not authenticated' do
    before do
      post_graphql(query)
    end

    it_behaves_like 'a working graphql query'

    it 'returns nil' do
      expect(graphql_data['project']).to be_nil
    end
  end
end
