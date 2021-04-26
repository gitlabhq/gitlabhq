# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'getting a package list for a project' do
  include GraphqlHelpers

  let_it_be(:resource) { create(:project, :repository) }
  let_it_be(:current_user) { create(:user) }
  let_it_be(:maven_package) { create(:maven_package, project: resource, name: 'tab', version: '4.0.0', created_at: 5.days.ago) }
  let_it_be(:package) { create(:npm_package, project: resource, name: 'uab', version: '5.0.0', created_at: 4.days.ago) }
  let_it_be(:composer_package) { create(:composer_package, project: resource, name: 'vab', version: '6.0.0', created_at: 3.days.ago) }
  let_it_be(:debian_package) { create(:debian_package, project: resource, name: 'zab', version: '7.0.0', created_at: 2.days.ago) }
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

  describe 'sorting and pagination' do
    let_it_be(:ascending_packages) { [maven_package, package, composer_package, debian_package].map { |package| global_id_of(package)} }

    let(:data_path) { [:project, :packages] }

    before do
      resource.add_reporter(current_user)
    end

    [:CREATED_ASC, :NAME_ASC, :VERSION_ASC, :TYPE_ASC].each do |order|
      context "#{order}" do
        it_behaves_like 'sorted paginated query' do
          let(:sort_param) { order }
          let(:first_param) { 4 }
          let(:expected_results) { ascending_packages }
        end
      end
    end

    [:CREATED_DESC, :NAME_DESC, :VERSION_DESC, :TYPE_DESC].each do |order|
      context "#{order}" do
        it_behaves_like 'sorted paginated query' do
          let(:sort_param) { order }
          let(:first_param) { 4 }
          let(:expected_results) { ascending_packages.reverse }
        end
      end
    end

    def pagination_query(params)
      graphql_query_for(:project, { 'fullPath' => resource.full_path },
        query_nodes(:packages, :id, include_pagination_info: true, args: params)
      )
    end
  end
end
