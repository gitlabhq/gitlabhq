# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'getting a package list for a project', feature_category: :package_registry do
  include GraphqlHelpers

  let_it_be(:resource) { create(:project, :repository) }
  let_it_be(:current_user) { create(:user) }
  let_it_be(:project1) { resource }
  let_it_be(:project2) { resource }

  let(:resource_type) { :project }

  it_behaves_like 'group and project packages query'

  describe 'packageProtectionRuleExists' do
    let_it_be(:maven_package) { create(:maven_package, project: project1, name: 'maven-package') }
    let_it_be(:npm_package) { create(:npm_package, project: project1, name: 'npm-package') }
    let_it_be(:npm_package_no_match) { create(:npm_package, project: project1, name: 'other-npm-package') }

    let_it_be(:npm_package_protection_rule) do
      create(:package_protection_rule, project: resource, package_name_pattern: npm_package.name, package_type: :npm,
        push_protected_up_to_access_level: :maintainer)
    end

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
          packageType
          packageProtectionRuleExists
        }
      QUERY
    end

    context 'when package protection rule for package and user exists' do
      using RSpec::Parameterized::TableSyntax

      where(:current_user_access_level, :expected_package_protection_rule_exists) do
        :reporter   | true
        :developer  | true
        :maintainer | true
        :owner      | true
      end

      with_them do
        before do
          resource.send("add_#{current_user_access_level}", current_user)

          post_graphql(query, current_user: current_user)
        end

        it_behaves_like 'a working graphql query that returns data'

        it 'returns package protection rules' do
          expect(graphql_data_at(resource_type, :packages, :nodes)).to include(
            hash_including(
              'name' => npm_package.name,
              'packageType' => npm_package.package_type.upcase,
              'packageProtectionRuleExists' =>
                expected_package_protection_rule_exists
            ),
            hash_including(
              'name' => maven_package.name,
              'packageType' => maven_package.package_type.upcase,
              'packageProtectionRuleExists' => false
            )
          )
        end
      end
    end

    context "when feature flag ':packages_protected_packages' disabled" do
      before_all do
        resource.add_maintainer(current_user)
      end

      before do
        stub_feature_flags(packages_protected_packages: false)

        post_graphql(query, current_user: current_user)
      end

      it 'returns no package protection rules' do
        graphql_data_at(resource_type, :packages, :nodes).each do |package|
          expect(package['packageProtectionRuleExists']).to eq false
        end
      end
    end
  end
end
