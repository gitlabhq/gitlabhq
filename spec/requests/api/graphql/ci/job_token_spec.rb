# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Fetching Groups and Projects for CI_JOB_TOKEN', feature_category: :continuous_integration do
  include GraphqlHelpers

  let_it_be_with_reload(:group) { create(:group) }

  let_it_be(:subgroup1) { create(:group, parent: group, name: 'vegetable') }
  let_it_be(:subgroup2) { create(:group, parent: group, name: 'fruit') }
  let_it_be(:subgroup3) { create(:group, parent: subgroup2, name: 'fruit') }
  let_it_be(:subgroup4) { create(:group, parent: subgroup3, name: 'fruit') }
  let_it_be(:subgroup5) { create(:group, parent: subgroup4, name: 'fruit') }

  let_it_be(:project1) { create(:project, group: subgroup1, name: 'cabbage', path: 'cabbage') }
  let_it_be(:project2) { create(:project, group: group, name: 'banana', path: 'banana') }
  let_it_be(:project3) { create(:project, group: subgroup2, name: 'banana', path: 'banana') }
  let_it_be(:project4) { create(:project, group: subgroup3, name: 'banana', path: 'banana') }
  let_it_be(:project5) { create(:project, group: subgroup4, name: 'banana', path: 'banana') }

  let_it_be(:user) { create(:user) }
  let(:fetched_projects_data) { graphql_data['projects'] }
  let(:fetched_groups_data) { graphql_data['groups'] }

  describe 'Get groups and projects query for CI_JOB_TOKEN' do
    before_all do
      group.add_maintainer(user)
    end

    context 'when searching project by name' do
      before do
        get_graphql(project_query('cabbage'), current_user: user)
      end

      it_behaves_like 'a working graphql query'

      it 'searches namespaces for exact match' do
        expect(fetched_projects_data['nodes'].length).to eq 1
        expect(fetched_projects_data['nodes'].first['id']).to eq "gid://gitlab/Project/#{project1.id}"
      end
    end

    context 'when searching project by path' do
      before do
        get_graphql(project_query("banana"), current_user: user)
      end

      it_behaves_like 'a working graphql query'

      it 'sorts by id (ascending order) when there are multiple matches' do
        expect(fetched_projects_data['nodes'].length).to eq 4
        expect(fetched_projects_data['nodes'].pluck('id')).to eq [
          "gid://gitlab/Project/#{project2.id}", # skip project 1 (group/vegetable/cabbage)
          "gid://gitlab/Project/#{project3.id}",
          "gid://gitlab/Project/#{project4.id}",
          "gid://gitlab/Project/#{project5.id}"
        ]
      end
    end

    context 'when searching group by name' do
      before do
        get_graphql(group_query('vegetable'), current_user: user)
      end

      it_behaves_like 'a working graphql query'

      it 'finds exact match' do
        expect(fetched_groups_data['nodes'].length).to eq 1
        expect(fetched_groups_data['nodes'].first['id']).to eq "gid://gitlab/Group/#{subgroup1.id}"
      end
    end

    context 'when searching group by path' do
      before do
        get_graphql(group_query('fruit/fruit'), current_user: user)
      end

      it_behaves_like 'a working graphql query'

      it 'sorts by id (ascending order) when there are multiple matches' do
        expect(fetched_groups_data['nodes'].length).to eq 3
        expect(fetched_groups_data['nodes'].pluck('id')).to eq [
          "gid://gitlab/Group/#{subgroup3.id}", # skip group 1 and 2 (group/vegetable and group/fruit)
          "gid://gitlab/Group/#{subgroup4.id}",
          "gid://gitlab/Group/#{subgroup5.id}"
        ]
      end
    end
  end

  private

  def project_query(search)
    <<~QUERY
    query {
      projects(search: "#{search}", sort: "id_asc", first: 10) {
        nodes {
          id
        }
      }
    }
    QUERY
  end

  def group_query(search)
    <<~QUERY
    query {
      groups(search: "#{search}",  sort: "id_asc", first: 10) {
        nodes {
          id
        }
      }
    }
    QUERY
  end
end
