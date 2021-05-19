# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'getting a package list for a group' do
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
      expect_graphql_errors_to_include [/Packages can be requested only for one group at a time/]
      expect(graphql_data_at(:b, :packages)).to be(nil)
    end
  end
end
