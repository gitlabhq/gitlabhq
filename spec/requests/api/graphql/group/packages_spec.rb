# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'getting a package list for a group', feature_category: :package_registry do
  include GraphqlHelpers

  let_it_be(:resource) { create(:group, :private) }
  let_it_be(:group_two) { create(:group, :private) }
  let_it_be(:project1) { create(:project, :repository, group: resource) }
  let_it_be(:project2) { create(:project, :repository, group: resource) }
  let_it_be(:current_user) { create(:user) }

  let(:resource_type) { :group }

  it_behaves_like 'group and project packages query'

  context 'with a batched query' do
    let_it_be(:group_two_project) { create(:project, :repository, group: group_two) }
    let_it_be(:group_one_package) { create(:npm_package, project: project1) }
    let_it_be(:group_two_package) { create(:npm_package, project: group_two_project) }

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
      expect(a_packages_names).to contain_exactly(group_one_package.name)
      expect_graphql_errors_to_include [/"packages" field can be requested only for 1 Group\(s\) at a time./]
      expect(graphql_data_at(:b, :packages)).to be_nil
    end
  end

  describe 'protectionRuleExists' do
    let_it_be(:project1_package_protected) { create(:npm_package, project: project1) }
    let_it_be(:project1_package) { create(:npm_package, project: project1) }
    let_it_be(:package_protection_rule1) do
      create(:package_protection_rule, project: project1,
        package_name_pattern: project1_package_protected.name,
        package_type: project1_package_protected.package_type,
        minimum_access_level_for_push: :admin)
    end

    let_it_be(:project2_package_protected) { create(:npm_package, project: project2) }
    let_it_be(:project2_package) { create(:npm_package, project: project2) }
    let_it_be(:package_protection_rule2) do
      create(:package_protection_rule, project: project2,
        package_name_pattern: project2_package_protected.name,
        package_type: project2_package_protected.package_type,
        minimum_access_level_for_push: :admin)
    end

    let_it_be_with_reload(:project3) { create(:project, :private, group: resource) }
    let_it_be(:project3_package_protected) { create(:npm_package, project: project3) }
    let_it_be(:project3_package) { create(:npm_package, project: project3) }
    let_it_be(:package_protection_rule3) do
      create(:package_protection_rule, project: project3,
        package_name_pattern: project3_package_protected.name,
        package_type: project3_package_protected.package_type,
        minimum_access_level_for_push: :admin)
    end

    let(:packages) { graphql_data_at(resource_type, :packages, :nodes) }

    let(:query) do
      graphql_query_for(
        resource_type,
        { 'fullPath' => resource.full_path },
        query_graphql_field('packages', {}, fields)
      )
    end

    let(:fields) do
      <<~QUERY
        nodes {
          name
          protectionRuleExists
        }
      QUERY
    end

    subject(:send_graphql_request) { post_graphql(query, current_user: current_user) }

    before do
      resource.add_reporter(current_user)
    end

    it 'returns true for all protected packages' do
      send_graphql_request

      expect(packages).to match_array([
        a_hash_including('name' => project1_package_protected.name, 'protectionRuleExists' => true),
        a_hash_including('name' => project2_package_protected.name, 'protectionRuleExists' => true),
        a_hash_including('name' => project3_package_protected.name, 'protectionRuleExists' => true),
        a_hash_including('name' => project1_package.name, 'protectionRuleExists' => false),
        a_hash_including('name' => project2_package.name, 'protectionRuleExists' => false),
        a_hash_including('name' => project3_package.name, 'protectionRuleExists' => false)
      ])
    end

    it 'executes only one database queries for all projects at once' do
      expect { send_graphql_request }.to match_query_count(1).for_model(::Packages::Protection::Rule)
    end

    context 'when 25 packages belong to group' do
      let_it_be(:resource) { create(:group) }
      let_it_be(:projects) { create_list(:project, 5, :private, group: resource) }

      before_all do
        projects.each do |project|
          package = create_list(:npm_package, 5, project: project)
          create(:package_protection_rule, project: project, package_name_pattern: package.first.name,
            package_type: package.first.package_type)
        end
      end

      it 'executes only two database queries to check the protection rules for packages in batches of 20' do
        expect { send_graphql_request }.to match_query_count(2).for_model(::Packages::Protection::Rule)
      end
    end
  end
end
