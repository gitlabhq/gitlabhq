# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'getting a package list for a group' do
  include GraphqlHelpers

  let_it_be(:resource) { create(:group, :private) }
  let_it_be(:group_two) { create(:group, :private) }
  let_it_be(:project) { create(:project, :repository, group: resource) }
  let_it_be(:another_project) { create(:project, :repository, group: resource) }
  let_it_be(:group_two_project) { create(:project, :repository, group: group_two) }
  let_it_be(:current_user) { create(:user) }

  let_it_be(:package) { create(:package, project: project) }
  let_it_be(:npm_package) { create(:npm_package, project: group_two_project) }
  let_it_be(:maven_package) { create(:maven_package, project: project) }
  let_it_be(:debian_package) { create(:debian_package, project: another_project) }
  let_it_be(:composer_package) { create(:composer_package, project: another_project) }
  let_it_be(:composer_metadatum) do
    create(:composer_metadatum, package: composer_package,
           target_sha: 'afdeh',
           composer_json: { name: 'x', type: 'y', license: 'z', version: 1 })
  end

  let(:package_names) { graphql_data_at(:group, :packages, :nodes, :name) }
  let(:target_shas) { graphql_data_at(:group, :packages, :nodes, :metadata, :target_sha) }
  let(:packages) { graphql_data_at(:group, :packages, :nodes) }

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
      'group',
      { 'fullPath' => resource.full_path },
      query_graphql_field('packages', {}, fields)
    )
  end

  it_behaves_like 'group and project packages query'

  context 'with a batched query' do
    let(:batch_query) do
      <<~QUERY
      {
        a: group(fullPath: "#{resource.full_path}") { packages { nodes { name } } }
        b: group(fullPath: "#{group_two.full_path}") { packages { nodes { name } } }
      }
      QUERY
    end

    let(:a_packages_names) { graphql_data_at(:a, :packages, :nodes, :name) }

    before do
      resource.add_reporter(current_user)
      group_two.add_reporter(current_user)
      post_graphql(batch_query, current_user: current_user)
    end

    it 'returns an error for the second group and data for the first' do
      expect(a_packages_names).to contain_exactly(
        package.name,
        maven_package.name,
        debian_package.name,
        composer_package.name
      )
      expect_graphql_errors_to_include [/Packages can be requested only for one group at a time/]
      expect(graphql_data_at(:b, :packages)).to be(nil)
    end
  end
end
