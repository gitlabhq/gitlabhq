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

  describe 'protectionRuleExists' do
    let_it_be(:maven_package) { create(:maven_package, project: project1, name: 'maven-package') }
    let_it_be(:npm_package) { create(:npm_package, project: project1, name: 'npm-package') }
    let_it_be(:npm_package_no_match) { create(:npm_package, project: project1, name: 'other-npm-package') }

    let_it_be(:npm_package_protection_rule) do
      create(:package_protection_rule, project: resource, package_name_pattern: npm_package.name, package_type: :npm,
        minimum_access_level_for_push: :maintainer)
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
          protectionRuleExists
        }
      QUERY
    end

    describe "efficient database queries" do
      let_it_be(:project2) { create(:project, :repository) }
      let_it_be(:project2_npm_package) { create(:npm_package, project: project2, name: '@project2/npm-package') }
      let_it_be(:project2_npm_packages_no_match) do
        create_list(:npm_package, 4, project: project2) do |npm_package, i|
          npm_package.update!(name: "@project2/npm-package-no-match-#{i}")
        end
      end

      let_it_be(:project2_npm_package_protection_rule) do
        create(:package_protection_rule,
          project: project2,
          package_name_pattern: project2_npm_package.name,
          package_type: :npm,
          minimum_access_level_for_push: :maintainer
        )
      end

      let_it_be(:user1) { create(:user, developer_of: resource) }
      let_it_be(:user2) { create(:user, developer_of: project2) }

      it 'avoids N+1 database queries' do
        control_count = ActiveRecord::QueryRecorder.new { post_graphql(query, current_user: user1) }

        query2 = graphql_query_for(resource_type, { 'fullPath' => project2.full_path },
          query_graphql_field('packages', {}, fields))
        expect { post_graphql(query2, current_user: user2) }.not_to exceed_query_limit(control_count)
      end
    end

    context 'when package protection rule for package and user exists' do
      using RSpec::Parameterized::TableSyntax

      where(:current_user_access_level, :expected_protection_rule_exists) do
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
              'protectionRuleExists' => expected_protection_rule_exists
            ),
            hash_including(
              'name' => maven_package.name,
              'packageType' => maven_package.package_type.upcase,
              'protectionRuleExists' => false
            )
          )
        end
      end
    end
  end
end
